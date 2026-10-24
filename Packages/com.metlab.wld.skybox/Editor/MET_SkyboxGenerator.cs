// ============================================================
// MET_SkyboxGenerator
// 概要: 街のスカイボックス（Metlab/Skybox/City）のマテリアルを、
//       時間帯・街の明るさ・視点の高さ・街並みなどの設定から生成するエディタ拡張。
//       メニュー「Tools > Metlab > スカイボックスをつくるやつ」で開く。
//
//       使い方:
//         1. 時間帯（夜・夕暮れ・昼・明け方）を選ぶ → 空・月/太陽・雲・建物・地面の色がそろう
//         2. 街の明るさ・視点の高さ・街並み（建物の割合・道路・木）・空などを調整
//         3. 「新しく生成」で Assets/MetlabGenerated/スカイボックスをつくるやつ/ にマテリアルを作る
//            「上書き」なら、指定したマテリアルに設定を書き込む（シーンに使っていればすぐ反映）
//       シーンへの適用は自動では行わない（Lighting ウィンドウの Skybox Material に自分で設定）。
//       生成したマテリアルは、インスペクタで1つずつ細かく調整してもよい。
//
//       バリエーション（同じ街の昼版など）:
//         「元にするマテリアル」に作ったマテリアルを入れて「設定を読み込む」→ 時間帯や天気を変えて
//         「新しく生成」。「細かい調整を引き継ぐ」がオンなら、インスペクタで変えた値も引き継ぐ。
//
// バージョン: 2.5.0
//   a: 大きな変更（破壊的変更・仕様変更）
//   b: 機能追加・変更
//   c: 些細な修正・調整
// [変更履歴]
//   2.5.0 - 「空の乗り物」にハロウィン用の魔女（ほうきに乗った影絵・月の前を横切る）を追加（シェーダー 3.5.0）
//   2.4.0 - 天気（晴れ・雨・雪と強さ）を追加（シェーダー 3.4.0）。
//           作ったマテリアルから設定を読み込んで、バリエーション（昼版など）を作れるように
//   2.3.0 - 「空の乗り物」にサンタを追加（シェーダー 3.3.0）
//   2.2.0 - シェーダー 3.2.0 に合わせて「空の乗り物」（旅客機の数・戦闘機の空中戦）を追加。
//           時間帯ごとに飛行機雲・機体の色・灯りの明るさを設定。夜・夕暮れ・明け方の地面・道路・木を明るく
//   2.1.0 - シェーダー 3.1.0 に合わせて、車の多さ・公園の街灯の多さを追加。
//           時間帯ごとに歩道・白線・共用廊下の明かり・車のライトの明るさを設定。
//           窓の明かりの色（ふつう／白っぽい）を、青くならない暖かい色に固定
//   2.0.0 - シェーダー 3.0.0（道路網・マンション・戸建て・公園・木）に合わせて設定を作り直し。
//           建物の割合・マンションの階数・高層ビルの高さ・道路・木・かすみの色を追加
// ============================================================

using UnityEditor;
using UnityEngine;

namespace Metlab.Skybox
{
    public class MET_SkyboxGenerator : EditorWindow
    {
        private const string MENU_PATH = "Tools/Metlab/スカイボックスをつくるやつ";
        private const string GENERATED_FOLDER = "Assets/MetlabGenerated/スカイボックスをつくるやつ";
        private const string CITY_SHADER = "Metlab/Skybox/City";
        private const string DEFAULT_NAME = "街の空";

        private static readonly string[] TIME_LABELS = { "夜", "夕暮れ", "昼", "明け方" };
        private const int TIME_NIGHT = 0;
        private const int TIME_DUSK = 1;
        private const int TIME_DAY = 2;
        private const int TIME_DAWN = 3;

        private static readonly string[] WEATHER_LABELS = { "晴れ", "雨", "雪" };
        private const int WEATHER_CLEAR = 0;
        private const int WEATHER_RAIN = 1;
        private const int WEATHER_SNOW = 2;

        // 「街の明るさ」0〜1 を、時間帯の基本値に掛ける倍率（0.5 で基本値のまま）
        private const float CITY_LIGHT_MUL_MIN = 0.2f;
        private const float CITY_LIGHT_MUL_MAX = 1.8f;

        // ---- 設定（ウィンドウを閉じるまで保持） ----
        [SerializeField] private string assetName = DEFAULT_NAME;
        [SerializeField] private Material sourceMaterial;
        [SerializeField] private bool inheritTweaks = true;
        [SerializeField] private int weather = WEATHER_CLEAR;
        [SerializeField] private float precipAmount = 0.5f;
        [SerializeField] private int timeOfDay = TIME_NIGHT;
        [SerializeField] private float cityBrightness = 0.5f;
        [SerializeField] private float windowCoolRatio = 0.12f;

        [SerializeField] private float viewHeight = 60f;
        [SerializeField] private float cityNear = 30f;
        [SerializeField] private float detailDistance = 900f;
        [SerializeField] private float cityFar = 4000f;

        [SerializeField] private float mansionRatio = 0.45f;
        [SerializeField] private float towerRatio = 0.06f;
        [SerializeField] private float houseRatio = 0.25f;
        [SerializeField] private float parkRatio = 0.1f;
        [SerializeField] private int mansionFloorsMin = 4;
        [SerializeField] private int mansionFloorsMax = 14;
        [SerializeField] private float towerHeightMin = 70f;
        [SerializeField] private float towerHeightMax = 200f;

        [SerializeField] private float cellSize = 12f;
        [SerializeField] private int superblockCells = 7;
        [SerializeField] private float sideRoadChance = 0.75f;
        [SerializeField] private float innerRoadChance = 0.6f;
        [SerializeField] private float treeSize = 3.2f;
        [SerializeField] private float parkLightChance = 0.35f;
        [SerializeField] private float carDensity = 0.35f;

        [SerializeField] private int airlinerCount = 1;
        [SerializeField] private bool dogfight = false;
        [SerializeField] private float dogfightAzimuth = 60f;
        [SerializeField] private float dogfightBrightness = 0.5f;
        [SerializeField] private bool santa = false;
        [SerializeField] private bool witch = false;
        [SerializeField] private int citySeed = 0;

        [SerializeField] private float cloudCoverage = 0.45f;
        [SerializeField] private float cloudSpeed = 0.02f;
        [SerializeField] private float starAmount = 0.2f;
        [SerializeField] private bool useTimeDefaultsForBody = true;
        [SerializeField] private float bodyAzimuth = 140f;
        [SerializeField] private float bodyAltitude = 28f;
        [SerializeField] private float moonPhase = 0.25f;

        [SerializeField] private int maxSteps = 110;
        [SerializeField] private int maxFarSteps = 48;
        [SerializeField] private Material overwriteTarget;

        private Vector2 scroll;

        [MenuItem(MENU_PATH)]
        private static void Open()
        {
            var w = GetWindow<MET_SkyboxGenerator>("スカイボックスをつくるやつ");
            w.minSize = new Vector2(380f, 520f);
        }

        // ------------------------------------------------------------
        // 画面
        // ------------------------------------------------------------

        private void OnGUI()
        {
            scroll = EditorGUILayout.BeginScrollView(scroll);

            EditorGUILayout.HelpBox("設定を選んで「新しく生成」を押すと、街のスカイボックスのマテリアルができます。シーンには自動で適用しません（Lighting ウィンドウの Skybox Material に設定してください）。", MessageType.Info);

            // ---- 元にするマテリアル（バリエーション作り） ----
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("元にするマテリアル（同じ街の昼版などを作る時）", EditorStyles.boldLabel);
            sourceMaterial = (Material)EditorGUILayout.ObjectField(new GUIContent("元にするマテリアル", "前に作ったスカイボックス。読み込むと街の配置などがこのウィンドウに入る"), sourceMaterial, typeof(Material), false);
            using (new EditorGUI.DisabledScope(sourceMaterial == null))
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    if (GUILayout.Button("設定を読み込む")) LoadFromMaterial(sourceMaterial);
                    inheritTweaks = EditorGUILayout.ToggleLeft(new GUIContent("細かい調整を引き継ぐ", "オンなら、インスペクタで変えた値（このウィンドウに無い項目）も新しいマテリアルに引き継ぐ"), inheritTweaks);
                }
            }

            // ---- 時間帯 ----
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("時間帯", EditorStyles.boldLabel);
            int newTime = GUILayout.Toolbar(timeOfDay, TIME_LABELS);
            if (newTime != timeOfDay)
            {
                timeOfDay = newTime;
                ApplyTimeDefaults();
            }
            cityBrightness = EditorGUILayout.Slider(new GUIContent("街の明るさ", "窓の明かり・街灯・地平線の照り返しの強さ。0.5 が時間帯の標準"), cityBrightness, 0f, 1f);
            windowCoolRatio = EditorGUILayout.Slider(new GUIContent("白っぽい窓の明かりの割合", "残りはふつう（暖色）の明かり。0 にすると全部同じ色"), windowCoolRatio, 0f, 1f);

            // ---- 天気 ----
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("天気", EditorStyles.boldLabel);
            weather = GUILayout.Toolbar(weather, WEATHER_LABELS);
            using (new EditorGUI.DisabledScope(weather == WEATHER_CLEAR))
            {
                precipAmount = EditorGUILayout.Slider(new GUIContent("雨・雪の強さ", "雨・雪の量。雲・かすみも合わせて濃くなる。雪は屋根や地面に積もる"), precipAmount, 0f, 1f);
            }

            // ---- 視点 ----
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("視点", EditorStyles.boldLabel);
            viewHeight = EditorGUILayout.Slider(new GUIContent("視点の高さ（m）", "低いと建物を見上げ、高いと街を見下ろす"), viewHeight, 1.5f, 400f);
            using (new EditorGUILayout.HorizontalScope())
            {
                if (GUILayout.Button("地上（2m）")) SetView(2f, 15f);
                if (GUILayout.Button("中くらい（60m）")) SetView(60f, 30f);
                if (GUILayout.Button("高層（200m）")) SetView(200f, 60f);
            }
            cityNear = EditorGUILayout.FloatField(new GUIContent("建物が始まる距離（m）", "これより近くには建物を置かない（ワールドの建物と重ならないように）"), cityNear);
            detailDistance = EditorGUILayout.FloatField(new GUIContent("細かく描く距離（m）", "これより遠くは大きな建物だけを描く（軽くなる）"), detailDistance);
            cityFar = EditorGUILayout.FloatField(new GUIContent("街が終わる距離（m）"), cityFar);

            // ---- 街並み ----
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("街並み（敷地ごとの割合・合計 1 を超える分は無視、残りは低い建物）", EditorStyles.boldLabel);
            mansionRatio = EditorGUILayout.Slider("マンション", mansionRatio, 0f, 1f);
            towerRatio = EditorGUILayout.Slider("高層ビル", towerRatio, 0f, 1f);
            houseRatio = EditorGUILayout.Slider("戸建て", houseRatio, 0f, 1f);
            parkRatio = EditorGUILayout.Slider("公園", parkRatio, 0f, 1f);
            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.LabelField("マンションの階数", GUILayout.Width(EditorGUIUtility.labelWidth - 4f));
                mansionFloorsMin = EditorGUILayout.IntField(mansionFloorsMin);
                EditorGUILayout.LabelField("〜", GUILayout.Width(16f));
                mansionFloorsMax = EditorGUILayout.IntField(mansionFloorsMax);
            }
            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.LabelField("高層ビルの高さ（m）", GUILayout.Width(EditorGUIUtility.labelWidth - 4f));
                towerHeightMin = EditorGUILayout.FloatField(towerHeightMin);
                EditorGUILayout.LabelField("〜", GUILayout.Width(16f));
                towerHeightMax = EditorGUILayout.FloatField(towerHeightMax);
            }

            // ---- 道路と木 ----
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("道路と木", EditorStyles.boldLabel);
            cellSize = EditorGUILayout.Slider(new GUIContent("道路の幅（m）", "区画の最小単位でもある。小さいほど街が細かくなり、少し重くなる"), cellSize, 6f, 30f);
            superblockCells = EditorGUILayout.IntSlider(new GUIContent("大きな街区の大きさ", "大通りで囲まれた街区の大きさ（道路の幅の何個分か）"), superblockCells, 4, 12);
            sideRoadChance = EditorGUILayout.Slider(new GUIContent("縦の道の多さ", "街区の境の縦の道。少ないと街区がつながって大きくなる"), sideRoadChance, 0f, 1f);
            innerRoadChance = EditorGUILayout.Slider(new GUIContent("街区の中の道の多さ", "街区の中を通る道（T字路）"), innerRoadChance, 0f, 1f);
            treeSize = EditorGUILayout.Slider("木の大きさ（m）", treeSize, 1f, 6f);
            parkLightChance = EditorGUILayout.Slider("公園の街灯の多さ", parkLightChance, 0f, 1f);
            carDensity = EditorGUILayout.Slider(new GUIContent("車の多さ", "道路を走る車のライト（夜・夕暮れ・明け方）"), carDensity, 0f, 1f);
            using (new EditorGUILayout.HorizontalScope())
            {
                citySeed = EditorGUILayout.IntField(new GUIContent("街の配置の種", "変えると道路や建物の並びが変わる"), citySeed);
                if (GUILayout.Button("ランダム", GUILayout.Width(70f))) citySeed = Random.Range(0, 10000);
            }

            // ---- 空 ----
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("空", EditorStyles.boldLabel);
            cloudCoverage = EditorGUILayout.Slider("雲の量", cloudCoverage, 0f, 1f);
            cloudSpeed = EditorGUILayout.Slider("雲の速さ", cloudSpeed, 0f, 0.2f);
            starAmount = EditorGUILayout.Slider("星の数", starAmount, 0f, 1f);
            useTimeDefaultsForBody = EditorGUILayout.Toggle(new GUIContent("月・太陽の位置は時間帯の標準", "オフにすると下の方角・高さを使う"), useTimeDefaultsForBody);
            using (new EditorGUI.DisabledScope(useTimeDefaultsForBody))
            {
                bodyAzimuth = EditorGUILayout.Slider("月・太陽の方角（度）", bodyAzimuth, 0f, 360f);
                bodyAltitude = EditorGUILayout.Slider("月・太陽の高さ（度）", bodyAltitude, -10f, 90f);
            }
            using (new EditorGUI.DisabledScope(timeOfDay != TIME_NIGHT))
            {
                moonPhase = EditorGUILayout.Slider(new GUIContent("月の欠け具合", "0 = 満月 / 1 = 新月（夜のみ）"), moonPhase, 0f, 1f);
            }

            // ---- 空の乗り物 ----
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("空の乗り物", EditorStyles.boldLabel);
            airlinerCount = EditorGUILayout.IntSlider(new GUIContent("旅客機の数", "まっすぐ横切る旅客機。夜は翼端灯・ストロボ、昼は飛行機雲"), airlinerCount, 0, 3);
            dogfight = EditorGUILayout.Toggle(new GUIContent("戦闘機の空中戦", "2機が絡み合いながら光る軌跡を残して飛ぶ。細かい動きはマテリアルの Dogfight の項目で調整"), dogfight);
            using (new EditorGUI.DisabledScope(!dogfight))
            {
                dogfightAzimuth = EditorGUILayout.Slider("空中戦の方角（度）", dogfightAzimuth, 0f, 360f);
                dogfightBrightness = EditorGUILayout.Slider(new GUIContent("空中戦の明るさ", "小さいほどうっすら"), dogfightBrightness, 0f, 3f);
            }
            santa = EditorGUILayout.Toggle(new GUIContent("サンタ", "赤い鼻のトナカイのそりが、街の上をぐるっと回って飛ぶ。細かい設定はマテリアルの Santa の項目"), santa);
            witch = EditorGUILayout.Toggle(new GUIContent("魔女（ハロウィン）", "ほうきに乗った魔女の影絵が街の上を回り、一周に一度、月の前を横切る。ほうきの先にかぼちゃランタン。\n細かい設定はマテリアルの Witch Halloween の項目"), witch);

            // ---- 品質 ----
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("品質", EditorStyles.boldLabel);
            maxSteps = EditorGUILayout.IntSlider(new GUIContent("計算の歩数・近く", "近くの街並みを何区画先まで調べるか。重いときは下げる"), maxSteps, 16, 200);
            maxFarSteps = EditorGUILayout.IntSlider(new GUIContent("計算の歩数・遠く", "遠くの大きな建物を何街区先まで調べるか。重いときは下げる"), maxFarSteps, 0, 96);

            // ---- 生成 ----
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("生成", EditorStyles.boldLabel);
            assetName = EditorGUILayout.TextField("名前", assetName);
            if (GUILayout.Button("新しく生成", GUILayout.Height(28f))) GenerateNew();

            EditorGUILayout.Space();
            overwriteTarget = (Material)EditorGUILayout.ObjectField(new GUIContent("上書きするマテリアル", "前に生成したマテリアルに、今の設定を書き込む"), overwriteTarget, typeof(Material), false);
            using (new EditorGUI.DisabledScope(overwriteTarget == null))
            {
                if (GUILayout.Button("上書き")) Overwrite();
            }

            EditorGUILayout.EndScrollView();
        }

        private void SetView(float height, float near)
        {
            viewHeight = height;
            cityNear = near;
        }

        // 時間帯を変えたとき、その時間帯に合う雲・星の初期値にする
        private void ApplyTimeDefaults()
        {
            starAmount = timeOfDay == TIME_NIGHT ? 0.2f : (timeOfDay == TIME_DAY ? 0f : 0.05f);
            cloudCoverage = timeOfDay == TIME_DAY ? 0.4f : 0.45f;
        }

        // ------------------------------------------------------------
        // 生成
        // ------------------------------------------------------------

        private void GenerateNew()
        {
            Shader shader = Shader.Find(CITY_SHADER);
            if (shader == null)
            {
                EditorUtility.DisplayDialog("スカイボックス生成", $"シェーダー「{CITY_SHADER}」が見つかりません。Console にシェーダーのエラーが出ていないか確認してください。", "OK");
                return;
            }

            string folder = EnsureFolder(GENERATED_FOLDER);
            string fileName = string.IsNullOrWhiteSpace(assetName) ? DEFAULT_NAME : assetName.Trim();
            foreach (char c in System.IO.Path.GetInvalidFileNameChars()) fileName = fileName.Replace(c, '_');
            string path = AssetDatabase.GenerateUniqueAssetPath($"{folder}/{fileName}.mat");

            bool inherit = sourceMaterial != null && inheritTweaks;
            var mat = inherit ? new Material(sourceMaterial) : new Material(shader);
            mat.shader = shader;
            ApplySettings(mat);
            AssetDatabase.CreateAsset(mat, path);
            AssetDatabase.SaveAssets();

            overwriteTarget = mat;
            Selection.activeObject = mat;
            EditorGUIUtility.PingObject(mat);
            Debug.Log($"[MET_SkyboxGenerator] スカイボックス「{path}」を生成しました（シーンには適用していません）。", mat);
        }

        private void Overwrite()
        {
            if (overwriteTarget == null) return;
            Shader shader = Shader.Find(CITY_SHADER);
            if (shader == null)
            {
                EditorUtility.DisplayDialog("スカイボックス生成", $"シェーダー「{CITY_SHADER}」が見つかりません。", "OK");
                return;
            }
            if (overwriteTarget.shader != shader &&
                !EditorUtility.DisplayDialog("スカイボックス生成", $"「{overwriteTarget.name}」は {CITY_SHADER} のマテリアルではありません。シェーダーを差し替えて上書きしますか？", "上書きする", "やめる"))
            {
                return;
            }

            Undo.RecordObject(overwriteTarget, "スカイボックスを上書き");
            overwriteTarget.shader = shader;
            ApplySettings(overwriteTarget);
            EditorUtility.SetDirty(overwriteTarget);
            AssetDatabase.SaveAssets();
            Debug.Log($"[MET_SkyboxGenerator] 「{overwriteTarget.name}」に設定を上書きしました。", overwriteTarget);
        }

        // 時間帯の基本値＋ウィンドウの設定をマテリアルへ
        private void ApplySettings(Material m)
        {
            ApplyTimePreset(m, timeOfDay);

            // 街の明るさ（0.5 で基本値のまま）
            float mul = Mathf.Lerp(CITY_LIGHT_MUL_MIN, CITY_LIGHT_MUL_MAX, cityBrightness);
            m.SetFloat("_WindowLitRatio", Mathf.Clamp01(m.GetFloat("_WindowLitRatio") * mul));
            m.SetFloat("_WindowBrightness", m.GetFloat("_WindowBrightness") * mul);
            m.SetFloat("_StreetLightBrightness", m.GetFloat("_StreetLightBrightness") * mul);
            m.SetFloat("_CloudCityLight", m.GetFloat("_CloudCityLight") * mul);
            m.SetFloat("_CorridorLightBrightness", m.GetFloat("_CorridorLightBrightness") * mul);
            m.SetFloat("_CarLightBrightness", m.GetFloat("_CarLightBrightness") * mul);
            if (timeOfDay != TIME_DAY) m.SetFloat("_CityGlowIntensity", m.GetFloat("_CityGlowIntensity") * mul);
            m.SetFloat("_WindowCoolRatio", windowCoolRatio);

            // 視点
            float near = Mathf.Max(0f, cityNear);
            float cell = Mathf.Max(3f, cellSize);
            m.SetFloat("_ViewHeight", viewHeight);
            m.SetFloat("_CityNear", near);
            m.SetFloat("_DetailDistance", Mathf.Max(near + cell, detailDistance));
            m.SetFloat("_CityFar", Mathf.Max(near + cell * superblockCells, cityFar));

            // 街並み
            m.SetFloat("_MansionRatio", mansionRatio);
            m.SetFloat("_TowerRatio", towerRatio);
            m.SetFloat("_HouseRatio", houseRatio);
            m.SetFloat("_ParkRatio", parkRatio);
            int fMin = Mathf.Max(1, Mathf.Min(mansionFloorsMin, mansionFloorsMax));
            int fMax = Mathf.Max(fMin, Mathf.Max(mansionFloorsMin, mansionFloorsMax));
            m.SetFloat("_MansionFloorsMin", fMin);
            m.SetFloat("_MansionFloorsMax", fMax);
            float tMin = Mathf.Max(10f, Mathf.Min(towerHeightMin, towerHeightMax));
            float tMax = Mathf.Max(tMin, Mathf.Max(towerHeightMin, towerHeightMax));
            m.SetFloat("_TowerHeightMin", tMin);
            m.SetFloat("_TowerHeightMax", tMax);
            m.SetFloat("_RoofLightMinHeight", Mathf.Lerp(tMin, tMax, 0.3f)); // 高めの高層ビルに航空障害灯

            // 道路と木
            m.SetFloat("_CellSize", cell);
            m.SetFloat("_SuperblockCells", superblockCells);
            m.SetFloat("_SideRoadChance", sideRoadChance);
            m.SetFloat("_InnerRoadChance", innerRoadChance);
            m.SetFloat("_TreeSize", treeSize);
            m.SetFloat("_ParkLightChance", parkLightChance);
            m.SetFloat("_CarDensity", carDensity);
            m.SetFloat("_AirlinerCount", airlinerCount);
            m.SetFloat("_DogfightEnabled", dogfight ? 1f : 0f);
            m.SetFloat("_DogfightAzimuth", dogfightAzimuth);
            m.SetFloat("_DogfightBrightness", dogfightBrightness);
            m.SetFloat("_SantaEnabled", santa ? 1f : 0f);
            m.SetFloat("_WitchEnabled", witch ? 1f : 0f);
            // 窓の明かりの色（青くしない）
            m.SetColor("_WindowColorWarm", new Color(1f, 0.8f, 0.55f));
            m.SetColor("_WindowColorCool", new Color(1f, 0.95f, 0.86f));
            m.SetFloat("_CitySeed", citySeed);

            // 空
            m.SetFloat("_CloudCoverage", cloudCoverage);
            m.SetFloat("_CloudSpeed", cloudSpeed);
            m.SetFloat("_StarAmount", starAmount);
            if (!useTimeDefaultsForBody)
            {
                m.SetFloat("_MoonAzimuth", bodyAzimuth);
                m.SetFloat("_MoonAltitude", bodyAltitude);
            }
            if (timeOfDay == TIME_NIGHT) m.SetFloat("_MoonPhase", moonPhase);

            // 品質
            m.SetFloat("_MaxSteps", maxSteps);
            m.SetFloat("_MaxFarSteps", maxFarSteps);

            // 天気（雲・星・かすみも合わせて変える）
            ApplyWeather(m);

            // 引き継ぐ時は、空中戦の色（時間帯で変わる値）を元のマテリアルのまま
            if (sourceMaterial != null && inheritTweaks && sourceMaterial.HasProperty("_DogfightColorA"))
            {
                m.SetColor("_DogfightColorA", sourceMaterial.GetColor("_DogfightColorA"));
                m.SetColor("_DogfightColorB", sourceMaterial.GetColor("_DogfightColorB"));
            }

            // 後で読み込めるように、このウィンドウだけの設定を覚えておく
            m.SetFloat("_GenTimeOfDay", timeOfDay);
            m.SetFloat("_GenCityBrightness", cityBrightness);
            m.SetFloat("_GenWeather", weather);
            m.SetFloat("_GenPrecipAmount", precipAmount);
            m.SetFloat("_GenUseDefaultBody", useTimeDefaultsForBody ? 1f : 0f);
        }

        private void ApplyWeather(Material m)
        {
            float amount = Mathf.Clamp01(precipAmount);
            bool rain = weather == WEATHER_RAIN;
            bool snow = weather == WEATHER_SNOW;
            bool day = timeOfDay == TIME_DAY;

            m.SetFloat("_RainAmount", rain ? amount : 0f);
            m.SetFloat("_SnowAmount", snow ? amount : 0f);
            m.SetFloat("_SnowCover", snow ? Mathf.Lerp(0.3f, 0.9f, amount) : 0f);
            m.SetColor("_RainColor", day ? new Color(0.55f, 0.6f, 0.65f) : new Color(0.3f, 0.32f, 0.36f));
            m.SetColor("_SnowColor", day ? new Color(0.95f, 0.95f, 1f) : new Color(0.6f, 0.62f, 0.68f));
            Color snowGround = timeOfDay == TIME_DAY ? new Color(0.8f, 0.82f, 0.86f)
                             : timeOfDay == TIME_DUSK ? new Color(0.25f, 0.22f, 0.24f)
                             : timeOfDay == TIME_DAWN ? new Color(0.3f, 0.28f, 0.32f)
                             : new Color(0.12f, 0.12f, 0.14f);
            m.SetColor("_SnowGroundColor", snowGround);

            if (rain || snow)
            {
                m.SetFloat("_CloudCoverage", Mathf.Max(m.GetFloat("_CloudCoverage"), Mathf.Lerp(0.7f, 0.95f, amount)));
                m.SetFloat("_StarAmount", 0f);
                m.SetFloat("_FogDensity", m.GetFloat("_FogDensity") * Mathf.Lerp(1.3f, 2.5f, amount));
                m.SetFloat("_MoonGlowIntensity", m.GetFloat("_MoonGlowIntensity") * 0.5f);
                m.SetFloat("_ContrailBrightness", 0f);
            }
        }

        // ------------------------------------------------------------
        // 読み込み（バリエーション作り）
        // ------------------------------------------------------------

        private void LoadFromMaterial(Material m)
        {
            if (m == null) return;
            if (!m.HasProperty("_ViewHeight") || !m.HasProperty("_CellSize"))
            {
                EditorUtility.DisplayDialog("スカイボックス生成", $"「{m.name}」は {CITY_SHADER} のマテリアルではないため、読み込めません。", "OK");
                return;
            }

            timeOfDay = Mathf.Clamp(Mathf.RoundToInt(Get(m, "_GenTimeOfDay", timeOfDay)), 0, TIME_LABELS.Length - 1);
            cityBrightness = Get(m, "_GenCityBrightness", cityBrightness);
            weather = Mathf.Clamp(Mathf.RoundToInt(Get(m, "_GenWeather", weather)), 0, WEATHER_LABELS.Length - 1);
            precipAmount = Get(m, "_GenPrecipAmount", precipAmount);
            useTimeDefaultsForBody = Get(m, "_GenUseDefaultBody", 1f) > 0.5f;
            windowCoolRatio = Get(m, "_WindowCoolRatio", windowCoolRatio);

            viewHeight = Get(m, "_ViewHeight", viewHeight);
            cityNear = Get(m, "_CityNear", cityNear);
            detailDistance = Get(m, "_DetailDistance", detailDistance);
            cityFar = Get(m, "_CityFar", cityFar);

            mansionRatio = Get(m, "_MansionRatio", mansionRatio);
            towerRatio = Get(m, "_TowerRatio", towerRatio);
            houseRatio = Get(m, "_HouseRatio", houseRatio);
            parkRatio = Get(m, "_ParkRatio", parkRatio);
            mansionFloorsMin = Mathf.RoundToInt(Get(m, "_MansionFloorsMin", mansionFloorsMin));
            mansionFloorsMax = Mathf.RoundToInt(Get(m, "_MansionFloorsMax", mansionFloorsMax));
            towerHeightMin = Get(m, "_TowerHeightMin", towerHeightMin);
            towerHeightMax = Get(m, "_TowerHeightMax", towerHeightMax);

            cellSize = Get(m, "_CellSize", cellSize);
            superblockCells = Mathf.RoundToInt(Get(m, "_SuperblockCells", superblockCells));
            sideRoadChance = Get(m, "_SideRoadChance", sideRoadChance);
            innerRoadChance = Get(m, "_InnerRoadChance", innerRoadChance);
            treeSize = Get(m, "_TreeSize", treeSize);
            parkLightChance = Get(m, "_ParkLightChance", parkLightChance);
            carDensity = Get(m, "_CarDensity", carDensity);
            citySeed = Mathf.RoundToInt(Get(m, "_CitySeed", citySeed));

            airlinerCount = Mathf.RoundToInt(Get(m, "_AirlinerCount", airlinerCount));
            dogfight = Get(m, "_DogfightEnabled", dogfight ? 1f : 0f) > 0.5f;
            dogfightAzimuth = Get(m, "_DogfightAzimuth", dogfightAzimuth);
            dogfightBrightness = Get(m, "_DogfightBrightness", dogfightBrightness);
            santa = Get(m, "_SantaEnabled", santa ? 1f : 0f) > 0.5f;
            witch = Get(m, "_WitchEnabled", witch ? 1f : 0f) > 0.5f;

            cloudCoverage = Get(m, "_CloudCoverage", cloudCoverage);
            cloudSpeed = Get(m, "_CloudSpeed", cloudSpeed);
            starAmount = Get(m, "_StarAmount", starAmount);
            bodyAzimuth = Get(m, "_MoonAzimuth", bodyAzimuth);
            bodyAltitude = Get(m, "_MoonAltitude", bodyAltitude);
            moonPhase = Get(m, "_MoonPhase", moonPhase);

            maxSteps = Mathf.RoundToInt(Get(m, "_MaxSteps", maxSteps));
            maxFarSteps = Mathf.RoundToInt(Get(m, "_MaxFarSteps", maxFarSteps));

            assetName = m.name;
            Repaint();
            Debug.Log($"[MET_SkyboxGenerator] 「{m.name}」の設定を読み込みました。時間帯や天気を変えて「新しく生成」すると、同じ街のバリエーションができます。", m);
        }

        private static float Get(Material m, string name, float fallback)
        {
            return m.HasProperty(name) ? m.GetFloat(name) : fallback;
        }

        // 時間帯ごとの色と光（空・月/太陽・雲・建物・地面）
        private static void ApplyTimePreset(Material m, int time)
        {
            switch (time)
            {
                case TIME_DUSK:
                    SetSky(m, new Color(0.08f, 0.10f, 0.26f), new Color(0.85f, 0.42f, 0.22f), 0.7f, new Color(0.95f, 0.40f, 0.18f), 0.8f, 0.15f);
                    SetBody(m, 250f, 3f, 0.03f, new Color(1f, 0.6f, 0.3f), 6f, 0f, 0f, new Color(1f, 0.5f, 0.2f), 1.2f, 6f);
                    SetClouds(m, new Color(0.25f, 0.14f, 0.17f), new Color(1f, 0.6f, 0.4f), 0.3f);
                    SetBuildings(m, new Color(0.06f, 0.06f, 0.08f), 1.5f, 0.4f, new Color(0.05f, 0.05f, 0.08f), 0.25f, 1.1f);
                    SetGround(m, new Color(0.06f, 0.055f, 0.06f), new Color(0.045f, 0.043f, 0.05f), new Color(0.045f, 0.065f, 0.04f), new Color(0.05f, 0.075f, 0.05f), 0.6f);
                    SetHaze(m, new Color(0.75f, 0.55f, 0.45f, 0.3f), 0.001f);
                    SetStreet(m, new Color(0.08f, 0.075f, 0.08f), new Color(0.3f, 0.3f, 0.3f), 0.9f, 1.2f);
                    SetAircraft(m, 1.2f, new Color(0.35f, 0.25f, 0.2f), new Color(1f, 0.75f, 0.6f), 0.4f,
                                new Color(1f, 0.85f, 0.7f), new Color(1f, 0.6f, 0.35f));
                    break;

                case TIME_DAY:
                    SetSky(m, new Color(0.18f, 0.38f, 0.80f), new Color(0.65f, 0.78f, 0.92f), 0.5f, new Color(0.80f, 0.85f, 0.90f), 0.3f, 0.2f);
                    SetBody(m, 160f, 55f, 0.025f, new Color(1f, 0.97f, 0.9f), 8f, 0f, 0f, new Color(1f, 0.95f, 0.85f), 0.8f, 8f);
                    SetClouds(m, new Color(0.60f, 0.65f, 0.72f), new Color(1f, 1f, 1f), 0f);
                    SetBuildings(m, new Color(0.35f, 0.36f, 0.38f), 1f, 0.35f, new Color(0.30f, 0.40f, 0.50f), 0.05f, 0.3f);
                    SetGround(m, new Color(0.22f, 0.22f, 0.21f), new Color(0.12f, 0.12f, 0.13f), new Color(0.15f, 0.30f, 0.12f), new Color(0.10f, 0.25f, 0.10f), 0f);
                    SetHaze(m, new Color(0.80f, 0.85f, 0.92f, 0.5f), 0.0006f);
                    SetStreet(m, new Color(0.30f, 0.30f, 0.29f), new Color(0.75f, 0.75f, 0.72f), 0.15f, 0f);
                    SetAircraft(m, 0.3f, new Color(0.8f, 0.8f, 0.82f), new Color(1f, 1f, 1f), 0.8f,
                                new Color(0.95f, 0.97f, 1f), new Color(0.9f, 0.92f, 0.95f));
                    break;

                case TIME_DAWN:
                    SetSky(m, new Color(0.12f, 0.16f, 0.35f), new Color(0.75f, 0.60f, 0.55f), 0.6f, new Color(0.90f, 0.60f, 0.50f), 0.6f, 0.15f);
                    SetBody(m, 80f, 4f, 0.03f, new Color(1f, 0.75f, 0.55f), 5f, 0f, 0f, new Color(1f, 0.7f, 0.5f), 1f, 7f);
                    SetClouds(m, new Color(0.30f, 0.25f, 0.32f), new Color(1f, 0.75f, 0.65f), 0.2f);
                    SetBuildings(m, new Color(0.08f, 0.08f, 0.11f), 1.3f, 0.35f, new Color(0.08f, 0.09f, 0.12f), 0.12f, 0.8f);
                    SetGround(m, new Color(0.07f, 0.065f, 0.075f), new Color(0.05f, 0.05f, 0.06f), new Color(0.05f, 0.07f, 0.05f), new Color(0.05f, 0.08f, 0.055f), 0.3f);
                    SetHaze(m, new Color(0.75f, 0.65f, 0.65f, 0.3f), 0.0009f);
                    SetStreet(m, new Color(0.09f, 0.09f, 0.1f), new Color(0.3f, 0.3f, 0.3f), 0.7f, 1f);
                    SetAircraft(m, 1.2f, new Color(0.3f, 0.25f, 0.25f), new Color(1f, 0.8f, 0.75f), 0.4f,
                                new Color(0.8f, 0.85f, 1f), new Color(1f, 0.7f, 0.5f));
                    break;

                default: // 夜
                    SetSky(m, new Color(0.008f, 0.012f, 0.035f), new Color(0.035f, 0.045f, 0.09f), 0.6f, new Color(0.30f, 0.18f, 0.12f), 0.7f, 0.12f);
                    SetBody(m, 140f, 28f, 0.035f, new Color(1f, 0.96f, 0.86f), 3f, 0.25f, 0.35f, new Color(0.45f, 0.5f, 0.65f), 0.5f, 14f);
                    SetClouds(m, new Color(0.05f, 0.055f, 0.08f), new Color(0.42f, 0.44f, 0.52f), 0.6f);
                    SetBuildings(m, new Color(0.018f, 0.022f, 0.032f), 1f, 0.25f, new Color(0.01f, 0.012f, 0.018f), 0.35f, 1.4f);
                    SetGround(m, new Color(0.04f, 0.04f, 0.045f), new Color(0.03f, 0.03f, 0.035f), new Color(0.03f, 0.05f, 0.03f), new Color(0.035f, 0.06f, 0.04f), 1f);
                    SetHaze(m, new Color(0.5f, 0.5f, 0.55f, 0f), 0.0008f);
                    SetStreet(m, new Color(0.06f, 0.06f, 0.065f), new Color(0.3f, 0.3f, 0.3f), 1.2f, 1.5f);
                    SetAircraft(m, 1.5f, new Color(0f, 0f, 0f), new Color(1f, 1f, 1f), 0f,
                                new Color(0.55f, 0.8f, 1f), new Color(1f, 0.65f, 0.35f));
                    break;
            }
        }

        private static void SetSky(Material m, Color zenith, Color horizon, float gradientPower, Color glow, float glowIntensity, float glowHeight)
        {
            m.SetColor("_ZenithColor", zenith);
            m.SetColor("_HorizonColor", horizon);
            m.SetFloat("_SkyGradientPower", gradientPower);
            m.SetColor("_CityGlowColor", glow);
            m.SetFloat("_CityGlowIntensity", glowIntensity);
            m.SetFloat("_CityGlowHeight", glowHeight);
        }

        private static void SetBody(Material m, float azimuth, float altitude, float size, Color color, float brightness,
                                    float phase, float crater, Color glowColor, float glowIntensity, float glowSharpness)
        {
            m.SetFloat("_MoonAzimuth", azimuth);
            m.SetFloat("_MoonAltitude", altitude);
            m.SetFloat("_MoonSize", size);
            m.SetColor("_MoonColor", color);
            m.SetFloat("_MoonBrightness", brightness);
            m.SetFloat("_MoonPhase", phase);
            m.SetFloat("_MoonCrater", crater);
            m.SetColor("_MoonGlowColor", glowColor);
            m.SetFloat("_MoonGlowIntensity", glowIntensity);
            m.SetFloat("_MoonGlowSharpness", glowSharpness);
        }

        private static void SetClouds(Material m, Color shadow, Color lit, float cityLight)
        {
            m.SetColor("_CloudColor", shadow);
            m.SetColor("_CloudLitColor", lit);
            m.SetFloat("_CloudCityLight", cityLight);
        }

        private static void SetBuildings(Material m, Color wall, float ambient, float directLight, Color glass, float litRatio, float windowBrightness)
        {
            m.SetColor("_BuildingColor", wall);
            m.SetFloat("_BuildingAmbient", ambient);
            m.SetFloat("_MoonLightOnBuildings", directLight);
            m.SetColor("_WindowGlassColor", glass);
            m.SetFloat("_WindowLitRatio", litRatio);
            m.SetFloat("_WindowBrightness", windowBrightness);
        }

        private static void SetGround(Material m, Color ground, Color road, Color park, Color tree, float streetLight)
        {
            m.SetColor("_GroundColor", ground);
            m.SetColor("_RoadColor", road);
            m.SetColor("_ParkColor", park);
            m.SetColor("_TreeColor", tree);
            m.SetFloat("_StreetLightBrightness", streetLight);
        }

        private static void SetStreet(Material m, Color sidewalk, Color marking, float corridorLight, float carLight)
        {
            m.SetColor("_SidewalkColor", sidewalk);
            m.SetColor("_RoadMarkingColor", marking);
            m.SetFloat("_CorridorLightBrightness", corridorLight);
            m.SetFloat("_CarLightBrightness", carLight);
        }

        // 空の乗り物（旅客機の灯り・機体の色・飛行機雲、空中戦の軌跡の色）
        private static void SetAircraft(Material m, float lightBrightness, Color body, Color contrail, float contrailBrightness,
                                        Color fighterA, Color fighterB)
        {
            m.SetFloat("_AirlinerLightBrightness", lightBrightness);
            m.SetColor("_AirlinerBodyColor", body);
            m.SetColor("_ContrailColor", contrail);
            m.SetFloat("_ContrailBrightness", contrailBrightness);
            m.SetColor("_DogfightColorA", fighterA);
            m.SetColor("_DogfightColorB", fighterB);
        }

        private static void SetHaze(Material m, Color fog, float density)
        {
            m.SetColor("_FogColor", fog);
            m.SetFloat("_FogDensity", density);
        }

        private static string EnsureFolder(string path)
        {
            string[] parts = path.Split('/');
            string current = parts[0];
            for (int i = 1; i < parts.Length; i++)
            {
                string next = current + "/" + parts[i];
                if (!AssetDatabase.IsValidFolder(next)) AssetDatabase.CreateFolder(current, parts[i]);
                current = next;
            }
            return current;
        }
    }
}
