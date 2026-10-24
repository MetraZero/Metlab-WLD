/*
 * MET_JoinNotification
 * VRChat ワールド入退室通知システム (メインコントローラー)
 *
 * 概要:
 *   プレイヤーがワールドに参加・退出した際、全員の画面に通知を表示する。
 *   MET_NotificationSet を配列で持ち、プレイヤー名に応じたセットを選んで表示。
 *   同一プレイヤーが複数セットに登録されている場合はランダムに選択。
 *   誰にも一致しない場合は isDefault = true のセットを使用。
 *
 * 動作の仕組み:
 *   OnPlayerJoined / OnPlayerLeft は全クライアントで発火するため
 *   ネットワーク同期なしで全員に通知が届く。
 *   ワールド参加直後の既存プレイヤーへの通知スパムを防ぐため
 *   initDelay 秒間は通知を抑制する。
 *
 * セットアップ:
 *   1. このスクリプトをルート GameObject にアタッチ
 *   2. 子に World Space Canvas を作成し CanvasGroup をアタッチ →
 *      Canvas Group フィールドにアサイン (HUD 追従・フェード制御用)
 *   3. Canvas 内に通知パネル用 GameObject を人数分作成し
 *      MET_NotificationSet をアタッチ → Sets 配列に登録
 *   4. AudioSource を用意して Audio Source にアサイン
 *   5. 必ず1つの MET_NotificationSet に isDefault = true を設定すること
 *
 * ZTest Always (壁埋まり対策):
 *   Udon は Material を実行時に複製できないため、エディタで設定する。
 *   各セットの Text (TMP) と背景 Image に ZTest Always のマテリアルを
 *   割り当てること。背景 Image には同梱の MET_UI_ZTestAlways シェーダーを使用。
 *   TMP はフォントマテリアルを複製し Extra Settings → ZTest → Always に変更。
 *
 * バージョン履歴:
 *   1.0.0 - 初版。Join/Leave 通知・サウンド・フェード・キュー・特別名前サポート。
 *   1.0.1 - デバッグ用テストメソッド追加。
 *   1.0.2 - initDelay=0 即時有効化修正。Debug.Log 追加。
 *   1.1.0 - HUD モード追加。GetTrackingData(Head) でカメラ追従。
 *   1.1.1 - ZTest Always 対策方針整理。Udon 制約の注記追加。
 *   2.0.0 - マルチセット対応。MET_NotificationSet を導入し、
 *           セットごとに背景・テキスト・サウンド・メッセージを個別設定可能に。
 *           同一プレイヤーが複数セット登録時はランダム選択。デフォルトセット対応。
 */

using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace Metlab.JoinNotice
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class MET_JoinNotification : UdonSharpBehaviour
    {
        // =========================================================
        // Inspector Fields
        // =========================================================

        [Header("─── 通知セット ──────────────────────────────────")]

        [Tooltip("通知セットの配列。MET_NotificationSet をアタッチした\n"
               + "各パネル GameObject をここに登録する。\n"
               + "必ず1つに isDefault = true を設定すること。")]
        public MET_NotificationSet[] sets = new MET_NotificationSet[0];


        [Header("─── Canvas ───────────────────────────────────────")]

        [Tooltip("Canvas の CanvasGroup\n"
               + "HUD 追従と全体フェードイン/アウトを制御する")]
        public CanvasGroup canvasGroup;


        [Header("─── Audio ────────────────────────────────────────")]

        [Tooltip("サウンド再生用 AudioSource\n"
               + "2D 音声推奨 (Spatial Blend = 0)\n"
               + "各セットの joinSound / leaveSound をここで再生する")]
        public AudioSource audioSource;


        [Header("─── Display ──────────────────────────────────────")]

        [Tooltip("通知の表示秒数")]
        [Range(1f, 15f)]
        public float displayDuration = 4f;

        [Tooltip("フェードアウト速度 (値が大きいほど速い)")]
        [Range(1f, 20f)]
        public float fadeSpeed = 5f;


        [Header("─── Behavior ─────────────────────────────────────")]

        [Tooltip("自分自身の Join も通知に表示するか")]
        public bool notifyLocalPlayerJoin = false;

        [Tooltip("初期化完了までの待機秒数\n"
               + "ワールド参加時に既存プレイヤーへの通知スパムを防ぐ\n"
               + "0 = 即時有効 (ClientSim テスト時は 0 推奨)")]
        [Range(0f, 15f)]
        public float initDelay = 5f;


        [Header("─── HUD (カメラ追従) ──────────────────────────")]

        [Tooltip("true: Canvas をカメラに追従させ常に視界に表示\n"
               + "false: World Space の固定位置に表示")]
        public bool enableHud = true;

        [Tooltip("カメラ前方への距離 (m)")]
        [Range(0.5f, 10f)]
        public float hudDistance = 3f;

        [Tooltip("視界中心からの垂直オフセット (m)\n正 = 上、負 = 下")]
        [Range(-3f, 3f)]
        public float hudVerticalOffset = -0.6f;

        [Tooltip("視界中心からの水平オフセット (m)\n正 = 右、負 = 左")]
        [Range(-3f, 3f)]
        public float hudHorizontalOffset = 0f;


        [Header("─── Debug (ClientSim テスト用) ──────────────────")]

        [Tooltip("_DebugTestJoin / _DebugTestLeave で使うテスト名")]
        public string debugTestName = "TestPlayer";


        // =========================================================
        // Private Fields
        // =========================================================

        private bool  _isReady   = false;
        private bool  _isShowing = false;
        private float _targetAlpha = 0f;

        // 通知キュー (循環バッファ)
        private const int QUEUE_SIZE = 20;
        private string[] _msgQueue;
        private bool[]   _joinFlagQueue;
        private int[]    _setIndexQueue;   // 使用するセットのインデックス
        private int      _qHead = 0;
        private int      _qTail = 0;


        // =========================================================
        // Unity Lifecycle
        // =========================================================

        private void Start()
        {
            _msgQueue      = new string[QUEUE_SIZE];
            _joinFlagQueue = new bool[QUEUE_SIZE];
            _setIndexQueue = new int[QUEUE_SIZE];

            // Canvas を非表示にして全セットパネルも非表示化
            if (canvasGroup != null) canvasGroup.alpha = 0f;
            _targetAlpha = 0f;
            _HideAllPanels();

            if (initDelay <= 0f)
            {
                _isReady = true;
                Debug.Log("[MET_JoinNotification] Start: 即時有効化 (initDelay=0)");
            }
            else
            {
                Debug.Log($"[MET_JoinNotification] Start: {initDelay}秒後に有効化");
                SendCustomEventDelayedSeconds(nameof(_OnReady), initDelay);
            }
        }

        private void Update()
        {
            // ① Canvas フェードアニメーション
            if (canvasGroup != null)
                canvasGroup.alpha = Mathf.MoveTowards(
                    canvasGroup.alpha,
                    _targetAlpha,
                    fadeSpeed * Time.deltaTime
                );

            // ② HUD: Canvas をローカルプレイヤーのヘッドに追従させる
            if (enableHud && canvasGroup != null)
                _UpdateHudPosition();
        }

        // Canvas をローカルプレイヤーのヘッドトラッキング位置に追従させる。
        // VRChat では Screen Space Overlay が使用不可のため World Space Canvas で代替。
        // Desktop / VR どちらでも TrackingDataType.Head が正しい位置・向きを返す。
        private void _UpdateHudPosition()
        {
            VRCPlayerApi localPlayer = Networking.LocalPlayer;
            if (!Utilities.IsValid(localPlayer)) return;

            VRCPlayerApi.TrackingData head =
                localPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head);

            Vector3 forward = head.rotation * Vector3.forward;
            Vector3 up      = head.rotation * Vector3.up;
            Vector3 right   = head.rotation * Vector3.right;

            Vector3 targetPos = head.position
                + forward * hudDistance
                + up      * hudVerticalOffset
                + right   * hudHorizontalOffset;

            // Canvas の -Z 側からプレイヤーが見る形にする (+Z を forward 方向へ)
            Quaternion targetRot = Quaternion.LookRotation(forward, up);

            canvasGroup.transform.SetPositionAndRotation(targetPos, targetRot);
        }


        // =========================================================
        // VRChat Player Events
        // =========================================================

        public override void OnPlayerJoined(VRCPlayerApi player)
        {
            Debug.Log($"[MET_JoinNotification] OnPlayerJoined: {player.displayName} | isReady={_isReady} | isLocal={player.isLocal}");
            if (!_isReady) return;
            if (player.isLocal && !notifyLocalPlayerJoin) return;

            string name     = player.displayName;
            int    setIndex = _FindSet(name);
            if (setIndex < 0) return;

            string message = sets[setIndex].BuildJoinMessage(name);
            _Enqueue(message, true, setIndex);
        }

        public override void OnPlayerLeft(VRCPlayerApi player)
        {
            if (!Utilities.IsValid(player)) return;
            Debug.Log($"[MET_JoinNotification] OnPlayerLeft: {player.displayName} | isReady={_isReady}");
            if (!_isReady) return;

            string name     = player.displayName;
            int    setIndex = _FindSet(name);
            if (setIndex < 0) return;

            string message = sets[setIndex].BuildLeaveMessage(name);
            _Enqueue(message, false, setIndex);
        }


        // =========================================================
        // Internal – Set Selection
        // =========================================================

        // プレイヤー名に一致するセットを返す。
        // 複数のセットに登録されている場合はランダムに1つを選ぶ。
        // どのセットにも登録されていない場合は isDefault=true のセットを返す。
        // セットが見つからない場合は -1 を返す。
        private int _FindSet(string playerName)
        {
            // 一致するセットを収集 (デフォルト以外)
            int[] matches  = new int[sets.Length];
            int   count    = 0;

            for (int i = 0; i < sets.Length; i++)
            {
                if (sets[i] == null) continue;
                if (!sets[i].isDefault && sets[i].ContainsPlayer(playerName))
                    matches[count++] = i;
            }

            // 1つ以上一致 → ランダム選択
            if (count > 0)
                return matches[Random.Range(0, count)];

            // 一致なし → デフォルトセットを使用
            for (int i = 0; i < sets.Length; i++)
                if (sets[i] != null && sets[i].isDefault) return i;

            return -1; // セットが未設定
        }


        // =========================================================
        // Internal – Queue & Display
        // =========================================================

        private void _Enqueue(string message, bool isJoin, int setIndex)
        {
            int nextTail = (_qTail + 1) % QUEUE_SIZE;
            if (nextTail == _qHead) return; // キュー満杯時は破棄

            _msgQueue[_qTail]      = message;
            _joinFlagQueue[_qTail] = isJoin;
            _setIndexQueue[_qTail] = setIndex;
            _qTail = nextTail;

            if (!_isShowing) _ShowNext();
        }

        private void _ShowNext()
        {
            if (_qHead == _qTail) // キューが空
            {
                _isShowing = false;
                return;
            }

            _isShowing = true;

            string message  = _msgQueue[_qHead];
            bool   isJoin   = _joinFlagQueue[_qHead];
            int    setIndex = _setIndexQueue[_qHead];
            _qHead = (_qHead + 1) % QUEUE_SIZE;

            MET_NotificationSet activeSet = sets[setIndex];

            // 全パネルを非表示にしてから対象セットだけ表示
            _HideAllPanels();
            activeSet.ShowNotification(message);

            // Canvas フェードイン
            _targetAlpha = 1f;

            // サウンド再生 (メインの AudioSource でセットのクリップを鳴らす)
            if (audioSource != null)
            {
                AudioClip clip = isJoin ? activeSet.joinSound : activeSet.leaveSound;
                if (clip != null) audioSource.PlayOneShot(clip);
            }

            Debug.Log($"[MET_JoinNotification] 通知: \"{message}\" (セット: {setIndex})");

            SendCustomEventDelayedSeconds(nameof(_OnDisplayEnd), displayDuration);
        }

        // 全セットのパネルを非表示にする
        private void _HideAllPanels()
        {
            for (int i = 0; i < sets.Length; i++)
                if (sets[i] != null) sets[i].HidePanel();
        }


        // =========================================================
        // Delayed Event Callbacks (public 必須)
        // =========================================================

        public void _OnReady()
        {
            _isReady = true;
            Debug.Log("[MET_JoinNotification] _OnReady: 通知有効化");
        }

        public void _OnDisplayEnd()
        {
            _targetAlpha = 0f;
            float waitTime = (1f / Mathf.Max(fadeSpeed, 0.1f)) + 0.15f;
            SendCustomEventDelayedSeconds(nameof(_OnFadeOutEnd), waitTime);
        }

        public void _OnFadeOutEnd()
        {
            _ShowNext();
        }


        // =========================================================
        // Debug – ClientSim テスト用
        // =========================================================

        public void _DebugTestJoin()
        {
            int setIndex = _FindSet(debugTestName);
            if (setIndex < 0) { Debug.LogWarning("[MET_JoinNotification] セットが見つかりません"); return; }
            string message = sets[setIndex].BuildJoinMessage(debugTestName);
            _Enqueue(message, true, setIndex);
        }

        public void _DebugTestLeave()
        {
            int setIndex = _FindSet(debugTestName);
            if (setIndex < 0) { Debug.LogWarning("[MET_JoinNotification] セットが見つかりません"); return; }
            string message = sets[setIndex].BuildLeaveMessage(debugTestName);
            _Enqueue(message, false, setIndex);
        }
    }
}
