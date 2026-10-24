# ほかのプレイヤーをつかむやつ

`com.metlab.wld.playergrab`

> **試作版（BETA）です。** 動作する最小構成の段階です。

手に持った「グラブアイテム」をほかのプレイヤーに向けて、離れた場所から掴み、ふわふわ持ち上げて運べる UdonSharp ギミックです。
VRChat では他人のアバターを直接動かせないため、見えない椅子（VRCStation）に相手を座らせ、その椅子をアイテムの前へ動かしています。

## 操作

1. グラブアイテムを持つ
2. 人に向けてトリガー（Use）を引くと、狙った範囲（既定 15m・20°）でいちばん近い人を掴む
3. 右スティックの上下で、持つ距離を変える
4. もう一度トリガーを引くと、その場に降ろす。動かしながら離すと、その勢いで相手が飛ぶ

## 使い方

**グラブアイテム（手に持つもの）**

1. `VRC Pickup`（Use を有効に）、Rigidbody、Collider を付ける
2. `UdonBehaviour` を付け、Program Source に `MET_PlayerGrabSystem` を設定する
3. `VRC Object Sync` を付ける
4. 必要なら、アイテムの先端に空のオブジェクトを置き、「銃口」に設定する（青い矢印の向きが狙う方向）

**保持ターゲット（相手を座らせる見えない椅子・別のオブジェクト）**

1. `VRC Station` を付け、Seated をオフ、Player Mobility を Immobilize For Vehicle、Disable Station Exit をオンにする
2. `VRC Object Sync` を付ける
3. グラブアイテムの設定欄に、この保持ターゲットを登録する

## 必要なもの

- Unity 2022.3
- com.vrchat.worlds >=3.7.0

## ライセンス

MIT License（リポジトリ直下の LICENSE を参照）
