# Metlab WLD

MetraZero 制作の VRChat ワールド向けツールです。

## 収録ツール

| ツール | パッケージID | 内容 | バージョン |
| --- | --- | --- | --- |
| [アセットのショートカットをつくるやつ](Packages/com.metlab.shortcut) | `com.metlab.shortcut` | よく使うフォルダやアセットのショートカットを、実際のフォルダ構成とは別に整理できるタブ。フォルダの色分け付き。 | 1.1.0 |
| [オブジェクトをプレイヤーについてこさせるやつ](Packages/com.metlab.wld.followplayer) | `com.metlab.wld.followplayer` | オブジェクトをローカルプレイヤーの位置に追従させる UdonSharp スクリプト。軸ごとのON/OFFと範囲制限付き。 | 1.0.0 |
| [レイマーチングでスカイボックスをつくるやつ](Packages/com.metlab.wld.skybox) | `com.metlab.wld.skybox` | 時間帯・天気・街並みを選ぶだけで、街の夜景などのスカイボックス用マテリアルを作るエディタ拡張とシェーダー。 | 1.1.0 |
| [ジョインをおしらせするやつ](Packages/com.metlab.wld.joinnotice) | `com.metlab.wld.joinnotice` | 誰かがワールドに入ってきた・出ていったときに、目の前に通知を出す UdonSharp ギミック。人ごとに文言や音を変えられる。 | 1.0.0 |
| [オブジェクトをランダムにだすやつ](Packages/com.metlab.wld.randomizer) | `com.metlab.wld.randomizer` | 登録したオブジェクトを、設定した確率でまとめてON/OFFする UdonSharp スクリプト。抽選結果は全員で共有される。 | 1.0.0 |
| [近づくとひらくドアにするやつ](Packages/com.metlab.wld.autodoor) | `com.metlab.wld.autodoor` | プレイヤーが近づくとドアがスライドして開き、離れると閉じる UdonSharp スクリプト。Animator 不要で複数枚のドアに対応。 | 0.0.0 |
| [昼と夜をきりかえるやつ](Packages/com.metlab.wld.daynight) | `com.metlab.wld.daynight` | ワールド全体の昼／夜を全員で切り替え、場所ごとの空（スカイボックス）や昼だけ・夜だけのオブジェクトも切り替える UdonSharp ギミック。 | 0.0.0 |
| [落ちても元の場所にもどれるやつ](Packages/com.metlab.wld.returnpoint) | `com.metlab.wld.returnpoint` | エラーなどでワールドから落ちて同じインスタンスに入り直したとき、元いた場所へ自動で戻す UdonSharp スクリプト。 | 0.0.0 (BETA) |
| [持ったものの大きさをかえるやつ](Packages/com.metlab.wld.pickupscaler) | `com.metlab.wld.pickupscaler` | Pickup を片手で持ち、もう片方の手のグラブで両手を近づける・離すと縮小・拡大できる UdonSharp スクリプト（VR 向け）。 | 0.0.0 |
| [ほかのプレイヤーをつかむやつ](Packages/com.metlab.wld.playergrab) | `com.metlab.wld.playergrab` | 手に持ったアイテムで、離れた場所にいるほかのプレイヤーを掴んで、ふわふわ持ち上げて運べる UdonSharp ギミック。 | 0.0.0 (BETA) |

## 導入方法（VCC / ALCOM）

1. 次の URL を VCC（または ALCOM）の「Packages > Add Repository」に登録する

   `https://metrazero.github.io/vpm-repo/index.json`

   または [こちらのページ](https://metrazero.github.io/vpm-repo/) の「VCC に追加」ボタンから登録できます。

2. プロジェクトの「Manage Project」から、使いたいツールを追加する

アバター向け（Metlab AVA）とワールド向け（Metlab WLD）は同じ URL で配信しています。
ワールド向けのツールはワールド用 SDK が必要なので、アバター用プロジェクトには入りません（逆も同じ）。

## メニュー

ウィンドウを持つツールは、すべて `Tools > Metlab` の下にあります。

## ライセンス

[MIT License](LICENSE)
