# オブジェクトをプレイヤーについてこさせるやつ

`com.metlab.wld.followplayer`

オブジェクトを、そのワールドにいる自分（ローカルプレイヤー）の位置へついてこさせる UdonSharp スクリプトです。
追従させる軸（X・Y・Z）を個別にON/OFFでき、ワールド座標で動ける範囲を制限できます。
位置の更新は各プレイヤーの手元だけで行われ、同期はしません。

## 使い方

1. ついてこさせたいオブジェクトに `UdonBehaviour` を追加する
2. Program Source に `FollowPlayerWithinBounds`（このパッケージ内の .asset）を設定する
3. インスペクタで、追従させる軸・範囲（最小／最大）・更新間隔（秒）を設定する

## 設定項目

| 項目 | 内容 |
| --- | --- |
| followX / followY / followZ | その軸をプレイヤーに合わせるか |
| minX〜maxZ | ワールド座標での移動範囲 |
| updateInterval | 位置を更新する間隔（秒） |

## 必要なもの

- Unity 2022.3
- com.vrchat.worlds >=3.7.0

## ライセンス

MIT License（リポジトリ直下の LICENSE を参照）
