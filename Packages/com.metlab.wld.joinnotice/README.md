# ジョインをおしらせするやつ

`com.metlab.wld.joinnotice`

誰かがワールドに入ってきたとき・出ていったときに、自分の目の前に通知を出す UdonSharp ギミックです。
プレイヤー名ごとに「通知セット」を分けて、文言・音・見た目を変えられます（例：フレンドだけ特別な通知）。
通知はカメラに追従する HUD として表示され、壁の向こうにいても隠れません。

## 中身

| ファイル | 役割 |
| --- | --- |
| `MET_JoinNotification` | 本体。入退室を受け取り、通知を順番に表示する |
| `MET_NotificationSet` | 通知セット。対象のプレイヤー名・文言・音・表示パネル |
| `MET_UI_ZTestAlways`（シェーダー）＋マテリアル | 通知パネルを壁より手前に描くためのもの |

## 使い方

1. World Space の Canvas を作り、`CanvasGroup` と `AudioSource` を付ける
2. Canvas に `UdonBehaviour` を付け、Program Source に `MET_JoinNotification` を設定する
3. Canvas の中に通知パネル（背景の Image と TextMeshPro の文字）を作り、`UdonBehaviour`（Program Source は `MET_NotificationSet`）を付ける
   - 背景の Image に付属のマテリアルを設定すると、壁に埋まらずに表示される
   - 対象のプレイヤー名、入室／退室の文言（`{0}` がプレイヤー名になる）、音を設定する
   - 誰にも当てはまらない人用のセットには「isDefault」をオンにする
4. `MET_JoinNotification` の `sets` に、作った通知セットを登録する

表示秒数、フェードの速さ、自分の入室も通知するか、HUD の距離などはインスペクタで変えられます。

## 必要なもの

- Unity 2022.3
- com.vrchat.worlds >=3.7.0

## ライセンス

MIT License（リポジトリ直下の LICENSE を参照）
