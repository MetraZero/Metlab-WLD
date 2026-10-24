/*
 * MET_NotificationSet
 * MET_JoinNotification の通知セット定義スクリプト
 *
 * 概要:
 *   1 つの「通知スタイル」をまとめた設定単位。
 *   デフォルト用・特定人物用・グループ用など、セットごとに
 *   背景・テキスト・サウンド・メッセージを個別に設定できる。
 *
 * セットアップ:
 *   1. 通知パネル GameObject (例: デフォルト / あいうえおさん個人用) に
 *      このスクリプトをアタッチする。
 *   2. その GameObject に CanvasGroup を追加し Panel Group にアサイン。
 *   3. 子の TextMeshProUGUI を Notification Text にアサイン。
 *   4. isDefault = true にするか、playerNames にプレイヤー名を登録する。
 *
 * バージョン履歴:
 *   1.0.0 - 初版。MET_JoinNotification v2.0.0 対応。
 *           playerNames / joinFormat / leaveFormat / サウンド / UI 参照を保持。
 */

using UdonSharp;
using UnityEngine;
using VRC.Udon;
using TMPro;

namespace Metlab.JoinNotice
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class MET_NotificationSet : UdonSharpBehaviour
    {
        // =========================================================
        // Inspector Fields
        // =========================================================

        [Header("─── 対象プレイヤー ──────────────────────────────")]

        [Tooltip("このセットに属するプレイヤー名リスト\n"
               + "同じプレイヤーが複数セットに登録されている場合は\n"
               + "実行時にランダムで1つが選ばれる")]
        public string[] playerNames = new string[0];

        [Tooltip("true: 誰にも一致しない場合のフォールバックとして使用\n"
               + "false: playerNames に登録されたプレイヤーにのみ使用")]
        public bool isDefault = false;


        [Header("─── メッセージ ──────────────────────────────────")]

        [Tooltip("Join 通知テキスト。{0} がプレイヤー名に置換される")]
        public string joinFormat = "{0} が訪れました";

        [Tooltip("Leave 通知テキスト。{0} がプレイヤー名に置換される")]
        public string leaveFormat = "{0} が出かけていきました";


        [Header("─── サウンド ────────────────────────────────────")]

        [Tooltip("Join 時のサウンド (未設定なら無音)")]
        public AudioClip joinSound;

        [Tooltip("Leave 時のサウンド (未設定なら無音)")]
        public AudioClip leaveSound;


        [Header("─── UI ─────────────────────────────────────────")]

        [Tooltip("このセットの通知テキスト (TextMeshProUGUI)\n"
               + "ZTest Always マテリアルを Font Material に割り当てること")]
        public TextMeshProUGUI notificationText;

        [Tooltip("このセットのパネル全体の CanvasGroup\n"
               + "表示中 alpha=1、非表示中 alpha=0 に自動制御される")]
        public CanvasGroup panelGroup;


        // =========================================================
        // Public Methods (MET_JoinNotification から呼ばれる)
        // =========================================================

        // 指定名がこのセットの playerNames に含まれるかを返す
        public bool ContainsPlayer(string playerName)
        {
            for (int i = 0; i < playerNames.Length; i++)
                if (playerNames[i] == playerName) return true;
            return false;
        }

        // テキストを更新してパネルを表示する
        public void ShowNotification(string message)
        {
            if (notificationText != null)
                notificationText.text = message;
            if (panelGroup != null)
                panelGroup.alpha = 1f;
        }

        // パネルを非表示にする
        public void HidePanel()
        {
            if (panelGroup != null)
                panelGroup.alpha = 0f;
        }

        // Join 通知メッセージを生成して返す
        public string BuildJoinMessage(string playerName)
        {
            return string.Format(joinFormat, playerName);
        }

        // Leave 通知メッセージを生成して返す
        public string BuildLeaveMessage(string playerName)
        {
            return string.Format(leaveFormat, playerName);
        }
    }
}
