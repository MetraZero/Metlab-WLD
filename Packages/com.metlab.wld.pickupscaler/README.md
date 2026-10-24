# 持ったものの大きさをかえるやつ

`com.metlab.wld.pickupscaler`

手に持ったオブジェクトを、両手で拡大・縮小できるようにする UdonSharp スクリプトです（VR 向け。デスクトップでは使えません）。

## 操作

1. オブジェクトを片手で持つ
2. もう片方の手のグラブボタンを押しっぱなしにする
3. 両手を近づけると縮小、離すと拡大
4. グラブボタンを離すと、その大きさで決まる

## 使い方

1. 対象のオブジェクトに `VRC Pickup`（Rigidbody と Collider が必要）を付ける
2. `UdonBehaviour` を付け、Program Source に `MET_PickupScaler` を設定する
3. 最小・最大の大きさ（最初の大きさに対する倍率）を設定する
4. 大きさを全員にそろえたい場合は「グローバル同期する」をオンにし、位置がずれないよう `VRC Object Sync` も付ける

大きさに合わせて Rigidbody の重さを変える設定もあります（既定はオフ）。

## 必要なもの

- Unity 2022.3
- com.vrchat.worlds >=3.7.0

## ライセンス

MIT License（リポジトリ直下の LICENSE を参照）
