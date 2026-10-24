# Metlab WLD

MetraZero 制作の VRChat ワールド向けツールです。

## 収録ツール

| ツール | パッケージID | 内容 | バージョン |
| --- | --- | --- | --- |
| [ショートカットをつくるやつ](Packages/com.metlab.shortcut) | `com.metlab.shortcut` | よく使うフォルダやアセットのショートカットを、実際のフォルダ構成とは別に整理できるタブ。フォルダの色分け付き。 | 1.0.0 |
| [オブジェクトをプレイヤーについてこさせるやつ](Packages/com.metlab.wld.followplayer) | `com.metlab.wld.followplayer` | オブジェクトをローカルプレイヤーの位置に追従させる UdonSharp スクリプト。軸ごとのON/OFFと範囲制限付き。 | 1.0.0 |
| [スカイボックスをつくるやつ](Packages/com.metlab.wld.skybox) | `com.metlab.wld.skybox` | 時間帯・天気・街並みを選ぶだけで、街の夜景などのスカイボックス用マテリアルを作るエディタ拡張とシェーダー。 | 1.0.0 |

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
