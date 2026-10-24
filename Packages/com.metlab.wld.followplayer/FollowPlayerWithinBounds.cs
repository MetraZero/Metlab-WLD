// v1.0.0
// オブジェクトをローカルプレイヤーの位置へ追従させる UdonSharp スクリプト（軸ごとのON/OFF・ワールド座標の範囲制限付き）。

using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace Metlab.FollowPlayer
{
    public class FollowPlayerWithinBounds : UdonSharpBehaviour
    {
        [Header("追従を許可する軸")]
        public bool followX = true;
        public bool followY = true;
        public bool followZ = true;

        [Header("ワールド座標での範囲制限")]
        public float minX = -10f;
        public float maxX = 10f;
        public float minY = 0f;
        public float maxY = 10f;
        public float minZ = -10f;
        public float maxZ = 10f;

        [Header("更新間隔（秒）")]
        public float updateInterval = 0.1f;

        private float timeSinceLastUpdate = 0f;

        private void LateUpdate()
        {
            // ローカルプレイヤーが存在しない場合は処理しない
            if (Networking.LocalPlayer == null) return;

            // 指定間隔でのみ更新
            timeSinceLastUpdate += Time.deltaTime;
            if (timeSinceLastUpdate < updateInterval) return;
            timeSinceLastUpdate = 0f;

            Vector3 playerPos = Networking.LocalPlayer.GetPosition();
            Vector3 newPos = transform.position;

            // X軸
            if (followX)
            {
                newPos.x = Mathf.Clamp(playerPos.x, minX, maxX);
            }

            // Y軸
            if (followY)
            {
                newPos.y = Mathf.Clamp(playerPos.y, minY, maxY);
            }

            // Z軸
            if (followZ)
            {
                newPos.z = Mathf.Clamp(playerPos.z, minZ, maxZ);
            }

            transform.position = newPos;
        }
    }
}
