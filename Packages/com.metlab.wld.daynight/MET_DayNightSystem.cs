// ============================================================
// MET_DayNightSystem
// 概要: ワールド全体の昼／夜モードを管理する（UdonSharp）。
//       - 昼／夜は全員でそろえる（Manual 同期。途中から入った人にも反映）。
//       - 空（スカイボックス）は「今いる場所」ごとに切り替える。
//         場所は MET_SkyboxArea の範囲の箱で決め、どの箱にもいなければ
//         「どのエリアにもいない時」の空になる（部屋 A など）。
//       - 昼だけ／夜だけ表示するオブジェクトを、全体とエリアごとに登録できる。
//       昼夜の切り替えは、ジェスチャーコマンドのアクション6（MET_GestureCommand）や、
//       他のギミックから _RequestNight / _RequestToggle を呼んで行う。
// バージョン: 1.0.1
//   a: 大きな変更（破壊的変更・仕様変更）
//   b: 機能追加・変更
//   c: 些細な修正・調整
//   1.0.1 - 昼夜を切り替える時、自分のプレイヤーが有効か確かめてから所有権を取るように（ワールドを出る途中の保険）
//   ※上の桁が上がった場合、下の桁は0にリセット
//
// 軽量化:
//   今いる場所は 0.5 秒ごとに調べ、変わった時だけ空を差し替える（Update は使わない）。
//
// 他のギミックとの連携:
//   「切り替わりを知らせる相手」に登録した UdonBehaviour へ、昼夜が変わるたびに
//   OnDayNightChanged イベントを送る（相手側で GetIsNight() を見て処理する）。
// ============================================================

using UdonSharp;
using UnityEngine;
using VRC.SDKBase;

namespace Metlab.DayNight
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class MET_DayNightSystem : UdonSharpBehaviour
    {
        private const float POLL_INTERVAL = 0.5f;
        private const int NO_AREA = -1;
        private const int NOT_CHECKED = -2;
        private const string CHANGED_EVENT = "OnDayNightChanged";

        [Header("昼夜")]
        [SerializeField, Tooltip("ワールドに最初に入った人が来た時点で夜にする（オフなら昼から始まる）")]
        private bool startAtNight = false;

        [Header("どのエリアにもいない時（部屋 A など）")]
        [SerializeField, Tooltip("昼の空")]
        private Material defaultDaySkybox;

        [SerializeField, Tooltip("夜の空")]
        private Material defaultNightSkybox;

        [SerializeField, Tooltip("昼だけ表示するオブジェクト（場所に関係なく切り替わる。照明など）")]
        private GameObject[] dayObjects;

        [SerializeField, Tooltip("夜だけ表示するオブジェクト（場所に関係なく切り替わる）")]
        private GameObject[] nightObjects;

        [Header("エリア")]
        [SerializeField, Tooltip("場所ごとの空（MET_SkyboxArea）。範囲が重なる時は上にあるものが優先")]
        private MET_SkyboxArea[] areas;

        [Header("他のギミックとの連携")]
        [SerializeField, Tooltip("昼夜が変わるたびに OnDayNightChanged イベントを送る相手")]
        private UdonSharpBehaviour[] listeners;

        [Header("デバッグ")]
        [SerializeField, Tooltip("昼夜・エリアの切り替わりをログに出す")]
        private bool debugLog = false;

        [UdonSynced] private bool syncedNight;

        private VRCPlayerApi localPlayer;
        private bool isNight;
        private int currentArea = NOT_CHECKED;
        private bool isReady;
        private bool receivedSync;

        // ------------------------------------------------------------
        // 初期化
        // ------------------------------------------------------------

        private void Start()
        {
            localPlayer = Networking.LocalPlayer;
            if (areas == null) areas = new MET_SkyboxArea[0];

            // Start より先に同期を受け取っていたら、そちらを使う
            if (!receivedSync) isNight = startAtNight;
            if (Networking.IsOwner(gameObject) && !receivedSync)
            {
                // 最初の人（オーナー）が初期状態を配る。後から入った人は OnDeserialization で受け取る
                syncedNight = startAtNight;
                RequestSerialization();
            }

            isReady = true;
            ApplyMode();
            SendCustomEventDelayedSeconds(nameof(_PollArea), POLL_INTERVAL);
        }

        // ------------------------------------------------------------
        // 公開メソッド
        // ------------------------------------------------------------

        /// <summary>今が夜かどうか</summary>
        public bool GetIsNight()
        {
            return isNight;
        }

        /// <summary>全員の昼夜を切り替える（true = 夜）</summary>
        public void _RequestNight(bool night)
        {
            VRCPlayerApi local = Networking.LocalPlayer;
            if (!Utilities.IsValid(local)) return;
            if (!Networking.IsOwner(gameObject)) Networking.SetOwner(local, gameObject);
            syncedNight = night;
            RequestSerialization();
            SetNight(night);
        }

        /// <summary>全員の昼夜を反転する</summary>
        public void _RequestToggle()
        {
            _RequestNight(!isNight);
        }

        /// <summary>全員を昼にする（他のギミックの SendCustomEvent 用）</summary>
        public void _RequestDay()
        {
            _RequestNight(false);
        }

        /// <summary>全員を夜にする（他のギミックの SendCustomEvent 用）</summary>
        public void _RequestNightMode()
        {
            _RequestNight(true);
        }

        public override void OnDeserialization()
        {
            receivedSync = true;
            SetNight(syncedNight);
        }

        // ------------------------------------------------------------
        // 昼夜の反映
        // ------------------------------------------------------------

        private void SetNight(bool night)
        {
            if (isReady && night == isNight) return;
            isNight = night;
            if (!isReady) return;

            ApplyMode();
            if (debugLog) Debug.Log($"[MET_DayNightSystem] {(isNight ? "夜" : "昼")}になりました", this);

            if (listeners != null)
            {
                for (int i = 0; i < listeners.Length; i++)
                {
                    if (listeners[i] != null) listeners[i].SendCustomEvent(CHANGED_EVENT);
                }
            }
        }

        private void ApplyMode()
        {
            SetActiveAll(dayObjects, !isNight);
            SetActiveAll(nightObjects, isNight);

            for (int i = 0; i < areas.Length; i++)
            {
                if (areas[i] != null) areas[i]._ApplyMode(isNight);
            }

            currentArea = FindArea();
            ApplySkybox();
        }

        // ------------------------------------------------------------
        // 今いる場所の空
        // ------------------------------------------------------------

        public void _PollArea()
        {
            SendCustomEventDelayedSeconds(nameof(_PollArea), POLL_INTERVAL);
            if (!isReady) return;

            int area = FindArea();
            if (area == currentArea) return;

            currentArea = area;
            ApplySkybox();
            if (debugLog)
            {
                string label = area == NO_AREA ? "どのエリアにもいない" : areas[area].name;
                Debug.Log($"[MET_DayNightSystem] 場所が変わりました: {label}", this);
            }
        }

        private int FindArea()
        {
            if (!Utilities.IsValid(localPlayer)) return NO_AREA;
            Vector3 pos = localPlayer.GetPosition();
            for (int i = 0; i < areas.Length; i++)
            {
                if (areas[i] != null && areas[i]._Contains(pos)) return i;
            }
            return NO_AREA;
        }

        private void ApplySkybox()
        {
            Material sky = currentArea == NO_AREA || currentArea < 0
                ? (isNight ? defaultNightSkybox : defaultDaySkybox)
                : areas[currentArea]._GetSkybox(isNight);

            if (sky != null && RenderSettings.skybox != sky) RenderSettings.skybox = sky;
        }

        private void SetActiveAll(GameObject[] objects, bool active)
        {
            if (objects == null) return;
            for (int i = 0; i < objects.Length; i++)
            {
                if (objects[i] != null) objects[i].SetActive(active);
            }
        }
    }
}
