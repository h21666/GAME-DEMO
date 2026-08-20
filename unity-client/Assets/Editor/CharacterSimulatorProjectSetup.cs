using System.IO;
using AIGCCharacterSimulator.Client;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace AIGCCharacterSimulator.Client.Editor
{
    [InitializeOnLoad]
    public static class CharacterSimulatorProjectSetup
    {
        private const string MainScenePath = "Assets/Scenes/Main.unity";

        static CharacterSimulatorProjectSetup()
        {
            EditorApplication.delayCall += EnsureMainSceneInBuildSettings;
        }

        [MenuItem("AIGC Simulator/Open Main Scene")]
        public static void OpenMainScene()
        {
            EnsureMainSceneExists();
            EditorSceneManager.OpenScene(MainScenePath, OpenSceneMode.Single);
        }

        [MenuItem("AIGC Simulator/Rebuild Main Scene")]
        public static void RebuildMainScene()
        {
            Directory.CreateDirectory("Assets/Scenes");

            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            GameObject runtime = new GameObject("CharacterSimulatorRuntime");
            runtime.AddComponent<CharacterApiClient>();
            runtime.AddComponent<CharacterSimulatorBootstrap>();

            GameObject cameraObject = new GameObject("Main Camera");
            cameraObject.tag = "MainCamera";
            cameraObject.transform.position = new Vector3(0f, 0f, -10f);

            Camera camera = cameraObject.AddComponent<Camera>();
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = new Color(0.07f, 0.09f, 0.12f, 1f);
            camera.orthographic = true;
            camera.orthographicSize = 5f;

            EditorSceneManager.SaveScene(scene, MainScenePath);
            EnsureMainSceneInBuildSettings();
            Selection.activeGameObject = runtime;
        }

        private static void EnsureMainSceneExists()
        {
            if (!File.Exists(MainScenePath))
            {
                RebuildMainScene();
            }
        }

        private static void EnsureMainSceneInBuildSettings()
        {
            if (!File.Exists(MainScenePath))
            {
                return;
            }

            EditorBuildSettings.scenes = new[]
            {
                new EditorBuildSettingsScene(MainScenePath, true)
            };
        }
    }
}
