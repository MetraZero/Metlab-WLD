// ============================================================
// MET_CitySkybox
// 概要: 街のスカイボックス（テクスチャ不要・すべて計算で描く）。
//       夜・夕暮れ・昼・明け方など、数値しだいでどの時間帯にもできる。
//       数値は「Tools > Metlab > スカイボックスをつくるやつ」でまとめて作れる。
//
//       街並み（近く）:
//         地面を小さな区画（セル）の格子に分け、視線が通るセルを順にたどる
//         レイマーチング（格子トラバーサル）で描く。
//         - 道路: 大きな街区ごとに、横の大通り（つながった直線）・ずらして並ぶ縦の道・
//           街区の中の道（T字路）を乱数で作る。行き止まりにならずにつながる。
//           街灯（点と路面の明かり）付き。
//         - 街区の中: マンション（板状の棟・1〜2棟）・高層ビル・戸建て（＋庭木）・
//           公園（木）・低い建物を割合で配置する。
//       街並み（遠く）:
//         「細かく描く距離」より先は、大きな街区単位の大まかなビルだけを描き、
//         かすみに溶かす（遠くまでスカイラインが続く）。
//       空: グラデーション＋地平線の照り返し、星（またたき）、
//           月・太陽（大きさ・方角・満ち欠け・模様・光の輪）、流れる雲（量・速さ・色）。
//
//       軽量化:
//         - ビルの最も高い所より上を通る視線は、街並みの計算をすぐ抜ける。
//         - 近くは最大「計算の歩数（近く）」セル、遠くは最大「計算の歩数（遠く）」街区まで。
//         - 遠くの窓・街灯は1つずつ描かず、平均の明るさにまとめる（ちらつき防止も兼ねる）。
//       視点は原点の真上「視点の高さ」にある想定（スカイボックスなので動いても見え方は変わらない）。
//       VRChat の Single Pass Stereo Instancing に対応。
//       ※ [Header()] の中は Unity の制約で日本語が使えないため英語。
// バージョン: 3.5.0
//   a: 大きな変更（破壊的変更・仕様変更）
//   b: 機能追加・変更
//   c: 些細な修正・調整
// [変更履歴]
//   3.5.0 - 不具合修正: 戸建ての庭木が家の位置を見ずに置かれ、家と重なっていた。
//           家の周りでいちばん広く空いている側（庭）に、はみ出さない大きさで置くように（狭ければ置かない）。
//           ハロウィン用に「ほうきに乗った魔女」を追加: 影絵の魔女が街の上を回り、
//           「月の前を横切る」がオンなら月と同じ高さを飛んで、一周に一度、月の前を黒い影で横切る。
//           ほうきの先にかぼちゃランタンの灯り、後ろに光の粉の尾
//   3.4.0 - 街灯の照り返しを作り直し: 周りの 3×3 マスの街灯から届く光を足し合わせ（区画の境目で切れない）、
//           地面の色に「掛けて」照らすように（上から色を塗ったように見えていた）。
//           街明かりの照り返しも色に掛ける形に。
//           雨・雪を追加（視点の周りの円筒に描く。建物より奥には降らせない）。雪の積もり（屋根・地面・木）。
//           生成ウィンドウの読み込み用に、時間帯などを覚えておく隠しプロパティを追加
//   3.3.0 - 交差点を自然に: 3.2.0 の「つながる側の歩道・白線を丸ごと消す」をやめ、
//           横道が入る車道の幅だけ開けて、曲がり角の歩道は残す（角で歩道がつながる）。
//           行き止まりは歩道で閉じる。交差点の手前に横断歩道。通り抜ける道路の中央線は途切れさせない。
//           サンタ（赤い鼻のトナカイ・鈴のきらめき・金色のそり・きらめきの尾）を追加
//   3.2.0 - 道路のつながりを修正: T字路・交差の手前で歩道と白線を途切れさせる。
//           建物が始まる距離より近くでも道路は描く。街区の中の横道は縦の道がある所だけ（行き止まり防止）。
//           夜の道路・歩道・芝生・木・地面の初期色を明るく。
//           空の乗り物を追加: 旅客機（翼端灯・ストロボ・点滅灯・飛行機雲）と、
//           戦闘機2機の空中戦（絡み合う光の軌跡）
//   3.1.0 - 道路を道路らしく: 暗いアスファルト・中央の破線・端の白線・歩道、街灯は左右交互に間隔を空け、
//           照り返しを小さく。走る車のライト（ヘッドライト・テールランプ）を追加。
//           地面・公園・木に月明かりと街明かりの照り返しが当たるように。公園の街灯を追加。
//           窓の「白っぽい明かり」を青白 → 暖かい白に。高層ビルだけ白っぽくするのをやめた。
//           マンションを描き分け: 共用廊下側（手すり壁・天井の灯りの列）とベランダ側
//           （すりガラスの手すり・1戸ごとに点く窓・戸境の仕切り）、短い面は壁
//   3.0.0 - 街並みを作り直し。格子の通り → 乱数でつながる道路網。マンション・戸建て・
//           公園・木を追加。足元（近く）から建物を置き、遠くは大まかなビルで続ける。
//           窓の色を「ほぼ暖色＋一部だけ寒色」にして、色のばらつきを抑えた。かすみの色を追加
//   2.0.0 - 夜専用（MET/Skybox/NightCity）から、どの時間帯にもできる Metlab/Skybox/City へ
// ============================================================
Shader "Metlab/Skybox/City"
{
    Properties
    {
        [Header(Sky)]
        _ZenithColor ("空の色（真上）", Color) = (0.008, 0.012, 0.035, 1)
        _HorizonColor ("空の色（地平線）", Color) = (0.035, 0.045, 0.09, 1)
        _SkyGradientPower ("空のグラデーションの鋭さ", Range(0.1, 4)) = 0.6
        _CityGlowColor ("地平線の照り返しの色（夜は街明かり・昼はかすみ）", Color) = (0.30, 0.18, 0.12, 1)
        _CityGlowIntensity ("地平線の照り返しの強さ", Range(0, 3)) = 0.7
        _CityGlowHeight ("地平線の照り返しの高さ", Range(0.01, 1)) = 0.12
        _Exposure ("全体の明るさ", Range(0, 4)) = 1

        [Header(Stars)]
        _StarDensity ("星の細かさ", Range(50, 600)) = 260
        _StarAmount ("星の数", Range(0, 1)) = 0.2
        _StarSize ("星の大きさ", Range(0.02, 0.2)) = 0.1
        _StarBrightness ("星の明るさ", Range(0, 5)) = 1.5
        _StarTwinkle ("星のまたたき", Range(0, 1)) = 0.5

        [Header(Moon or Sun)]
        _MoonAzimuth ("月・太陽の方角（度）", Range(0, 360)) = 140
        _MoonAltitude ("月・太陽の高さ（度）", Range(-10, 90)) = 28
        _MoonSize ("月・太陽の大きさ", Range(0.005, 0.2)) = 0.035
        _MoonColor ("月・太陽の色（建物に当たる光の色にもなる）", Color) = (1, 0.96, 0.86, 1)
        _MoonBrightness ("月・太陽の明るさ", Range(0, 20)) = 3
        _MoonPhase ("欠け具合（0 満月 / 1 新月・太陽は 0）", Range(0, 1)) = 0.25
        _MoonPhaseAngle ("欠ける向き（度）", Range(0, 360)) = 200
        _MoonCrater ("模様の濃さ（太陽は 0）", Range(0, 1)) = 0.35
        _MoonGlowColor ("光の輪の色", Color) = (0.45, 0.5, 0.65, 1)
        _MoonGlowIntensity ("光の輪の強さ", Range(0, 3)) = 0.5
        _MoonGlowSharpness ("光の輪の鋭さ（大きいほど小さい輪）", Range(2, 80)) = 14

        [Header(Clouds)]
        _CloudCoverage ("雲の量", Range(0, 1)) = 0.45
        _CloudSoftness ("雲の柔らかさ", Range(0.01, 0.5)) = 0.18
        _CloudScale ("雲の大きさ（大きいほど細かい）", Range(0.1, 10)) = 1.6
        _CloudSpeed ("雲の速さ", Range(0, 1)) = 0.02
        _CloudDirection ("雲の流れる向き（度）", Range(0, 360)) = 30
        _CloudOpacity ("雲の濃さ", Range(0, 1)) = 0.85
        _CloudColor ("雲の色（影）", Color) = (0.05, 0.055, 0.08, 1)
        _CloudLitColor ("雲の色（月・太陽に照らされた所）", Color) = (0.42, 0.44, 0.52, 1)
        _CloudCityLight ("雲の下側に映る街明かり", Range(0, 2)) = 0.6

        [Header(City Layout)]
        _ViewHeight ("視点の高さ（m）", Float) = 60
        _CityNear ("建物が始まる距離（m）", Float) = 30
        _DetailDistance ("細かく描く距離（m・これより遠くは大まかなビルだけ）", Float) = 900
        _CityFar ("街が終わる距離（m）", Float) = 4000
        _CellSize ("区画の最小単位＝道路の幅（m）", Float) = 12
        _SuperblockCells ("大きな街区の大きさ（区画の数）", Range(4, 12)) = 7
        _SideRoadChance ("街区の境の縦の道の多さ", Range(0, 1)) = 0.75
        _InnerRoadChance ("街区の中の道の多さ", Range(0, 1)) = 0.6
        _CitySeed ("街の配置の種（変えると並びが変わる）", Float) = 0

        [Header(Buildings)]
        _MansionRatio ("マンションの割合", Range(0, 1)) = 0.45
        _TowerRatio ("高層ビルの割合", Range(0, 1)) = 0.06
        _HouseRatio ("戸建ての割合", Range(0, 1)) = 0.25
        _ParkRatio ("公園の割合", Range(0, 1)) = 0.1
        _MansionFloorsMin ("マンションの階数（最小）", Range(2, 40)) = 4
        _MansionFloorsMax ("マンションの階数（最大）", Range(2, 40)) = 14
        _TowerHeightMin ("高層ビルの高さ（最小 m）", Float) = 70
        _TowerHeightMax ("高層ビルの高さ（最大 m）", Float) = 200
        _FloorHeight ("1階分の高さ（m）", Float) = 3.1
        _BuildingColor ("建物の壁の色", Color) = (0.018, 0.022, 0.032, 1)
        _BuildingColorVariation ("建物の壁の色のばらつき", Range(0, 1)) = 0.3
        _BuildingAmbient ("建物の明るさ（空からの光）", Range(0, 3)) = 1
        _MoonLightOnBuildings ("建物に当たる月・太陽の光の強さ", Range(0, 1)) = 0.25

        [Header(Windows)]
        _WindowColorWarm ("窓の明かりの色（ふつう）", Color) = (1, 0.8, 0.55, 1)
        _WindowColorCool ("窓の明かりの色（白っぽい）", Color) = (1, 0.95, 0.86, 1)
        _WindowCoolRatio ("白っぽい明かりの割合", Range(0, 1)) = 0.12
        _WindowBrightnessVariation ("窓の明るさのばらつき", Range(0, 1)) = 0.25
        _WindowGlassColor ("明かりの無い窓のガラスの色", Color) = (0.01, 0.012, 0.018, 1)
        _WindowLitRatio ("明かりの付いた窓の割合", Range(0, 1)) = 0.35
        _WindowBrightness ("窓の明かりの明るさ", Range(0, 5)) = 1.4
        _RoofLightColor ("航空障害灯の色", Color) = (1, 0.08, 0.04, 1)
        _RoofLightMinHeight ("航空障害灯を付ける高さ（m 以上）", Float) = 100
        _RoofLightBrightness ("航空障害灯の明るさ", Range(0, 10)) = 4

        [Header(Mansions)]
        _UnitWidth ("マンションの1戸の幅（m）", Float) = 6.5
        _CorridorLightColor ("共用廊下の明かりの色", Color) = (1, 0.93, 0.78, 1)
        _CorridorLightBrightness ("共用廊下の明かりの明るさ", Range(0, 5)) = 1.2

        [Header(Ground and Trees)]
        _GroundColor ("敷地の地面の色", Color) = (0.04, 0.04, 0.045, 1)
        _RoadColor ("道路の色", Color) = (0.03, 0.03, 0.035, 1)
        _ParkColor ("芝生の色", Color) = (0.03, 0.05, 0.03, 1)
        _TreeColor ("木の色", Color) = (0.035, 0.06, 0.04, 1)
        _TreeSize ("木の大きさ（m）", Range(1, 6)) = 3.2
        _StreetLightColor ("街灯の色", Color) = (1, 0.75, 0.45, 1)
        _StreetLightBrightness ("街灯の明るさ", Range(0, 5)) = 1

        _SidewalkColor ("歩道の色", Color) = (0.06, 0.06, 0.065, 1)
        _RoadMarkingColor ("道路の白線の色", Color) = (0.3, 0.3, 0.3, 1)
        _ParkLightChance ("公園の街灯の多さ", Range(0, 1)) = 0.35

        [Header(Cars)]
        _CarDensity ("車の多さ", Range(0, 1)) = 0.35
        _CarSpeed ("車の速さ（m／秒）", Float) = 12
        _HeadlightColor ("ヘッドライトの色", Color) = (1, 0.95, 0.85, 1)
        _TaillightColor ("テールランプの色", Color) = (1, 0.08, 0.04, 1)
        _CarLightBrightness ("車のライトの明るさ", Range(0, 5)) = 1.5

        [Header(Airliners)]
        [IntRange] _AirlinerCount ("旅客機の数", Range(0, 3)) = 1
        _AirlinerAltitude ("旅客機の高さ（m）", Float) = 1500
        _AirlinerDistance ("旅客機の航路の広がり（m）", Float) = 3000
        _AirlinerSpeed ("旅客機の速さ（m／秒）", Float) = 120
        _AirlinerRouteLength ("1回の横断の距離（m）", Float) = 30000
        _AirlinerSpan ("翼の幅（m）", Float) = 60
        _AirlinerLightBrightness ("旅客機の灯りの明るさ", Range(0, 5)) = 1.5
        _AirlinerBodyColor ("旅客機の機体の色（昼に見える。夜は黒）", Color) = (0, 0, 0, 1)
        _ContrailColor ("飛行機雲の色", Color) = (1, 1, 1, 1)
        _ContrailBrightness ("飛行機雲の濃さ（0 = 無し）", Range(0, 2)) = 0
        _ContrailLength ("飛行機雲の長さ（秒）", Float) = 40

        [Header(Dogfight)]
        [ToggleUI] _DogfightEnabled ("戦闘機の空中戦を出す", Float) = 0
        _DogfightAzimuth ("空中戦の方角（度）", Range(0, 360)) = 60
        _DogfightElevation ("空中戦の高さ（度）", Range(0, 80)) = 25
        _DogfightDistance ("空中戦までの距離（m）", Float) = 4000
        _DogfightSize ("空中戦の広さ（m）", Float) = 700
        _DogfightSpeed ("動きの速さ", Range(0, 3)) = 0.6
        _DogfightChaos ("動きの激しさ", Range(0, 1)) = 0.6
        _DogfightChaseLag ("追う側の遅れ", Range(0, 2)) = 0.35
        _DogfightTrailLength ("軌跡の長さ（秒）", Range(0.5, 20)) = 5
        _DogfightTrailWidth ("軌跡の太さ（m）", Float) = 4
        _DogfightColorA ("1機目の軌跡の色", Color) = (0.55, 0.8, 1, 1)
        _DogfightColorB ("2機目の軌跡の色", Color) = (1, 0.65, 0.35, 1)
        _DogfightBrightness ("空中戦の明るさ（小さいほどうっすら）", Range(0, 3)) = 0.5

        [Header(Santa)]
        [ToggleUI] _SantaEnabled ("サンタを飛ばす", Float) = 0
        _SantaRadius ("サンタが回る半径（m）", Float) = 600
        _SantaAltitude ("サンタの高さ（m）", Float) = 120
        _SantaSpeed ("サンタの速さ（m／秒）", Float) = 25
        _SantaBob ("上下のゆれ（m）", Float) = 8
        _SantaTrailLength ("きらめきの尾の長さ（秒）", Range(0, 10)) = 3
        _SantaNoseColor ("トナカイの鼻の色", Color) = (1, 0.1, 0.05, 1)
        _SantaSparkleColor ("きらめきの色", Color) = (1, 0.85, 0.5, 1)
        _SantaBrightness ("サンタの明るさ", Range(0, 5)) = 1.5

        [Header(Witch Halloween)]
        [ToggleUI] _WitchEnabled ("ほうきに乗った魔女を飛ばす（ハロウィン）", Float) = 0
        [ToggleUI] _WitchCrossMoon ("月の前を横切る（高さを月に合わせる）", Float) = 1
        _WitchRadius ("魔女が回る半径（m）", Float) = 400
        _WitchAltitude ("魔女の高さ（m・月の前を横切らない時）", Float) = 150
        _WitchSpeed ("魔女の速さ（m／秒）", Float) = 30
        _WitchBob ("上下のゆれ（m）", Float) = 6
        _WitchSize ("魔女の大きさ（ほうきの長さ m）", Float) = 16
        _WitchColor ("影絵の色", Color) = (0.015, 0.01, 0.025, 1)
        _WitchLanternColor ("ほうきの先のかぼちゃランタンの色", Color) = (1, 0.45, 0.08, 1)
        _WitchSparkleColor ("光の粉の色", Color) = (0.7, 0.4, 1, 1)
        _WitchTrailLength ("光の粉の尾の長さ（秒）", Range(0, 10)) = 2.5
        _WitchBrightness ("ランタン・光の粉の明るさ", Range(0, 5)) = 1.5

        [Header(Weather)]
        _RainAmount ("雨の量（0 = 降らない）", Range(0, 1)) = 0
        _RainSpeed ("雨の落ちる速さ（m／秒）", Float) = 9
        _RainColor ("雨の色（明るさ）", Color) = (0.3, 0.32, 0.36, 1)
        _SnowAmount ("雪の量（0 = 降らない）", Range(0, 1)) = 0
        _SnowSpeed ("雪の落ちる速さ（m／秒）", Float) = 1.2
        _SnowColor ("雪の色（明るさ）", Color) = (0.6, 0.62, 0.68, 1)
        _PrecipWind ("風で斜めに降る度合い", Range(-1, 1)) = 0.15
        _SnowCover ("雪の積もり具合（屋根・地面・木）", Range(0, 1)) = 0
        _SnowGroundColor ("積もった雪の色", Color) = (0.12, 0.12, 0.14, 1)

        [HideInInspector] _GenTimeOfDay ("生成ウィンドウ: 時間帯", Float) = 0
        [HideInInspector] _GenCityBrightness ("生成ウィンドウ: 街の明るさ", Float) = 0.5
        [HideInInspector] _GenWeather ("生成ウィンドウ: 天気", Float) = 0
        [HideInInspector] _GenPrecipAmount ("生成ウィンドウ: 雨・雪の強さ", Float) = 0.5
        [HideInInspector] _GenUseDefaultBody ("生成ウィンドウ: 月・太陽の位置は標準", Float) = 1

        [Header(Haze and Quality)]
        _FogColor ("かすみの色（a = 地平線の空の色との混ぜ具合）", Color) = (0.5, 0.5, 0.55, 0)
        _FogDensity ("遠くのかすみの濃さ", Range(0, 0.004)) = 0.0008
        [IntRange] _MaxSteps ("計算の歩数・近く（品質）", Range(16, 200)) = 110
        [IntRange] _MaxFarSteps ("計算の歩数・遠く（品質）", Range(0, 96)) = 48
    }

    SubShader
    {
        Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" }
        Cull Off
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.5
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            // ループの上限（コンパイル時）。実際の歩数は _MaxSteps / _MaxFarSteps
            #define MAX_STEPS_LIMIT 200
            #define MAX_FAR_STEPS_LIMIT 96
            #define TRAIL_SAMPLES 24
            #define SANTA_SPARKLES 24
            #define WITCH_SPARKLES 20
            #define GARDEN_TREE_MIN 0.8     // 庭木の半径がこれ（m）より小さくなるなら置かない
            #define GARDEN_TREE_MARGIN 0.3  // 庭木と家のすき間（m）
            #define PRECIP_LAYERS 4         // 雨・雪の円筒の数
            #define PRECIP_NEAR 6.0         // 一番手前の円筒の半径（m）
            #define PRECIP_STEP 2.2         // 円筒ごとの半径の倍率
            #define LAMP_RADIUS 5.0         // 街灯の明るい範囲（m）
            #define LAMP_REACH 15.0         // 街灯の光が届く範囲（m）
            #define LAMP_AVERAGE 0.12       // 遠くで1つずつ描かない時の、街灯の光の平均
            #define LAMP_GAIN 6.0           // 街灯の光で地面がどれだけ明るくなるか
            #define EPS 1e-5

            // セルの種類
            #define CELL_ROAD 0
            #define CELL_LOT 1
            #define CELL_EMPTY 2
            // 敷地（ロット）の種類（建物の種類にも使う）
            #define LOT_MANSION 0
            #define LOT_TOWER 1
            #define LOT_HOUSE 2
            #define LOT_PARK 3
            #define LOT_LOW 4
            // 当たった物
            #define HIT_NONE 0
            #define HIT_BUILDING 1
            #define HIT_TREE 2

            float4 _ZenithColor, _HorizonColor, _CityGlowColor;
            float _SkyGradientPower, _CityGlowIntensity, _CityGlowHeight, _Exposure;

            float _StarDensity, _StarAmount, _StarSize, _StarBrightness, _StarTwinkle;

            float _MoonAzimuth, _MoonAltitude, _MoonSize, _MoonBrightness, _MoonPhase, _MoonPhaseAngle, _MoonCrater;
            float4 _MoonColor, _MoonGlowColor;
            float _MoonGlowIntensity, _MoonGlowSharpness;

            float _CloudCoverage, _CloudSoftness, _CloudScale, _CloudSpeed, _CloudDirection, _CloudOpacity, _CloudCityLight;
            float4 _CloudColor, _CloudLitColor;

            float _ViewHeight, _CityNear, _DetailDistance, _CityFar, _CellSize, _SuperblockCells;
            float _SideRoadChance, _InnerRoadChance, _CitySeed;

            float _MansionRatio, _TowerRatio, _HouseRatio, _ParkRatio;
            float _MansionFloorsMin, _MansionFloorsMax, _TowerHeightMin, _TowerHeightMax, _FloorHeight;
            float4 _BuildingColor;
            float _BuildingColorVariation, _BuildingAmbient, _MoonLightOnBuildings;

            float4 _WindowColorWarm, _WindowColorCool, _WindowGlassColor, _RoofLightColor;
            float _WindowCoolRatio, _WindowBrightnessVariation, _WindowLitRatio, _WindowBrightness;
            float _RoofLightMinHeight, _RoofLightBrightness;

            float4 _GroundColor, _RoadColor, _ParkColor, _TreeColor, _StreetLightColor;
            float _TreeSize, _StreetLightBrightness;
            float4 _SidewalkColor, _RoadMarkingColor, _CorridorLightColor, _HeadlightColor, _TaillightColor;
            float _ParkLightChance, _UnitWidth, _CorridorLightBrightness, _CarDensity, _CarSpeed, _CarLightBrightness;

            float _AirlinerCount, _AirlinerAltitude, _AirlinerDistance, _AirlinerSpeed, _AirlinerRouteLength, _AirlinerSpan;
            float _AirlinerLightBrightness, _ContrailBrightness, _ContrailLength;
            float4 _AirlinerBodyColor, _ContrailColor;
            float _DogfightEnabled, _DogfightAzimuth, _DogfightElevation, _DogfightDistance, _DogfightSize, _DogfightSpeed;
            float _DogfightChaos, _DogfightChaseLag, _DogfightTrailLength, _DogfightTrailWidth, _DogfightBrightness;
            float4 _DogfightColorA, _DogfightColorB;
            float _SantaEnabled, _SantaRadius, _SantaAltitude, _SantaSpeed, _SantaBob, _SantaTrailLength, _SantaBrightness;
            float4 _SantaNoseColor, _SantaSparkleColor;
            float _WitchEnabled, _WitchCrossMoon, _WitchRadius, _WitchAltitude, _WitchSpeed, _WitchBob, _WitchSize;
            float _WitchTrailLength, _WitchBrightness;
            float4 _WitchColor, _WitchLanternColor, _WitchSparkleColor;
            float _RainAmount, _RainSpeed, _SnowAmount, _SnowSpeed, _PrecipWind, _SnowCover;
            float4 _RainColor, _SnowColor, _SnowGroundColor;

            // 視線が建物・地面に当たった距離（雨・雪を建物の向こうに描かないため）
            static float g_hitT = 1e9;

            float4 _FogColor;
            float _FogDensity, _MaxSteps, _MaxFarSteps;

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 dir : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.dir = v.vertex.xyz;   // スカイボックスの頂点＝視線の向き
                return o;
            }

            // ------------------------------------------------------------
            // 乱数・ノイズ
            // ------------------------------------------------------------

            float Hash12(float2 p)
            {
                float3 p3 = frac(float3(p.xyx) * 0.1031);
                p3 += dot(p3, p3.yzx + 33.33);
                return frac((p3.x + p3.y) * p3.z);
            }

            float3 Hash32(float2 p)
            {
                float3 p3 = frac(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
                p3 += dot(p3, p3.yxz + 33.33);
                return frac((p3.xxy + p3.yzz) * p3.zyx);
            }

            float3 Hash33(float3 p3)
            {
                p3 = frac(p3 * float3(0.1031, 0.1030, 0.0973));
                p3 += dot(p3, p3.yxz + 33.33);
                return frac((p3.xxy + p3.yxx) * p3.zyx);
            }

            float ValueNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                float a = Hash12(i);
                float b = Hash12(i + float2(1, 0));
                float c = Hash12(i + float2(0, 1));
                float d = Hash12(i + float2(1, 1));
                float2 u = f * f * (3.0 - 2.0 * f);
                return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
            }

            float Fbm(float2 p)
            {
                float v = 0.0;
                float a = 0.5;
                [unroll]
                for (int k = 0; k < 5; k++)
                {
                    v += a * ValueNoise(p);
                    p = p * 2.03 + 17.1;
                    a *= 0.5;
                }
                return v / 0.97;
            }

            float SeedOffset()
            {
                return _CitySeed * 1.618;
            }

            // ------------------------------------------------------------
            // 空
            // ------------------------------------------------------------

            float3 SkyColor(float3 d)
            {
                float h = saturate(d.y);
                float3 sky = lerp(_HorizonColor.rgb, _ZenithColor.rgb, pow(h, _SkyGradientPower));
                sky += _CityGlowColor.rgb * _CityGlowIntensity * exp(-h / max(_CityGlowHeight, 0.001));
                return sky;
            }

            // かすみの色（地平線の空の色に、指定の色を混ぜる）。街並みと空の境目がなじむ
            float3 HazeColor()
            {
                float3 horizon = _HorizonColor.rgb + _CityGlowColor.rgb * _CityGlowIntensity;
                return lerp(horizon, _FogColor.rgb, _FogColor.a);
            }

            float Fog(float t)
            {
                return 1.0 - exp(-t * _FogDensity);
            }

            float3 MoonDirection()
            {
                float az = radians(_MoonAzimuth);
                float alt = radians(_MoonAltitude);
                return float3(sin(az) * cos(alt), sin(alt), cos(az) * cos(alt));
            }

            float3 Stars(float3 d, float pixAng)
            {
                float3 p = d * _StarDensity;
                float3 cell = floor(p);
                float3 f = frac(p);
                float3 h = Hash33(cell + _CitySeed);
                float exists = step(1.0 - _StarAmount, Hash33(cell + 7.7).x);

                float3 starPos = 0.25 + 0.5 * h;
                float size = _StarSize * (0.5 + h.z);
                // 1ピクセルより小さい星は、1ピクセルの大きさで暗く描く（ちらつき防止）
                float drawSize = clamp(pixAng * _StarDensity, size, 0.24);
                float dist = length(f - starPos);
                float b = saturate(1.0 - dist / drawSize);
                b *= b * saturate(size / drawSize);

                float twinkle = lerp(1.0, 0.55 + 0.45 * sin(_Time.y * (1.5 + h.x * 4.0) + h.y * 40.0), _StarTwinkle);
                float3 tint = lerp(float3(0.75, 0.82, 1.0), float3(1.0, 0.88, 0.75), h.x);
                return tint * (b * exists * twinkle * _StarBrightness);
            }

            // 月・太陽の円盤（a = 円盤の濃さ）
            float4 MoonDisk(float3 d, float3 md, float pixAng)
            {
                float cosA = dot(d, md);
                if (cosA <= 0.0) return 0;

                float3 right = normalize(cross(float3(0, 1, 0), md) + float3(EPS, 0, 0));
                float3 up = cross(md, right);
                float2 mp = float2(dot(d, right), dot(d, up)) / _MoonSize;
                float r = length(mp);
                if (r > 1.2) return 0;

                float aa = max(pixAng / _MoonSize * 1.5, 0.01);
                float disk = 1.0 - smoothstep(1.0 - aa, 1.0, r);

                // 満ち欠け: 影の円を横にずらして重ねる（0 = 影なし / 1 = 全部影）
                float pa = radians(_MoonPhaseAngle);
                float2 pr = float2(mp.x * cos(pa) - mp.y * sin(pa), mp.x * sin(pa) + mp.y * cos(pa));
                float offset = lerp(2.2, 0.0, _MoonPhase);
                float lit = smoothstep(1.0 - aa * 2.0, 1.0 + aa * 2.0, length(pr - float2(offset, 0)));

                // 模様と、縁が少し暗くなる丸み
                float crater = ValueNoise(mp * 2.5 + 11.0) * 0.6 + ValueNoise(mp * 6.0 + 3.0) * 0.4;
                float tex = 1.0 - _MoonCrater * smoothstep(0.45, 0.8, crater);
                float limb = 0.6 + 0.4 * sqrt(saturate(1.0 - r * r));

                float3 col = _MoonColor.rgb * _MoonBrightness * tex * limb * lit
                           + _MoonColor.rgb * 0.015; // 影の部分のうっすらした明るさ
                return float4(col, disk);
            }

            float3 MoonGlow(float3 d, float3 md)
            {
                float ang = acos(clamp(dot(d, md), -1.0, 1.0));
                return _MoonGlowColor.rgb * _MoonGlowIntensity * exp(-ang * _MoonGlowSharpness);
            }

            // 雲（rgb = 色、a = 濃さ）
            float4 Clouds(float3 d, float3 md)
            {
                if (d.y <= 0.0) return 0;

                // 空の高い所に平らな雲の層がある想定で、地平線に向かって細かくなる
                float2 uv = d.xz / (d.y + 0.12) * (_CloudScale * 0.5);
                float wa = radians(_CloudDirection);
                float2 wind = float2(sin(wa), cos(wa)) * _CloudSpeed * _Time.y;
                float n = Fbm(uv + wind + _CitySeed * 3.1);

                float threshold = lerp(0.78, 0.22, _CloudCoverage);
                float cover = smoothstep(threshold - _CloudSoftness, threshold + _CloudSoftness, n);
                float alpha = cover * _CloudOpacity * saturate(d.y * 8.0);

                // 月・太陽の近く・雲の薄い所ほど明るい。地平線に近い雲の下側は街明かりで染まる
                float ang = acos(clamp(dot(d, md), -1.0, 1.0));
                float moonLit = exp(-ang * 2.5) * saturate(_MoonAltitude / 10.0 + 0.5);
                float3 col = lerp(_CloudColor.rgb, _CloudLitColor.rgb, saturate(moonLit * (1.2 - cover * 0.6) + (1.0 - cover) * 0.25));
                col += _CityGlowColor.rgb * _CloudCityLight * exp(-d.y * 5.0);
                return float4(col, alpha);
            }

            // ------------------------------------------------------------
            // 空の乗り物（旅客機・戦闘機の空中戦）
            // ------------------------------------------------------------

            // 光の点（視線が点の近くを通ると光る。遠くの点は大きさを保ったまま暗く）
            float SkyGlow(float3 ro, float3 rd, float3 q, float size, float pixAng)
            {
                float s = dot(q - ro, rd);
                if (s <= 0.0) return 0.0;
                float ang = length(ro + rd * s - q) / s;
                float trueRadius = size / s;
                float radius = max(trueRadius, pixAng * 1.2);
                return exp(-(ang * ang) / (radius * radius)) * saturate(trueRadius / radius);
            }

            // 視線と線分の最短距離。s = 視線上の距離、u = 線分上の位置（0 = a / 1 = b）
            float RaySegmentDistance(float3 ro, float3 rd, float3 a, float3 b, out float s, out float u)
            {
                float3 ab = b - a;
                float3 ao = a - ro;
                float e = dot(rd, ab);
                float denom = dot(ab, ab) - e * e;
                u = denom > 1e-6 ? saturate((dot(ao, rd) * e - dot(ao, ab)) / denom) : 0.0;
                float3 q = a + ab * u;
                s = max(dot(q - ro, rd), 1e-3);
                return length(ro + rd * s - q);
            }

            // 線（軌跡・飛行機雲）の光。width = 太さ（m）。u = 線分上の位置（a → b）
            float LineGlow(float3 ro, float3 rd, float3 a, float3 b, float width, float pixAng, out float u)
            {
                float s;
                float dist = RaySegmentDistance(ro, rd, a, b, s, u);
                float ang = dist / s;
                float trueRadius = width / s;
                float radius = max(trueRadius, pixAng);
                return exp(-(ang * ang) / (radius * radius)) * saturate(trueRadius / radius);
            }

            // 旅客機 k 番目の今の位置・進む向き・右の翼の向き。横断するたびに航路が変わる
            void AirlinerState(int k, float time, out float3 pos, out float3 fwd, out float3 right)
            {
                float period = _AirlinerRouteLength / max(_AirlinerSpeed, 1.0);   // 1回の横断にかかる秒
                float tk = time + k * period * 0.37;
                float cycle = floor(tk / period);
                float prog = frac(tk / period);                                    // 0 → 1 で横断
                float3 h = Hash33(float3(cycle, k * 7.1, _CitySeed + 3.3));
                float heading = h.x * 6.2831;
                fwd = float3(sin(heading), 0.0, cos(heading));
                right = float3(fwd.z, 0.0, -fwd.x);
                float offset = lerp(-1.0, 1.0, h.y) * _AirlinerDistance;          // 視点からの横のずれ
                float altitude = _AirlinerAltitude * lerp(0.7, 1.3, h.z);
                float along = (prog - 0.5) * _AirlinerRouteLength;
                pos = float3(0.0, _ViewHeight + altitude, 0.0) + right * offset + fwd * along;
            }

            float3 Airliners(float3 rd, float pixAng)
            {
                float3 ro = float3(0.0, _ViewHeight, 0.0);
                float3 col = 0;
                float time = _Time.y;

                [loop]
                for (int k = 0; k < 3; k++)
                {
                    if (k >= (int)_AirlinerCount) break;
                    float3 pos, fwd, right;
                    AirlinerState(k, time, pos, fwd, right);

                    // 視線の向きでざっくり外す（飛行機雲の長さも含めた範囲）
                    float trail = _AirlinerSpeed * _ContrailLength * step(0.001, _ContrailBrightness);
                    float3 mid = pos - fwd * trail * 0.5;
                    float3 toM = mid - ro;
                    float distM = length(toM);
                    float cone = (_AirlinerSpan + trail * 0.5) / distM + 0.01;
                    if (dot(rd, toM / distM) < cos(min(cone, 1.5))) continue;

                    float wing = _AirlinerSpan * 0.5;
                    float3 left = pos - right * wing;
                    float3 rightTip = pos + right * wing;
                    float strobe = step(0.92, frac(time * 1.0 + k * 0.3));
                    float beacon = step(0.85, frac(time * 0.8 + k * 0.5));

                    float3 lights = 0;
                    lights += float3(1.0, 0.1, 0.05) * SkyGlow(ro, rd, left, 1.5, pixAng);       // 左の翼端: 赤
                    lights += float3(0.1, 1.0, 0.3) * SkyGlow(ro, rd, rightTip, 1.5, pixAng);    // 右の翼端: 緑
                    lights += strobe * 3.0 * (SkyGlow(ro, rd, left, 2.0, pixAng) + SkyGlow(ro, rd, rightTip, 2.0, pixAng)); // 白いストロボ
                    lights += float3(1.0, 0.15, 0.05) * beacon * 1.5 * SkyGlow(ro, rd, pos + float3(0.0, 3.0, 0.0), 1.5, pixAng); // 胴体の赤い点滅
                    col += lights * _AirlinerLightBrightness;

                    // 機体（昼に日の光で見える）
                    col += _AirlinerBodyColor.rgb * SkyGlow(ro, rd, pos, wing * 0.6, pixAng);

                    // 飛行機雲（後ろほど薄く広がる）
                    if (_ContrailBrightness > 0.0)
                    {
                        float u;
                        float g = LineGlow(ro, rd, pos - fwd * 40.0, pos - fwd * (40.0 + trail), 6.0, pixAng, u);
                        col += _ContrailColor.rgb * _ContrailBrightness * g * (1.0 - u);
                    }
                }
                return col;
            }

            // 空中戦の中心（視点から見た方角・高さ・距離で決める）
            float3 DogfightCenter()
            {
                float az = radians(_DogfightAzimuth);
                float el = radians(_DogfightElevation);
                float3 dir = float3(sin(az) * cos(el), sin(el), cos(az) * cos(el));
                return float3(0.0, _ViewHeight, 0.0) + dir * _DogfightDistance;
            }

            // 空中戦の機体 k（0 / 1）の位置。k = 1 は k = 0 を少し遅れて追いかける（絡み合う軌跡）
            float3 FighterPos(int k, float time)
            {
                float t = time * _DogfightSpeed - k * _DogfightChaseLag;
                float c = _DogfightChaos;
                float3 p;
                p.x = sin(t * 1.00 + 0.3) + c * 0.45 * sin(t * 2.31 + 1.7);
                p.y = 0.55 * sin(t * 1.63 + 0.9) + c * 0.30 * sin(t * 3.70 + 0.4);
                p.z = sin(t * 1.27 + 2.1) + c * 0.40 * cos(t * 2.93 + 0.8);
                if (k == 1) p += c * 0.25 * float3(sin(t * 4.1), cos(t * 3.3), sin(t * 3.7 + 1.0));
                return DogfightCenter() + p * _DogfightSize;
            }

            float3 Dogfight(float3 rd, float pixAng)
            {
                if (_DogfightEnabled < 0.5 || _DogfightBrightness <= 0.0) return 0;
                float3 ro = float3(0.0, _ViewHeight, 0.0);

                // 視線の向きでざっくり外す
                float3 toC = DogfightCenter() - ro;
                float distC = length(toC);
                float cone = _DogfightSize * 2.2 / distC + 0.02;
                if (dot(rd, toC / distC) < cos(min(cone, 1.5))) return 0;

                float time = _Time.y;
                float dt = _DogfightTrailLength / TRAIL_SAMPLES;
                float3 col = 0;

                [loop]
                for (int k = 0; k < 2; k++)
                {
                    float3 trailCol = k == 0 ? _DogfightColorA.rgb : _DogfightColorB.rgb;
                    float3 prev = FighterPos(k, time);
                    col += trailCol * 3.0 * SkyGlow(ro, rd, prev, 4.0, pixAng);   // 機体（噴射の光）

                    [loop]
                    for (int i = 1; i <= TRAIL_SAMPLES; i++)
                    {
                        float3 cur = FighterPos(k, time - dt * i);
                        float age = (i - 0.5) / TRAIL_SAMPLES;
                        float width = _DogfightTrailWidth * (1.0 + age * 2.0);  // 古い所ほど広がって薄くなる
                        float u;
                        col += trailCol * LineGlow(ro, rd, prev, cur, width, pixAng, u) * (1.0 - age) * (1.0 - age);
                        prev = cur;
                    }
                }
                return col * _DogfightBrightness;
            }

            // ---- サンタ（トナカイのそり） ----
            //   街の上を、ゆれながらぐるっと回って飛ぶ。
            //   先頭は赤い鼻のトナカイ、2頭ずつ並ぶトナカイ（鈴のきらめき）、金色のそり、きらめきの尾

            // そりの位置。back = 今の位置から後ろへの距離（m）。マイナスなら前
            float3 SantaPos(float back)
            {
                float r = max(_SantaRadius, 10.0);
                float ang = (_Time.y * _SantaSpeed - back) / r;
                float bob = sin(ang * 6.0) * _SantaBob;
                return float3(sin(ang) * r, _ViewHeight + _SantaAltitude + bob, cos(ang) * r);
            }

            float3 Santa(float3 rd, float pixAng)
            {
                if (_SantaEnabled < 0.5 || _SantaBrightness <= 0.0) return 0;
                float3 ro = float3(0.0, _ViewHeight, 0.0);

                // 視線の向きでざっくり外す（先頭のトナカイからきらめきの尾の端まで）
                float trail = _SantaSpeed * _SantaTrailLength;
                float3 head = SantaPos(-20.0);
                float3 tailEnd = SantaPos(trail);
                float3 mid = (head + tailEnd) * 0.5;
                float3 toM = mid - ro;
                float distM = length(toM);
                float cone = (length(head - tailEnd) * 0.6 + 30.0) / distM + 0.01;
                if (dot(rd, toM / distM) < cos(min(cone, 1.5))) return 0;

                float3 col = 0;
                float3 sleigh = SantaPos(0.0);
                float3 fwd = normalize(SantaPos(-1.0) - sleigh);
                float3 side = normalize(cross(float3(0.0, 1.0, 0.0), fwd));

                // そり（金色）
                col += _SantaSparkleColor.rgb * 1.5 * SkyGlow(ro, rd, sleigh, 1.5, pixAng);

                // トナカイ（前へ2頭ずつ・鈴がきらっと光る）
                [unroll]
                for (int k = 1; k <= 4; k++)
                {
                    float3 c = SantaPos(-3.0 * k);
                    float bell = 0.6 + 0.4 * sin(_Time.y * 9.0 + k * 1.7);
                    float g = SkyGlow(ro, rd, c + side * 0.8, 0.5, pixAng) + SkyGlow(ro, rd, c - side * 0.8, 0.5, pixAng);
                    col += _SantaSparkleColor.rgb * 0.45 * bell * g;
                }

                // 先頭のトナカイの赤い鼻
                col += _SantaNoseColor.rgb * 3.0 * SkyGlow(ro, rd, SantaPos(-16.0), 0.6, pixAng);

                // きらめきの尾（後ろへ、ちらちら光りながら広がる）
                [loop]
                for (int i = 1; i <= SANTA_SPARKLES; i++)
                {
                    float back = trail * i / SANTA_SPARKLES;
                    float3 h = Hash33(float3(i, floor(_Time.y * 8.0 + i * 0.37), 5.1));
                    float3 pos = SantaPos(back) + (h - 0.5) * (3.0 + back * 0.05);
                    float age = (float)i / SANTA_SPARKLES;
                    float twinkle = step(0.4, h.x);
                    col += _SantaSparkleColor.rgb * twinkle * (1.0 - age) * SkyGlow(ro, rd, pos, 0.4, pixAng);
                }
                return col * _SantaBrightness;
            }

            // ---- ほうきに乗った魔女（ハロウィン） ----
            //   影絵（黒いシルエット）の魔女が街の上をぐるっと回って飛ぶ。
            //   「月の前を横切る」なら、飛ぶ高さを月の高さ（仰角）に合わせるので、一周に一度、月の前を横切る。
            //   ほうきの先にかぼちゃランタンの灯り、ほうきの後ろに光の粉の尾

            // 魔女の位置。back = 今の位置から後ろへの距離（m）。マイナスなら前。サンタとは逆回り
            float3 WitchPos(float back)
            {
                float r = max(_WitchRadius, 10.0);
                float ang = -(_Time.y * _WitchSpeed - back) / r;
                float height = _WitchCrossMoon > 0.5 ? r * tan(radians(clamp(_MoonAltitude, 3.0, 80.0))) : _WitchAltitude;
                float bob = sin(ang * 7.0) * _WitchBob;
                return float3(sin(ang) * r, _ViewHeight + height + bob, cos(ang) * r);
            }

            // 2D の形（符号付き距離。中が負）
            float SdSegment(float2 p, float2 a, float2 b, float r)
            {
                float2 pa = p - a;
                float2 ba = b - a;
                float h = saturate(dot(pa, ba) / max(dot(ba, ba), 1e-6));
                return length(pa - ba * h) - r;
            }

            float SdTriangle(float2 p, float2 p0, float2 p1, float2 p2)
            {
                float2 e0 = p1 - p0, e1 = p2 - p1, e2 = p0 - p2;
                float2 v0 = p - p0, v1 = p - p1, v2 = p - p2;
                float2 pq0 = v0 - e0 * saturate(dot(v0, e0) / dot(e0, e0));
                float2 pq1 = v1 - e1 * saturate(dot(v1, e1) / dot(e1, e1));
                float2 pq2 = v2 - e2 * saturate(dot(v2, e2) / dot(e2, e2));
                float sgn = sign(e0.x * e2.y - e0.y * e2.x);
                float2 d = min(min(float2(dot(pq0, pq0), sgn * (v0.x * e0.y - v0.y * e0.x)),
                                   float2(dot(pq1, pq1), sgn * (v1.x * e1.y - v1.y * e1.x))),
                                   float2(dot(pq2, pq2), sgn * (v2.x * e2.y - v2.y * e2.x)));
                return -sqrt(d.x) * sign(d.y);
            }

            // 魔女の影絵の形。q = ほうきの長さを 1 とした座標（x = 進む向き、y = 上）
            float WitchSdf(float2 q, float time)
            {
                // 少し前後にかしぐ
                float tilt = sin(time * 1.3) * 0.07;
                float cs = cos(tilt), sn = sin(tilt);
                q = float2(q.x * cs - q.y * sn, q.x * sn + q.y * cs);
                float flap = sin(time * 9.0);

                float d = SdSegment(q, float2(-0.42, -0.03), float2(0.52, 0.02), 0.014);                    // ほうきの柄
                d = min(d, SdTriangle(q, float2(-0.38, -0.01), float2(-0.72, 0.05 + flap * 0.01), float2(-0.70, -0.14)) - 0.01); // ほうきの穂
                d = min(d, SdTriangle(q, float2(-0.13, -0.02), float2(0.12, -0.02), float2(0.03, 0.24)));   // 胴・スカート
                d = min(d, SdSegment(q, float2(0.03, -0.02), float2(0.13, -0.13), 0.022));                 // 足
                d = min(d, SdSegment(q, float2(0.13, -0.13), float2(0.19, -0.12), 0.018));                 // 靴
                d = min(d, SdSegment(q, float2(0.05, 0.19), float2(0.22, 0.03), 0.018));                  // 腕（ほうきを持つ）
                d = min(d, length(q - float2(0.06, 0.29)) - 0.05);                                         // 頭
                d = min(d, SdSegment(q, float2(-0.04, 0.325), float2(0.16, 0.335), 0.012));               // 帽子のつば
                d = min(d, SdTriangle(q, float2(-0.005, 0.33), float2(0.125, 0.33), float2(-0.09, 0.53)));  // とんがり帽子
                d = min(d, SdTriangle(q, float2(0.05, 0.23), float2(-0.04, 0.15), float2(-0.34, 0.09 + flap * 0.035))); // なびくマント
                return d;
            }

            // 魔女の影絵の濃さ（0〜1）
            float WitchMask(float3 rd, float pixAng)
            {
                if (_WitchEnabled < 0.5) return 0;
                float3 ro = float3(0.0, _ViewHeight, 0.0);
                float3 w = WitchPos(0.0);
                float3 toW = w - ro;
                float dist = length(toW);
                float3 v = toW / dist;
                float size = max(_WitchSize, 0.1);

                // 視線の向きでざっくり外す
                float cosV = dot(rd, v);
                if (cosV < cos(min(size * 0.9 / dist + pixAng * 3.0, 1.5))) return 0;

                // 魔女を通り、視線に垂直な面の上の座標にする（x = 進む向き、y = 上）
                float t = dist / max(cosV, 1e-3);
                float3 o = ro + rd * t - w;
                float3 fwd = normalize(WitchPos(-1.0) - w);
                float3 ax = fwd - v * dot(fwd, v);
                if (dot(ax, ax) < 1e-6) ax = cross(float3(0.0, 1.0, 0.0), v);
                ax = normalize(ax);
                float3 ay = normalize(cross(v, ax));
                if (ay.y < 0.0) ay = -ay;
                float2 q = float2(dot(o, ax), dot(o, ay)) / size;

                float px = pixAng * t / size;   // 1ピクセルの大きさ（ほうきの長さを 1 とした単位）
                float sdf = WitchSdf(q, _Time.y);
                return 1.0 - smoothstep(-px, px, sdf);
            }

            // ランタンの灯りと光の粉
            float3 WitchLights(float3 rd, float pixAng)
            {
                if (_WitchEnabled < 0.5 || _WitchBrightness <= 0.0) return 0;
                float3 ro = float3(0.0, _ViewHeight, 0.0);
                float size = max(_WitchSize, 0.1);

                float trail = _WitchSpeed * _WitchTrailLength;
                float3 head = WitchPos(-size);
                float3 tailEnd = WitchPos(trail + size);
                float3 mid = (head + tailEnd) * 0.5;
                float3 toM = mid - ro;
                float distM = length(toM);
                float cone = (length(head - tailEnd) * 0.6 + size * 2.0) / distM + 0.01;
                if (dot(rd, toM / distM) < cos(min(cone, 1.5))) return 0;

                float3 w = WitchPos(0.0);
                float3 fwd = normalize(WitchPos(-1.0) - w);
                float3 col = 0;

                // ほうきの先のかぼちゃランタン（ゆらめく）
                float flicker = 0.75 + 0.25 * sin(_Time.y * 13.0) * sin(_Time.y * 7.3 + 1.0);
                float3 lantern = w + fwd * (0.56 * size) - float3(0.0, 0.07 * size, 0.0);
                col += _WitchLanternColor.rgb * 2.5 * flicker * SkyGlow(ro, rd, lantern, size * 0.035, pixAng);

                // 光の粉の尾（ほうきの穂の後ろから、ちらちら光りながら広がる）
                [loop]
                for (int i = 1; i <= WITCH_SPARKLES; i++)
                {
                    float back = trail * i / WITCH_SPARKLES;
                    float3 h = Hash33(float3(i, floor(_Time.y * 7.0 + i * 0.41), 9.7));
                    float3 pos = WitchPos(back + size * 0.7) + (h - 0.5) * (size * 0.2 + back * 0.06);
                    float age = (float)i / WITCH_SPARKLES;
                    float twinkle = step(0.45, h.x);
                    col += _WitchSparkleColor.rgb * twinkle * (1.0 - age) * SkyGlow(ro, rd, pos, size * 0.025, pixAng);
                }
                return col * _WitchBrightness;
            }

            // ------------------------------------------------------------
            // 交差判定
            // ------------------------------------------------------------

            // 箱と視線の交差（入った面の法線も返す）
            bool IntersectBox(float3 ro, float3 rd, float3 bmin, float3 bmax, out float tHit, out float3 n)
            {
                float3 inv = 1.0 / (rd + (rd >= 0 ? EPS : -EPS));
                float3 t0 = (bmin - ro) * inv;
                float3 t1 = (bmax - ro) * inv;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);
                tHit = max(max(tmin.x, tmin.y), tmin.z);
                float tFar = min(min(tmax.x, tmax.y), tmax.z);
                n = 0;
                if (tFar < max(tHit, 0.0) || tHit < 0.0) return false;

                if (tHit == tmin.x) n = float3(-sign(rd.x), 0, 0);
                else if (tHit == tmin.y) n = float3(0, -sign(rd.y), 0);
                else n = float3(0, 0, -sign(rd.z));
                return true;
            }

            bool IntersectSphere(float3 ro, float3 rd, float4 sph, out float tHit, out float3 n)
            {
                float3 oc = ro - sph.xyz;
                float b = dot(oc, rd);
                float c = dot(oc, oc) - sph.w * sph.w;
                float h = b * b - c;
                tHit = 0;
                n = 0;
                if (h < 0.0 || sph.w <= 0.0) return false;
                tHit = -b - sqrt(h);
                if (tHit < 0.0) return false;
                n = (ro + rd * tHit - sph.xyz) / sph.w;
                return true;
            }

            // 一番近い当たりを覚えておく
            void TryBox(float3 ro, float3 rd, float3 bmin, float3 bmax, int btype, float2 bid,
                        inout float bestT, inout float3 bestN, inout int bestKind, inout int bestType, inout float2 bestId,
                        inout float3 bestMin, inout float3 bestMax)
            {
                float t;
                float3 n;
                if (IntersectBox(ro, rd, bmin, bmax, t, n) && t < bestT)
                {
                    bestT = t; bestN = n; bestKind = HIT_BUILDING; bestType = btype; bestId = bid;
                    bestMin = bmin; bestMax = bmax;
                }
            }

            void TrySphere(float3 ro, float3 rd, float4 sph,
                           inout float bestT, inout float3 bestN, inout int bestKind)
            {
                float t;
                float3 n;
                if (IntersectSphere(ro, rd, sph, t, n) && t < bestT)
                {
                    bestT = t; bestN = n; bestKind = HIT_TREE;
                }
            }

            // ------------------------------------------------------------
            // 街の配置（道路網・敷地）
            // ------------------------------------------------------------

            struct CellInfo
            {
                int type;       // CELL_ROAD / CELL_LOT / CELL_EMPTY
                int roadAxis;   // 0: x 方向に伸びる道路 / 1: z 方向 / 2: 交差点
                float4 lot;     // 敷地の範囲（セル番号 xMin, zMin, xMax, zMax・両端を含む）
                int lotType;    // LOT_～
                float2 lotId;
            };

            // セル（区画）が道路か敷地かを決める。
            //   大きな街区（N×N セル）ごとに:
            //     ・下端の行（ly = 0）は横の大通り（どこまでもつながる）
            //     ・左端の列（lx = 0）は縦の道（ある確率で）。街区の並びは行ごとにずらす
            //     ・街区の中に縦の道（上下の大通りをつなぐ）、その左側に横の道（T字路）
            float SuperblockCells()
            {
                return max(floor(_SuperblockCells), 4.0);
            }

            // 街区の行ごとの横のずれ（セル数）
            float RowOffset(float sy)
            {
                return floor(Hash12(float2(sy, 7.13) + SeedOffset()) * SuperblockCells());
            }

            // 街区ごとの道路の有無と位置
            void SuperblockRoads(float2 sb, out bool sideRoad, out bool innerV, out bool innerH, out float vPos, out float hPos)
            {
                float N = SuperblockCells();
                float s = SeedOffset();
                sideRoad = Hash12(sb + s + 3.1) < _SideRoadChance;
                innerV = Hash12(sb + s + 5.7) < _InnerRoadChance;
                vPos = 2.0 + floor(Hash12(sb + s + 9.7) * (N - 3.0));       // 2 〜 N-2
                innerH = innerV && sideRoad && Hash12(sb + s + 4.4) < _InnerRoadChance * 0.7; // 両端が道路につながる時だけ
                hPos = 2.0 + floor(Hash12(sb + s + 6.6) * (N - 3.0));
            }

            int LotTypeOf(float2 lotId)
            {
                float lt = Hash12(lotId + SeedOffset() + 11.3);
                float c0 = _MansionRatio;
                float c1 = c0 + _TowerRatio;
                float c2 = c1 + _HouseRatio;
                float c3 = c2 + _ParkRatio;
                return lt < c0 ? LOT_MANSION : (lt < c1 ? LOT_TOWER : (lt < c2 ? LOT_HOUSE : (lt < c3 ? LOT_PARK : LOT_LOW)));
            }

            // 街区 sb の region 番目（0〜2）の敷地。無ければ false（GetCell と同じ決め方）
            bool SuperblockLot(float2 sb, int region, out CellInfo ci)
            {
                ci.type = CELL_LOT;
                ci.roadAxis = 0;
                ci.lot = 0;
                ci.lotType = LOT_LOW;
                ci.lotId = 0;

                bool sideRoad, innerV, innerH;
                float vPos, hPos;
                SuperblockRoads(sb, sideRoad, innerV, innerH, vPos, hPos);
                if (region == 1 && !innerV) return false;
                if (region == 2 && !innerH) return false;

                float N = SuperblockCells();
                float xMin = sideRoad ? 1.0 : 0.0;
                float xMax = N - 1.0;
                float zMin = 1.0;
                float zMax = N - 1.0;
                if (region == 1)
                {
                    xMin = vPos + 1.0;
                }
                else
                {
                    if (innerV) xMax = vPos - 1.0;
                    if (innerH)
                    {
                        if (region == 0) zMax = hPos - 1.0;
                        else zMin = hPos + 1.0;
                    }
                }
                float baseX = sb.x * N + RowOffset(sb.y);
                float baseZ = sb.y * N;
                ci.lot = float4(baseX + xMin, baseZ + zMin, baseX + xMax, baseZ + zMax);
                ci.lotId = sb * 3.0 + float2(region, region * 0.5 + 0.25);
                ci.lotType = LotTypeOf(ci.lotId);

                // 街の範囲の外は無し
                float r = length((ci.lot.xy + ci.lot.zw + 1.0) * 0.5 * _CellSize);
                return r >= _CityNear && r <= _CityFar;
            }

            CellInfo GetCell(float2 cell)
            {
                CellInfo ci;
                ci.type = CELL_LOT;
                ci.roadAxis = 0;
                ci.lot = 0;
                ci.lotType = LOT_LOW;
                ci.lotId = 0;

                float r = length((cell + 0.5) * _CellSize);
                if (r > _CityFar)
                {
                    ci.type = CELL_EMPTY;
                    return ci;
                }

                float N = SuperblockCells();
                float sy = floor(cell.y / N);
                float rowOff = RowOffset(sy);
                float sx = floor((cell.x - rowOff) / N);
                float lx = cell.x - rowOff - sx * N;
                float ly = cell.y - sy * N;
                float2 sb = float2(sx, sy);

                bool sideRoad, innerV, innerH;
                float vPos, hPos;
                SuperblockRoads(sb, sideRoad, innerV, innerH, vPos, hPos);

                bool alongX = (ly < 0.5) || (innerH && abs(ly - hPos) < 0.5 && lx < vPos);
                bool alongZ = (sideRoad && lx < 0.5) || (innerV && abs(lx - vPos) < 0.5);
                if (alongX || alongZ)
                {
                    ci.type = CELL_ROAD;
                    ci.roadAxis = (alongX && alongZ) ? 2 : (alongX ? 0 : 1);
                    return ci;
                }

                // 建物が始まる距離より近くは、道路だけ（敷地には何も置かない）
                if (r < _CityNear)
                {
                    ci.type = CELL_EMPTY;
                    return ci;
                }

                // 道路で区切られた敷地の範囲
                float xMin = sideRoad ? 1.0 : 0.0;
                float xMax = N - 1.0;
                float zMin = 1.0;
                float zMax = N - 1.0;
                float region = 0.0;
                if (innerV)
                {
                    if (lx < vPos) xMax = vPos - 1.0;
                    else { xMin = vPos + 1.0; region = 1.0; }
                }
                if (innerH && lx < vPos)
                {
                    if (ly < hPos) zMax = hPos - 1.0;
                    else { zMin = hPos + 1.0; region = 2.0; }
                }
                float baseX = sx * N + rowOff;
                float baseZ = sy * N;
                ci.lot = float4(baseX + xMin, baseZ + zMin, baseX + xMax, baseZ + zMax);
                ci.lotId = sb * 3.0 + float2(region, region * 0.5 + 0.25);
                ci.lotType = LotTypeOf(ci.lotId);
                return ci;
            }

            // 敷地の建物（マンション・高層ビル・低い建物）。戻り値 = 棟数（0〜2）
            int LotBoxes(CellInfo ci, out float3 bmin0, out float3 bmax0, out float3 bmin1, out float3 bmax1)
            {
                bmin0 = 0; bmax0 = 0; bmin1 = 0; bmax1 = 0;
                float C = _CellSize;
                float inset = C * 0.2;   // 道路からの後退
                float2 lo = ci.lot.xy * C + inset;
                float2 hi = (ci.lot.zw + 1.0) * C - inset;
                float2 size = max(hi - lo, 1.0);
                float3 h = Hash32(ci.lotId + SeedOffset() + 21.7);

                if (ci.lotType == LOT_TOWER)
                {
                    float side = min(clamp(min(size.x, size.y) * lerp(0.55, 0.9, h.x), 15.0, 45.0), min(size.x, size.y));
                    float2 c = (lo + hi) * 0.5;
                    float height = lerp(_TowerHeightMin, _TowerHeightMax, pow(h.y, 1.5));
                    bmin0 = float3(c.x - side * 0.5, 0.0, c.y - side * 0.5);
                    bmax0 = float3(c.x + side * 0.5, height, c.y + side * 0.5);
                    return 1;
                }
                if (ci.lotType == LOT_LOW)
                {
                    bmin0 = float3(lo.x, 0.0, lo.y);
                    bmax0 = float3(hi.x, lerp(5.0, 12.0, h.y), hi.y);
                    return 1;
                }

                // マンション: 長い向きに沿った板状の棟。奥行きに余裕があれば2棟並べる
                float floorsMin = min(_MansionFloorsMin, _MansionFloorsMax);
                float floorsMax = max(_MansionFloorsMin, _MansionFloorsMax);
                float height0 = floor(lerp(floorsMin, floorsMax + 0.999, h.y)) * _FloorHeight;
                float height1 = floor(lerp(floorsMin, floorsMax + 0.999, h.z)) * _FloorHeight;
                bool longX = size.x >= size.y;
                float shortLen = longX ? size.y : size.x;
                float depth = min(13.0, shortLen);
                int count = shortLen > depth * 2.0 + 12.0 ? 2 : 1;
                float off = count == 1 ? (shortLen - depth) * 0.5 : 0.0;

                if (longX)
                {
                    bmin0 = float3(lo.x, 0.0, lo.y + off);
                    bmax0 = float3(hi.x, height0, lo.y + off + depth);
                    bmin1 = float3(lo.x, 0.0, hi.y - depth);
                    bmax1 = float3(hi.x, height1, hi.y);
                }
                else
                {
                    bmin0 = float3(lo.x + off, 0.0, lo.y);
                    bmax0 = float3(lo.x + off + depth, height0, hi.y);
                    bmin1 = float3(hi.x - depth, 0.0, lo.y);
                    bmax1 = float3(hi.x, height1, hi.y);
                }
                return count;
            }

            // 戸建て（セルごとに小さな家）
            bool HouseBox(float2 cell, out float3 bmin, out float3 bmax)
            {
                float3 h = Hash32(cell + SeedOffset() + 31.3);
                bmin = 0;
                bmax = 0;
                if (h.x > 0.8) return false;
                float C = _CellSize;
                float side = C * lerp(0.5, 0.68, h.y);
                float2 c = (cell + 0.5) * C + (h.zy - 0.5) * (C - side) * 0.8;
                float height = lerp(5.5, 8.5, h.z);
                bmin = float3(c.x - side * 0.5, 0.0, c.y - side * 0.5);
                bmax = float3(c.x + side * 0.5, height, c.y + side * 0.5);
                return true;
            }

            // 戸建ての庭木：家の周りでいちばん広く空いている側（庭）に、家と重ならない大きさで置く。
            // 置けない（庭が狭い）時は w = 0
            float4 GardenTree(float2 cell, float3 hmin, float3 hmax)
            {
                float C = _CellSize;
                float2 lo = cell * C;
                float2 hi = lo + C;
                float gapL = hmin.x - lo.x;
                float gapR = hi.x - hmax.x;
                float gapB = hmin.z - lo.y;
                float gapT = hi.y - hmax.z;
                float gap = max(max(gapL, gapR), max(gapB, gapT));

                float3 h = Hash32(cell * 1.31 + SeedOffset() + 41.9);
                float r = min(_TreeSize * lerp(0.7, 1.2, h.z), gap * 0.5 - GARDEN_TREE_MARGIN);
                if (r < GARDEN_TREE_MIN) return 0;

                float2 p;
                if (gap == gapL)      p = float2(lo.x + gapL * 0.5, lerp(lo.y + r, hi.y - r, h.x));
                else if (gap == gapR) p = float2(hi.x - gapR * 0.5, lerp(lo.y + r, hi.y - r, h.x));
                else if (gap == gapB) p = float2(lerp(lo.x + r, hi.x - r, h.x), lo.y + gapB * 0.5);
                else                  p = float2(lerp(lo.x + r, hi.x - r, h.x), hi.y - gapT * 0.5);
                return float4(p.x, r + 2.0, p.y, r);
            }

            // 木（セルの中に収まる球）。k で何本目かを変える
            float4 TreeSphere(float2 cell, float k)
            {
                float3 h = Hash32(cell * 1.31 + k * 17.0 + SeedOffset() + 41.9);
                float C = _CellSize;
                float2 local = (0.2 + 0.6 * h.xy) * C;
                float edge = min(min(local.x, local.y), min(C - local.x, C - local.y));
                float r = min(_TreeSize * lerp(0.7, 1.2, h.z), edge);
                float2 p = cell * C + local;
                return float4(p.x, r + 2.0, p.y, r);
            }

            // ------------------------------------------------------------
            // 色付け
            // ------------------------------------------------------------

            // 空からの光＋月・太陽の光（地面・木・建物の壁に共通）
            float3 SkyLight(float3 n, float3 md, float directScale)
            {
                float direct = _MoonLightOnBuildings * directScale * saturate(dot(n, md)) * saturate(md.y * 5.0 + 0.2);
                return _BuildingAmbient + _MoonColor.rgb * direct;
            }

            // 地面に当たる光（上向きの面）
            float3 GroundLight(float3 md)
            {
                return SkyLight(float3(0, 1, 0), md, 4.0);
            }

            // 街明かりの照り返し（夜の街全体をうっすら照らす暖かい光）。色に掛けて使う
            float3 CityBounce()
            {
                return _StreetLightColor.rgb * _StreetLightBrightness * 0.3;
            }

            // 小さな光の点（街灯・車のライト等）。視線が点の近くを通ると光る
            float PointGlow(float3 ro, float3 rd, float3 q, float size, float tLimit, float pixAng)
            {
                float s = dot(q - ro, rd);
                if (s <= 0.0 || s >= tLimit) return 0.0;
                float ang = length(ro + rd * s - q) / s;
                float trueRadius = size / s;
                float radius = max(trueRadius, pixAng * 1.2);
                // 遠くの点は大きさを保ったまま暗く（ちらつき防止）
                return exp(-(ang * ang) / (radius * radius)) * saturate(trueRadius / radius);
            }

            // ---- マンション ----
            //   長い面の片方 = 共用廊下側（床の縁・手すり壁・廊下の奥と天井の灯りの列）
            //   もう片方   = ベランダ側（床の縁・すりガラスの手すり・1戸ごとに点く窓・戸境の仕切り）
            //   短い面     = 壁（階段の小さな窓）
            float3 MansionFacade(float3 p, float3 n, float t, float2 bid, float3 bmin, float3 bmax, float3 wall, float3 rd, float pixAng)
            {
                float3 size = bmax - bmin;
                bool longX = size.x >= size.z;
                bool faceAlongX = abs(n.z) > 0.5;      // この面が x 方向に伸びている
                bool longFace = longX == faceAlongX;
                float u = faceAlongX ? p.x - bmin.x : p.z - bmin.z;
                float faceLen = faceAlongX ? size.x : size.z;

                float fh = max(_FloorHeight, 1.0);
                float fy = floor(p.y / fh);
                float fv = frac(p.y / fh);
                float footprint = t * pixAng / max(abs(dot(rd, n)), 0.15);
                float aa = saturate(footprint / fh * 1.5 - 0.3);

                float3 corridor = _CorridorLightColor.rgb * _CorridorLightBrightness;
                float3 concrete = wall * 1.7;  // 床の縁・手すりは明るいコンクリート

                if (!longFace)
                {
                    // 短い面: 真ん中に階段の小さな窓
                    float center = abs(u - faceLen * 0.5);
                    float stairWin = step(center, 0.6) * step(0.4, fv) * step(fv, 0.8);
                    float3 sharpE = wall + stairWin * corridor * 0.5;
                    float3 avgE = wall + corridor * 0.5 * (1.2 / max(faceLen, 1.0)) * 0.4;
                    return lerp(sharpE, avgE, aa);
                }

                float side = faceAlongX ? n.z : n.x;
                bool corridorSide = (Hash12(bid + 77.7) < 0.5) == (side > 0.0);
                float uw = max(_UnitWidth, 2.0);
                float unit = floor(u / uw);
                float fu = frac(u / uw);

                if (corridorSide)
                {
                    float3 railing = concrete * 1.15 + corridor * 0.08;   // 廊下の灯りで照らされた手すり壁
                    float3 inner = wall * 0.6 + corridor * 0.06;          // 廊下の奥（ドアの並び）
                    float dx = (fu - 0.5) * uw;
                    float dy = (fv - 0.92) * fh;
                    float spot = exp(-(dx * dx) / 0.15 - (dy * dy) / 0.02); // 天井の灯り（1戸に1つ）
                    float3 sharpC = fv < 0.08 ? concrete : (fv < 0.42 ? railing : inner + corridor * spot * 2.0);
                    float3 avgC = concrete * 0.08 + railing * 0.34 + inner * 0.58 + corridor * 0.03;
                    return lerp(sharpC, avgC, aa);
                }

                // ベランダ側: 部屋の明かりは1戸（1階分×1戸）ごとに点く。カーテン越しで明るさが違う
                float2 roomId = float2(unit, fy);
                float lit = step(Hash12(roomId + bid * 13.1), _WindowLitRatio);
                float curtain = 0.55 + 0.45 * Hash12(roomId * 1.7 + bid);
                float tone = step(Hash12(roomId * 2.3 + bid), _WindowCoolRatio);
                float3 lightCol = lerp(_WindowColorWarm.rgb, _WindowColorCool.rgb, tone) * curtain * _WindowBrightness;
                float3 room = lerp(_WindowGlassColor.rgb, lightCol, lit);

                float partition = saturate(step(fu, 0.05) + step(0.95, fu));          // 戸境の仕切り
                float win = saturate(step(0.1, fu) * step(fu, 0.62) + step(0.7, fu) * step(fu, 0.9)); // 大きな窓＋小さな窓
                win *= (1.0 - partition) * step(fv, 0.94);

                float3 panel = concrete * 0.9 + room * 0.12;   // すりガラスの手すり（部屋の明かりがうっすら透ける）
                float3 sharpB;
                if (fv < 0.08) sharpB = concrete;
                else if (fv < 0.40) sharpB = lerp(panel, wall * 0.5, partition);
                else sharpB = lerp(wall * 0.45, room, win);

                float3 avgRoom = lerp(_WindowGlassColor.rgb, _WindowColorWarm.rgb * 0.78 * _WindowBrightness, _WindowLitRatio);
                float3 avgB = concrete * 0.08 + (concrete * 0.9 + avgRoom * 0.12) * 0.32 + (wall * 0.45 * 0.35 + avgRoom * 0.65) * 0.54;
                return lerp(sharpB, avgB, aa);
            }

            float3 ShadeBuilding(float3 p, float3 n, float t, int btype, float2 bid, float3 bmin, float3 bmax, float3 rd, float pixAng, float3 md)
            {
                float3 hb = Hash32(bid + SeedOffset() + 51.1);
                float typeLight = btype == LOT_MANSION ? 1.35 : (btype == LOT_HOUSE ? 1.25 : (btype == LOT_LOW ? 1.1 : 0.9));
                float3 baseCol = _BuildingColor.rgb * typeLight * max(0.0, 1.0 + (hb.x - 0.5) * 2.0 * _BuildingColorVariation);
                float3 wall = baseCol * (SkyLight(n, md, 4.0) + CityBounce() * 0.5);
                if (n.y > 0.5) return lerp(wall * 0.8, _SnowGroundColor.rgb * (SkyLight(n, md, 4.0) + CityBounce()), _SnowCover); // 屋上（雪が積もる）

                if (btype == LOT_MANSION) return MansionFacade(p, n, t, bid, bmin, bmax, wall, rd, pixAng);

                // それ以外（高層ビル・低い建物・戸建て）の窓の並び
                float spacing = btype == LOT_TOWER ? 1.6 : 3.0;
                float2 winX = btype == LOT_TOWER ? float2(0.08, 0.92) : float2(0.18, 0.82);
                float2 winY = btype == LOT_TOWER ? float2(0.15, 0.9) : float2(0.32, 0.86);
                float litMul = btype == LOT_HOUSE ? 0.7 : 1.0;

                float u = (abs(n.x) > 0.5) ? p.z : p.x;
                float2 w = float2(u / spacing, p.y / _FloorHeight);
                float2 id = floor(w);
                float2 f = frac(w);
                float inWin = step(winX.x, f.x) * step(f.x, winX.y) * step(winY.x, f.y) * step(f.y, winY.y);

                float litRatio = saturate(_WindowLitRatio * litMul);
                float lit = step(Hash12(id + bid * 13.1 + n.xz * 7.3), litRatio);
                float tone = step(Hash12(id * 1.7 + bid), _WindowCoolRatio);
                float3 wc = lerp(_WindowColorWarm.rgb, _WindowColorCool.rgb, tone);
                wc *= 1.0 - _WindowBrightnessVariation * Hash12(id * 3.1 + bid * 0.7);

                // 明かりの無い窓はガラスの色（後で「窓の明かりの明るさ」を掛けるので先に割っておく）
                float3 glass = _WindowGlassColor.rgb / max(_WindowBrightness, 0.001);
                float3 sharp = lerp(glass, wc, lit) * inWin;

                // 遠くの窓は平均の明るさに（1ピクセルに窓がいくつも入るとちらつくため）
                float area = (winX.y - winX.x) * (winY.y - winY.x);
                float3 avgLit = lerp(_WindowColorWarm.rgb, _WindowColorCool.rgb, _WindowCoolRatio) * (1.0 - _WindowBrightnessVariation * 0.5);
                float3 avg = lerp(glass, avgLit, litRatio) * area;
                float footprint = t * pixAng / max(abs(dot(rd, n)), 0.15);
                float aa = saturate(footprint / min(spacing, _FloorHeight) * 1.5 - 0.3);

                return wall + lerp(sharp, avg, aa) * _WindowBrightness;
            }

            float3 ShadeTree(float3 n, float3 md)
            {
                float3 albedo = lerp(_TreeColor.rgb, _SnowGroundColor.rgb * 0.8, _SnowCover * 0.6 * saturate(n.y));  // 上の面に雪
                return albedo * (SkyLight(n, md, 3.0) * (0.7 + 0.3 * saturate(n.y)) + CityBounce());
            }

            // ---- 道路 ----

            // 道路のセルの街灯の位置（xz）。1セルに1本、左右交互（交差点には無し）
            float2 LampPosition(float2 cell, int axis)
            {
                float2 c = (cell + 0.5) * _CellSize;
                float along = axis == 0 ? cell.x : cell.y;
                float sideSign = fmod(abs(along), 2.0) < 1.0 ? 1.0 : -1.0;
                float2 perp = axis == 0 ? float2(0.0, 1.0) : float2(1.0, 0.0);
                return c + perp * (sideSign * _CellSize * 0.42);
            }

            // 公園の街灯の位置（xz）。無ければ w = 0
            float3 ParkLampPosition(float2 cell)
            {
                float3 h = Hash32(cell + SeedOffset() + 83.1);
                if (h.x > _ParkLightChance) return 0;
                float2 p = (cell + 0.25 + 0.5 * h.yz) * _CellSize;
                return float3(p.x, p.y, 1.0);
            }

            // 地面のその点に届く街灯の光（周りの 3×3 マスの街灯・公園の街灯を足し合わせる）。
            //   色に掛けて使う（照らす）。遠くは平均の明るさにまとめる
            float3 LampLight(float3 p, float2 cell, float footprint)
            {
                float aa = saturate(footprint / _CellSize * 2.0);
                float sum = 0.0;
                if (aa < 0.999)
                {
                    [unroll]
                    for (int dz = -1; dz <= 1; dz++)
                    {
                        [unroll]
                        for (int dx = -1; dx <= 1; dx++)
                        {
                            float2 nc = cell + float2(dx, dz);
                            CellInfo n = GetCell(nc);
                            float2 lp = 0;
                            float strength = 0.0;
                            if (n.type == CELL_ROAD && n.roadAxis != 2)
                            {
                                lp = LampPosition(nc, n.roadAxis);
                                strength = 1.0;
                            }
                            else if (n.type == CELL_LOT && n.lotType == LOT_PARK)
                            {
                                float3 pl = ParkLampPosition(nc);
                                if (pl.z > 0.5) { lp = pl.xy; strength = 0.6; }
                            }
                            if (strength > 0.0)
                            {
                                float2 d = p.xz - lp;
                                float d2 = dot(d, d);
                                // 真下が一番明るく、なだらかに暗くなる（15m 先でほぼ 0）
                                sum += strength * saturate(1.0 - d2 / (LAMP_REACH * LAMP_REACH)) / (1.0 + d2 / (LAMP_RADIUS * LAMP_RADIUS));
                            }
                        }
                    }
                }
                sum = lerp(sum, LAMP_AVERAGE, aa);
                return _StreetLightColor.rgb * _StreetLightBrightness * sum;
            }

            float3 ShadeGround(float3 p, float2 cell, CellInfo ci, float t, float pixAng, float3 md)
            {
                float3 light = GroundLight(md);
                float3 street = _StreetLightColor.rgb * _StreetLightBrightness;
                float footprint = t * pixAng;

                if (ci.type == CELL_ROAD)
                {
                    float C = _CellSize;
                    float w = C * 0.38;                       // 車道の半分の幅（ここから外が歩道）
                    float2 local = p.xz - (cell + 0.5) * C;

                    // 4方向の隣が道路か（＝その向きに道がつながっている）
                    CellInfo nPX = GetCell(cell + float2(1.0, 0.0));
                    CellInfo nNX = GetCell(cell - float2(1.0, 0.0));
                    CellInfo nPZ = GetCell(cell + float2(0.0, 1.0));
                    CellInfo nNZ = GetCell(cell - float2(0.0, 1.0));
                    bool oPX = nPX.type == CELL_ROAD;
                    bool oNX = nNX.type == CELL_ROAD;
                    bool oPZ = nPZ.type == CELL_ROAD;
                    bool oNZ = nNZ.type == CELL_ROAD;

                    // 歩道: つながっていない側の縁（行き止まりも閉じる）＋四隅（曲がり角の歩道がつながる）
                    float sidewalk = 0.0;
                    if (local.x > w && !oPX) sidewalk = 1.0;
                    if (local.x < -w && !oNX) sidewalk = 1.0;
                    if (local.y > w && !oPZ) sidewalk = 1.0;
                    if (local.y < -w && !oNZ) sidewalk = 1.0;
                    if (abs(local.x) > w && abs(local.y) > w) sidewalk = 1.0;
                    float3 baseCol = lerp(_RoadColor.rgb, _SidewalkColor.rgb, sidewalk);

                    // 路面の表示（交差点のマスには描かない）
                    float lineW = 0.08;
                    float mark = 0.0;
                    if (ci.roadAxis != 2)
                    {
                        bool axisX = ci.roadAxis == 0;
                        float along = axisX ? local.x : local.y;
                        float alongWorld = axisX ? p.x : p.z;
                        float perpSigned = axisX ? local.y : local.x;
                        float perp = abs(perpSigned);
                        bool openSide = perpSigned >= 0.0 ? (axisX ? oPZ : oPX) : (axisX ? oNZ : oNX);

                        // 端の白線（横道が入ってくる所だけ途切れる）
                        float edge = step(abs(perp - C * 0.33), lineW) * ((openSide && abs(along) < w) ? 0.0 : 1.0);

                        // 横断歩道: 進む先が交差点・横の道路なら、その手前に
                        bool endPos = axisX ? (oPX && nPX.roadAxis != 0) : (oPZ && nPZ.roadAxis != 1);
                        bool endNeg = axisX ? (oNX && nNX.roadAxis != 0) : (oNZ && nNZ.roadAxis != 1);
                        float distPos = C * 0.5 - along;
                        float distNeg = C * 0.5 + along;
                        float band = (endPos ? step(1.0, distPos) * step(distPos, 4.0) : 0.0)
                                   + (endNeg ? step(1.0, distNeg) * step(distNeg, 4.0) : 0.0);
                        band = saturate(band);
                        float zebra = band * step(perp, w - 0.3) * step(frac(perp / 0.9 + 0.25), 0.5);

                        // 中央の破線（横断歩道の上には描かない）
                        float center = step(perp, lineW) * step(frac(alongWorld / 6.0), 0.5) * (1.0 - band);
                        mark = saturate(edge + center + zebra);
                    }
                    // 遠くでは細すぎるので消す
                    float markFade = 1.0 - saturate(footprint / (lineW * 2.0) - 0.5);
                    baseCol = lerp(baseCol, _RoadMarkingColor.rgb, mark * markFade * (1.0 - sidewalk));

                    // 雪が積もる（道路は踏まれて少なめ）
                    baseCol = lerp(baseCol, _SnowGroundColor.rgb, _SnowCover * 0.6);
                    // 周りの街灯・街明かりで照らす（色に掛ける）
                    return baseCol * (light + CityBounce() + LampLight(p, cell, footprint) * LAMP_GAIN);
                }

                float3 groundCol = _GroundColor.rgb;
                if (ci.type == CELL_LOT)
                {
                    if (ci.lotType == LOT_PARK) groundCol = _ParkColor.rgb;
                    else if (ci.lotType == LOT_HOUSE) groundCol = lerp(_GroundColor.rgb, _ParkColor.rgb, 0.5);
                }
                groundCol = lerp(groundCol, _SnowGroundColor.rgb, _SnowCover);
                // 周りの街灯（公園の街灯も）・街明かりで照らす（色に掛ける）
                return groundCol * (light + CityBounce() + LampLight(p, cell, footprint) * LAMP_GAIN);
            }

            // 道路の街灯（光の点）
            float3 StreetLamps(float3 ro, float3 rd, float2 cell, int axis, float tLimit, float pixAng)
            {
                if (axis == 2) return 0;
                float2 lp = LampPosition(cell, axis);
                float g = PointGlow(ro, rd, float3(lp.x, 7.0, lp.y), 0.35, tLimit, pixAng);
                return _StreetLightColor.rgb * _StreetLightBrightness * 1.5 * g;
            }

            // 公園の街灯（光の点・低め）
            float3 ParkLamp(float3 ro, float3 rd, float2 cell, float tLimit, float pixAng)
            {
                float3 lamp = ParkLampPosition(cell);
                if (lamp.z < 0.5) return 0;
                float g = PointGlow(ro, rd, float3(lamp.x, 3.5, lamp.y), 0.25, tLimit, pixAng);
                return _StreetLightColor.rgb * _StreetLightBrightness * 1.2 * g;
            }

            // 走る車のライト。片方の車線は向かってくる白いヘッドライト、もう片方は赤いテールランプ
            float3 CarLights(float3 ro, float3 rd, float2 cell, int axis, float tLimit, float pixAng)
            {
                if (axis == 2 || _CarDensity <= 0.0 || _CarLightBrightness <= 0.0) return 0;
                float C = _CellSize;
                float2 center = (cell + 0.5) * C;
                float alongStart = axis == 0 ? cell.x * C : cell.y * C;
                float roadLine = axis == 0 ? center.y : center.x;   // 道路ごとに違う値（同じ道路の上では一定）
                float spacing = 28.0;
                float3 sum = 0;

                [unroll]
                for (int lane = 0; lane < 2; lane++)
                {
                    float dir = lane == 0 ? 1.0 : -1.0;
                    float laneOffset = dir * C * 0.16;
                    float shift = _Time.y * _CarSpeed * dir;
                    float slot = floor((alongStart + C * 0.5 - shift) / spacing);
                    float2 hs = float2(slot, roadLine * 0.37 + lane * 13.7) + SeedOffset();
                    if (Hash12(hs) >= _CarDensity) continue;

                    float carAlong = (slot + 0.25 + 0.5 * Hash12(hs + 3.3)) * spacing + shift;
                    if (carAlong < alongStart || carAlong >= alongStart + C) continue;

                    float2 pos = axis == 0 ? float2(carAlong, roadLine + laneOffset) : float2(roadLine + laneOffset, carAlong);
                    float g = PointGlow(ro, rd, float3(pos.x, 0.8, pos.y), 0.3, tLimit, pixAng);
                    sum += (lane == 0 ? _HeadlightColor.rgb : _TaillightColor.rgb) * g;
                }
                return sum * _CarLightBrightness;
            }

            // 屋上の航空障害灯（点滅）
            float3 RoofLight(float3 ro, float3 rd, float3 bmin, float3 bmax, float2 seed, float pixAng)
            {
                if (bmax.y < _RoofLightMinHeight) return 0;
                float3 q = float3((bmin.x + bmax.x) * 0.5, bmax.y + 1.0, (bmin.z + bmax.z) * 0.5);
                float s = dot(q - ro, rd);
                if (s <= 0.0) return 0;
                float ang = length(ro + rd * s - q) / s;
                float radius = max(2.0 / s, pixAng * 1.5);
                float phase = Hash12(seed + 5.3) * 6.2831;
                float blink = pow(saturate(sin(_Time.y * 2.2 + phase)), 6.0);
                return _RoofLightColor.rgb * _RoofLightBrightness * blink * exp(-(ang * ang) / (radius * radius));
            }

            // ------------------------------------------------------------
            // 街並みをたどる
            // ------------------------------------------------------------

            // 大きな升目（街区の大きさ）単位で、大きな建物だけを調べる。
            //   遠く（細かく描く距離より先）と、上向きの視線（高層ビルだけ）に使う。
            //   近くと同じ街区・敷地の決め方なので、建物の位置は食い違わない。
            //   升目の行＝街区の行。行はずれているので、1つの升目に重なる2つの街区を調べる
            bool CoarseTrace(float3 ro, float3 rd, float tStart, float tEnd, bool towersOnly, float tGround,
                             float pixAng, float3 md, inout float3 glow, out float3 outCol)
            {
                outCol = 0;
                float N = SuperblockCells();
                float CF = _CellSize * N;
                float2 dxz = rd.xz;
                float2 stepDir = float2(dxz.x >= 0.0 ? 1.0 : -1.0, dxz.y >= 0.0 ? 1.0 : -1.0);
                float2 invAbs = 1.0 / max(abs(dxz), EPS);
                float t = tStart;
                float3 p = ro + rd * t;
                float2 fcell = floor(p.xz / CF);
                float2 fDelta = CF * invAbs;
                float2 fMax = t + ((fcell + max(stepDir, 0.0)) * CF - p.xz) * stepDir * invAbs;

                [loop]
                for (int j = 0; j < MAX_FAR_STEPS_LIMIT; j++)
                {
                    if (j >= (int)_MaxFarSteps || t > tEnd) break;
                    float tExit = min(fMax.x, fMax.y);

                    float bestT = 1e9;
                    float3 bestN = 0;
                    int bestKind = HIT_NONE;
                    int bestType = LOT_LOW;
                    float2 bestId = 0;
                    float3 bestMin = 0;
                    float3 bestMax = 0;

                    float sx0 = floor((fcell.x * N - RowOffset(fcell.y)) / N);
                    [loop]
                    for (int k = 0; k < 2; k++)
                    {
                        float2 sb = float2(sx0 + k, fcell.y);
                        [loop]
                        for (int region = 0; region < 3; region++)
                        {
                            CellInfo ci;
                            if (!SuperblockLot(sb, region, ci)) continue;
                            bool big = ci.lotType == LOT_TOWER
                                    || (!towersOnly && (ci.lotType == LOT_MANSION || ci.lotType == LOT_LOW));
                            if (!big) continue;

                            float3 a0, b0, a1, b1;
                            int count = LotBoxes(ci, a0, b0, a1, b1);
                            TryBox(ro, rd, a0, b0, ci.lotType, ci.lotId, bestT, bestN, bestKind, bestType, bestId, bestMin, bestMax);
                            if (count > 1) TryBox(ro, rd, a1, b1, ci.lotType, ci.lotId + 0.5, bestT, bestN, bestKind, bestType, bestId, bestMin, bestMax);

                            // 航空障害灯は、敷地の中心がこの升目にあるときだけ足す（二重に足さない）
                            float2 lc = (ci.lot.xy + ci.lot.zw + 1.0) * 0.5 * _CellSize;
                            if (all(abs(floor(lc / CF) - fcell) < 0.5)) glow += RoofLight(ro, rd, a0, b0, ci.lotId, pixAng);
                        }
                    }

                    if (bestKind != HIT_NONE && bestT <= tExit + 0.01 && bestT < tGround)
                    {
                        float3 hp = ro + rd * bestT;
                        outCol = lerp(ShadeBuilding(hp, bestN, bestT, bestType, bestId, bestMin, bestMax, rd, pixAng, md), HazeColor(), Fog(bestT)); g_hitT = bestT;
                        return true;
                    }
                    if (!towersOnly && tGround <= tExit)
                    {
                        // 遠くの地面: 地面・道路・街灯・車の平均の明るさ
                        float3 avgAlbedo = lerp(lerp(_GroundColor.rgb, _RoadColor.rgb, 0.3), _SnowGroundColor.rgb, _SnowCover * 0.8);
                        float3 avgGround = avgAlbedo * (GroundLight(md) + CityBounce() + _StreetLightColor.rgb * _StreetLightBrightness * LAMP_AVERAGE * LAMP_GAIN)
                                         + _HeadlightColor.rgb * _CarLightBrightness * _CarDensity * 0.01;
                        outCol = lerp(avgGround, HazeColor(), Fog(tGround)); g_hitT = tGround;
                        return true;
                    }

                    t = tExit;
                    if (fMax.x < fMax.y) { fMax.x += fDelta.x; fcell.x += stepDir.x; }
                    else { fMax.y += fDelta.y; fcell.y += stepDir.y; }
                }
                return false;
            }

            // 何にも当たらなければ false（空）。glow は手前の灯り（街灯・航空障害灯）
            bool TraceCity(float3 rd, float pixAng, float3 md, out float3 outCol, out float3 glow)
            {
                outCol = 0;
                glow = 0;
                float3 ro = float3(0, _ViewHeight, 0);
                float tGround = rd.y < 0.0 ? ro.y / -rd.y : 1e9;
                float lenXZ = max(length(rd.xz), 1e-4);
                float mansionMax = max(_MansionFloorsMin, _MansionFloorsMax) * _FloorHeight;
                float maxHeight = max(_TowerHeightMax, mansionMax) + 10.0;
                // 高層ビル以外（マンション・低い建物・戸建て・木）の一番高い所
                float smallMax = max(max(mansionMax, 12.0), 2.0 + _TreeSize * 2.4) + 1.0;

                // 上向きで、建物の一番高い所より上を通る視線は街並み無し
                if (rd.y >= 0.0 && ro.y >= maxHeight) return false;

                float tDetail = _DetailDistance / lenXZ;
                float tFar = _CityFar / lenXZ;
                float tTop = rd.y > 0.0 ? (maxHeight - ro.y) / rd.y : 1e9;   // 上向きの視線が建物より高くなる所
                float tEnd = min(tFar, tTop);

                // 上向きで、視点が高層ビル以外より高い → 当たるのは高層ビルだけ。街区単位で軽く調べる
                if (rd.y > 0.0 && ro.y > smallMax)
                {
                    return CoarseTrace(ro, rd, 0.0, tEnd, true, tGround, pixAng, md, glow, outCol);
                }

                // ---- 近く: セル単位で細かく ----
                float C = _CellSize;
                float2 dxz = rd.xz;
                float2 stepDir = float2(dxz.x >= 0.0 ? 1.0 : -1.0, dxz.y >= 0.0 ? 1.0 : -1.0);
                float2 invAbs = 1.0 / max(abs(dxz), EPS);
                float2 cell = floor(ro.xz / C);
                float2 tDelta = C * invAbs;
                float2 tMax = ((cell + max(stepDir, 0.0)) * C - ro.xz) * stepDir * invAbs;
                float t = 0.0;

                [loop]
                for (int i = 0; i < MAX_STEPS_LIMIT; i++)
                {
                    if (i >= (int)_MaxSteps || t > tDetail || t > tEnd) break;

                    float tExit = min(tMax.x, tMax.y);
                    CellInfo ci = GetCell(cell);

                    float bestT = 1e9;
                    float3 bestN = 0;
                    int bestKind = HIT_NONE;
                    int bestType = LOT_LOW;
                    float2 bestId = 0;
                    float3 bestMin = 0;
                    float3 bestMax = 0;

                    if (ci.type == CELL_ROAD)
                    {
                        glow += StreetLamps(ro, rd, cell, ci.roadAxis, tGround, pixAng) + CarLights(ro, rd, cell, ci.roadAxis, tGround, pixAng);
                    }
                    else if (ci.type == CELL_LOT)
                    {
                        if (ci.lotType == LOT_HOUSE)
                        {
                            float3 hmin, hmax;
                            bool hasHouse = HouseBox(cell, hmin, hmax);
                            if (hasHouse) TryBox(ro, rd, hmin, hmax, LOT_HOUSE, cell, bestT, bestN, bestKind, bestType, bestId, bestMin, bestMax);
                            if (Hash12(cell + SeedOffset() + 71.7) < 0.35)
                            {
                                // 庭木（家がある時は、家と重ならない側に）
                                float4 tree = hasHouse ? GardenTree(cell, hmin, hmax) : TreeSphere(cell, 0.0);
                                if (tree.w > 0.0) TrySphere(ro, rd, tree, bestT, bestN, bestKind);
                            }
                        }
                        else if (ci.lotType == LOT_PARK)
                        {
                            TrySphere(ro, rd, TreeSphere(cell, 0.0), bestT, bestN, bestKind);
                            if (Hash12(cell + SeedOffset() + 72.3) < 0.6) TrySphere(ro, rd, TreeSphere(cell, 1.0), bestT, bestN, bestKind);
                            glow += ParkLamp(ro, rd, cell, tGround, pixAng);
                        }
                        else
                        {
                            float3 a0, b0, a1, b1;
                            int count = LotBoxes(ci, a0, b0, a1, b1);
                            TryBox(ro, rd, a0, b0, ci.lotType, ci.lotId, bestT, bestN, bestKind, bestType, bestId, bestMin, bestMax);
                            if (count > 1) TryBox(ro, rd, a1, b1, ci.lotType, ci.lotId + 0.5, bestT, bestN, bestKind, bestType, bestId, bestMin, bestMax);
                            // 航空障害灯は敷地の左下のセルを通るときだけ足す（同じ灯りを何度も足さない）
                            if (all(abs(cell - ci.lot.xy) < 0.5)) glow += RoofLight(ro, rd, a0, b0, ci.lotId, pixAng);
                        }
                    }

                    // 当たりはこのセルを出る前のものだけ（敷地の建物は次のセルでも調べ直す）
                    if (bestKind != HIT_NONE && bestT <= tExit + 0.01 && bestT < tGround)
                    {
                        float3 hp = ro + rd * bestT;
                        float3 col = bestKind == HIT_TREE ? ShadeTree(bestN, md)
                                                          : ShadeBuilding(hp, bestN, bestT, bestType, bestId, bestMin, bestMax, rd, pixAng, md);
                        outCol = lerp(col, HazeColor(), Fog(bestT)); g_hitT = bestT;
                        return true;
                    }
                    if (tGround <= tExit)
                    {
                        float3 gp = ro + rd * tGround;
                        outCol = lerp(ShadeGround(gp, cell, ci, tGround, pixAng, md), HazeColor(), Fog(tGround)); g_hitT = tGround;
                        return true;
                    }

                    t = tExit;
                    if (tMax.x < tMax.y) { tMax.x += tDelta.x; cell.x += stepDir.x; }
                    else { tMax.y += tDelta.y; cell.y += stepDir.y; }
                }

                // ---- 遠く: 大きな街区単位で、大きな建物だけ ----
                if (CoarseTrace(ro, rd, t, tEnd, false, tGround, pixAng, md, glow, outCol)) return true;

                // 下向きで何にも当たらなかった（歩数切れ・街の外）＝遠くの地面はかすみの中
                if (rd.y < 0.0)
                {
                    outCol = HazeColor();
                    return true;
                }
                return false;
            }

            // ------------------------------------------------------------

            // ------------------------------------------------------------
            // 雨・雪
            //   視点の周りの見えない円筒（半径 6m・13m・29m・64m）の上に、落ちてくる雨筋・雪の粒を描く。
            //   建物や地面より奥の円筒には描かない（g_hitT）。真上・真下は円筒が歪むので薄くする
            // ------------------------------------------------------------

            float3 Precipitation(float3 rd, float pixAng)
            {
                float rain = _RainAmount;
                float snow = _SnowAmount;
                if (rain <= 0.0 && snow <= 0.0) return 0;

                float3 ro = float3(0.0, _ViewHeight, 0.0);
                float lenXZ = length(rd.xz);
                if (lenXZ < 0.02) return 0;
                float verticalFade = saturate(lenXZ * 3.0);
                float time = _Time.y;
                float3 sum = 0;

                [unroll]
                for (int k = 0; k < PRECIP_LAYERS; k++)
                {
                    float r = PRECIP_NEAR * pow(PRECIP_STEP, k);
                    float t = r / lenXZ;
                    if (t > g_hitT) break;                 // 建物・地面の向こうには降らせない

                    float3 p = ro + rd * t;
                    float u = atan2(p.x, p.z) * r;         // 円筒の周りの位置（m）
                    float v = p.y;
                    float layerFade = 1.0 - (float)k / PRECIP_LAYERS * 0.6;
                    float px = max(pixAng * t, 0.003);     // 1ピクセルの大きさ（m）

                    if (rain > 0.0)
                    {
                        // 雨筋（風で斜め）。1マスに1粒
                        float2 cellSize = float2(0.5, 3.0);
                        float2 g = float2(u + v * _PrecipWind, v + time * _RainSpeed) / cellSize;
                        float2 id = floor(g) + k * 37.0;
                        float2 f = frac(g);
                        if (Hash12(id) < rain)
                        {
                            float dx = (f.x - Hash12(id + 7.7)) * cellSize.x;
                            float dy = (f.y - Hash12(id + 3.1)) * cellSize.y;
                            float w = max(0.006, px * 0.6);
                            float streak = exp(-dx * dx / (w * w)) * saturate(1.0 - abs(dy) / 0.6) * saturate(0.006 / w + 0.2);
                            sum += _RainColor.rgb * streak * layerFade;
                        }
                    }

                    if (snow > 0.0)
                    {
                        // 雪の粒（ゆらゆら揺れながらゆっくり落ちる）
                        float2 cellSize = float2(1.0, 1.0);
                        float sway = sin(time * 0.7 + v * 0.3) * 0.3 + v * _PrecipWind * 0.3;
                        float2 g = float2(u + sway, v + time * _SnowSpeed) / cellSize;
                        float2 id = floor(g) + k * 53.0;
                        float2 f = frac(g);
                        float h = Hash12(id);
                        if (h < snow)
                        {
                            float2 c = float2(Hash12(id + 1.3), Hash12(id + 2.9)) * 0.7 + 0.15;
                            c += 0.12 * float2(sin(time * 1.3 + h * 20.0), cos(time * 1.1 + h * 17.0));
                            float2 d = (f - c) * cellSize;
                            float size = 0.035 * (0.6 + Hash12(id + 5.5));
                            float w = max(size, px);
                            float flake = exp(-dot(d, d) / (w * w)) * saturate(size / w + 0.15);
                            sum += _SnowColor.rgb * flake * layerFade;
                        }
                    }
                }
                return sum * verticalFade;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 d = normalize(i.dir);
                // 1ピクセルあたりの角度（遠くの細かい模様をまとめるのに使う）
                float pixAng = max(length(fwidth(d)), 1e-5);
                float3 md = MoonDirection();

                float3 col;
                float3 cityCol, glow;
                g_hitT = 1e9;
                if (TraceCity(d, pixAng, md, cityCol, glow))
                {
                    col = cityCol;
                }
                else
                {
                    col = SkyColor(d);
                    if (d.y > 0.0)
                    {
                        float horizonFade = saturate(d.y * 6.0);
                        float4 moon = MoonDisk(d, md, pixAng);
                        float moonGlowNear = exp(-acos(clamp(dot(d, md), -1.0, 1.0)) * 30.0);
                        col += Stars(d, pixAng) * horizonFade * (1.0 - moon.a) * (1.0 - moonGlowNear);
                        col += MoonGlow(d, md);
                        col = lerp(col, moon.rgb, moon.a);

                        float4 cloud = Clouds(d, md);
                        col = lerp(col, cloud.rgb, cloud.a);

                        // 魔女の影絵（雲・月の手前）
                        col = lerp(col, _WitchColor.rgb, WitchMask(d, pixAng));

                        // 空の乗り物（雲の手前を飛ぶ。厚い雲ではうっすら隠れる）
                        col += (Airliners(d, pixAng) + Dogfight(d, pixAng) + Santa(d, pixAng) + WitchLights(d, pixAng)) * (1.0 - cloud.a * 0.6);
                    }
                }
                col += glow;
                col += Precipitation(d, pixAng);   // 雨・雪（建物の手前だけ）

                return fixed4(col * _Exposure, 1.0);
            }
            ENDCG
        }
    }

    Fallback Off
}
