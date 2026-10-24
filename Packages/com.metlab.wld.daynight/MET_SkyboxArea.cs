// ============================================================
// MET_SkyboxArea
// 概要: 昼夜システム（MET_DayNightSystem）の「場所」1つ分（UdonSharp・同期なし）。
//       - 範囲の箱（BoxCollider）の中にいる間、このエリアの昼／夜の空になる。
//       - このエリアだけの「昼だけ／夜だけ表示するオブジェクト」を登録できる。
//       - 額縁（ミニチュアポータル）越しにこのエリアを見た時の空も昼夜で切り替える
//         （「額縁用の空の球」。MirrorReflection レイヤーに置いた大きな球で、
//           プレイヤー本人の画面には映らず、額縁のカメラにだけ映る）。
// バージョン: 1.0.0
//   a: 大きな変更（破壊的変更・仕様変更）
//   b: 機能追加・変更
//   c: 些細な修正・調整
//   ※上の桁が上がった場合、下の桁は0にリセット
//
// 範囲の箱:
//   BoxCollider の位置・大きさ・回転だけを使う。コライダーとしては無効のままでよい
//   （当たり判定やトリガーにはしない）。
// ============================================================

using UdonSharp;
using UnityEngine;

namespace Metlab.DayNight
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class MET_SkyboxArea : UdonSharpBehaviour
    {
        [Header("範囲")]
        [SerializeField, Tooltip("この箱の中にいる間、このエリアの空になる（BoxCollider。無効のままでよい）")]
        private BoxCollider bounds;

        [Header("空")]
        [SerializeField, Tooltip("昼の空")]
        private Material daySkybox;

        [SerializeField, Tooltip("夜の空")]
        private Material nightSkybox;

        [SerializeField, Tooltip("額縁用の空の球（MirrorReflection レイヤー）。昼夜で上の空に差し替える。額縁でこのエリアをのぞかないなら空でよい")]
        private Renderer[] viewSkyRenderers;

        [Header("このエリアのオブジェクト")]
        [SerializeField, Tooltip("昼だけ表示するオブジェクト")]
        private GameObject[] dayObjects;

        [SerializeField, Tooltip("夜だけ表示するオブジェクト")]
        private GameObject[] nightObjects;

        /// <summary>位置がこのエリアの範囲の中か</summary>
        public bool _Contains(Vector3 worldPos)
        {
            if (bounds == null) return false;
            Vector3 local = bounds.transform.InverseTransformPoint(worldPos) - bounds.center;
            Vector3 half = bounds.size * 0.5f;
            return Mathf.Abs(local.x) <= half.x && Mathf.Abs(local.y) <= half.y && Mathf.Abs(local.z) <= half.z;
        }

        /// <summary>昼／夜の空</summary>
        public Material _GetSkybox(bool night)
        {
            return night ? nightSkybox : daySkybox;
        }

        /// <summary>昼夜に合わせて、額縁用の空とオブジェクトを切り替える</summary>
        public void _ApplyMode(bool night)
        {
            Material sky = _GetSkybox(night);
            if (viewSkyRenderers != null)
            {
                for (int i = 0; i < viewSkyRenderers.Length; i++)
                {
                    Renderer r = viewSkyRenderers[i];
                    if (r == null) continue;
                    r.enabled = sky != null;
                    if (sky != null) r.sharedMaterial = sky;
                }
            }
            SetActiveAll(dayObjects, !night);
            SetActiveAll(nightObjects, night);
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
