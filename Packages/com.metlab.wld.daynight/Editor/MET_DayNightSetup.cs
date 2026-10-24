// ============================================================
// MET_DayNightSetup
// 概要: 昼夜システム（MET_DayNightSystem / MET_SkyboxArea）をシーンに作るエディタ拡張。
//       メニュー「Tools > Metlab > 昼夜システム」から使う。
//
//       昼夜システムを作成:
//         [MET]昼夜システム を作る（シーンに既にあれば選択するだけ）。
//         「どのエリアにもいない時」の昼の空に、今のシーンのスカイボックスを入れておく。
//
//       エリアを追加:
//         範囲の箱（BoxCollider・無効）＋ MET_SkyboxArea ＋ 額縁用の空の球 を作り、
//         昼夜システムのエリア一覧に追加する。
//         部屋のオブジェクトを選んでから実行すると、その部屋を囲む大きさで作る。
//
// バージョン: 1.0.0
//   a: 大きな変更（破壊的変更・仕様変更）
//   b: 機能追加・変更
//   c: 些細な修正・調整
// ============================================================

using UdonSharpEditor;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;

namespace Metlab.DayNight
{
    public static class MET_DayNightSetup
    {
        private const string MENU_ROOT = "Tools/Metlab/昼と夜をきりかえるやつ/";
        private const string SYSTEM_NAME = "[MET]昼夜システム";
        private const string AREA_NAME = "[MET]空のエリア";
        private const string VIEW_SKY_NAME = "額縁用の空（MirrorReflection）";
        private const string VIEW_SKY_LAYER = "MirrorReflection";

        private static readonly Vector3 DEFAULT_AREA_SIZE = new Vector3(30f, 20f, 30f);
        private const float AREA_MARGIN = 2f;          // 部屋を囲む時の余裕（m）
        private const float VIEW_SKY_DIAMETER = 600f;  // 額縁用の空の球の直径（m）。額縁のカメラの映す距離（500m）より内側に収まる大きさ

        // ------------------------------------------------------------
        // 昼夜システムを作成
        // ------------------------------------------------------------

        [MenuItem(MENU_ROOT + "昼夜システムを作成")]
        private static void CreateSystem()
        {
            var existing = Object.FindObjectOfType<MET_DayNightSystem>(true);
            if (existing != null)
            {
                Selection.activeGameObject = existing.gameObject;
                EditorGUIUtility.PingObject(existing.gameObject);
                Debug.Log("[MET_DayNightSetup] 昼夜システムはシーンに既にあります。", existing);
                return;
            }

            var go = new GameObject(SYSTEM_NAME);
            Undo.RegisterCreatedObjectUndo(go, "昼夜システムを作成");
            var system = UdonSharpUndo.AddComponent<MET_DayNightSystem>(go);

            var so = new SerializedObject(system);
            so.FindProperty("defaultDaySkybox").objectReferenceValue = RenderSettings.skybox;
            so.ApplyModifiedPropertiesWithoutUndo();
            UdonSharpEditorUtility.CopyProxyToUdon(system);

            Selection.activeGameObject = go;
            EditorSceneManager.MarkSceneDirty(go.scene);
            Debug.Log("[MET_DayNightSetup] 昼夜システムを作成しました。「どのエリアにもいない時」の夜の空を設定し、ジェスチャーコマンドのアクション6にこのオブジェクトを入れてください。", go);
        }

        // ------------------------------------------------------------
        // エリアを追加
        // ------------------------------------------------------------

        [MenuItem(MENU_ROOT + "エリアを追加（部屋を選んでから実行すると囲む大きさで作る）")]
        private static void AddArea()
        {
            // 範囲: 選んだオブジェクトの見た目全体を囲む。何も選んでいなければシーンビューの注視点に初期の大きさで
            Vector3 center;
            Vector3 size;
            GameObject selected = Selection.activeGameObject;
            if (selected != null && TryGetRendererBounds(selected, out Bounds b))
            {
                center = b.center;
                size = b.size + Vector3.one * (AREA_MARGIN * 2f);
            }
            else
            {
                SceneView view = SceneView.lastActiveSceneView;
                center = (view != null ? view.pivot : Vector3.zero) + Vector3.up * (DEFAULT_AREA_SIZE.y * 0.5f);
                size = DEFAULT_AREA_SIZE;
            }

            string areaName = GameObjectUtility.GetUniqueNameForSibling(null, selected != null ? $"{AREA_NAME}_{selected.name}" : AREA_NAME);
            var go = new GameObject(areaName);
            Undo.RegisterCreatedObjectUndo(go, "空のエリアを追加");
            go.transform.position = center;

            var box = go.AddComponent<BoxCollider>();
            box.size = size;
            box.isTrigger = true;
            box.enabled = false;   // 範囲として使うだけ（当たり判定にしない）

            // 額縁用の空の球（MirrorReflection レイヤー＝本人の画面には映らず、額縁のカメラにだけ映る）
            GameObject sky = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            sky.name = VIEW_SKY_NAME;
            sky.transform.SetParent(go.transform, false);
            sky.transform.localScale = Vector3.one * VIEW_SKY_DIAMETER;
            Object.DestroyImmediate(sky.GetComponent<Collider>());
            int layer = LayerMask.NameToLayer(VIEW_SKY_LAYER);
            if (layer >= 0) sky.layer = layer;
            var sr = sky.GetComponent<MeshRenderer>();
            sr.sharedMaterial = null;
            sr.enabled = false;    // 空のマテリアルは実行時に入る（エディタで紫の球が見えないように）
            sr.shadowCastingMode = ShadowCastingMode.Off;
            sr.receiveShadows = false;
            sr.lightProbeUsage = LightProbeUsage.Off;
            sr.reflectionProbeUsage = ReflectionProbeUsage.Off;

            var area = UdonSharpUndo.AddComponent<MET_SkyboxArea>(go);
            var so = new SerializedObject(area);
            so.FindProperty("bounds").objectReferenceValue = box;
            SerializedProperty renderers = so.FindProperty("viewSkyRenderers");
            renderers.arraySize = 1;
            renderers.GetArrayElementAtIndex(0).objectReferenceValue = sr;
            so.ApplyModifiedPropertiesWithoutUndo();
            UdonSharpEditorUtility.CopyProxyToUdon(area);

            // 昼夜システムのエリア一覧に追加
            var system = Object.FindObjectOfType<MET_DayNightSystem>(true);
            if (system != null)
            {
                var sso = new SerializedObject(system);
                SerializedProperty areas = sso.FindProperty("areas");
                areas.arraySize++;
                areas.GetArrayElementAtIndex(areas.arraySize - 1).objectReferenceValue = area;
                sso.ApplyModifiedProperties();
                UdonSharpEditorUtility.CopyProxyToUdon(system);
            }

            Selection.activeGameObject = go;
            EditorSceneManager.MarkSceneDirty(go.scene);
            string note = system != null ? "昼夜システムのエリア一覧に追加しました。" : "※シーンに昼夜システムが無いため、エリア一覧への追加はしていません。";
            Debug.Log($"[MET_DayNightSetup] 「{areaName}」を作成しました。{note} 昼・夜の空を設定してください。範囲は BoxCollider の大きさで調整します。", go);
        }

        // 子も含めた見た目（Renderer）全体を囲む範囲
        private static bool TryGetRendererBounds(GameObject root, out Bounds bounds)
        {
            bounds = new Bounds();
            bool found = false;
            foreach (var r in root.GetComponentsInChildren<Renderer>(true))
            {
                if (r is ParticleSystemRenderer) continue;
                if (!found) { bounds = r.bounds; found = true; }
                else bounds.Encapsulate(r.bounds);
            }
            return found;
        }
    }
}
