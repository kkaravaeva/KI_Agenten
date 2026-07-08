#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

public static class StandaloneBuild
{
    [MenuItem("Tools/Build/Build Standalone (Windows x64)")]
    public static void BuildWindows()
    {
        var options = new BuildPlayerOptions
        {
            scenes           = new[] { "Assets/Scenes/Training Area.unity" },
            locationPathName = "Build/KI_Agenten.exe",
            target           = BuildTarget.StandaloneWindows64,
            options          = BuildOptions.None,
        };
        var report = BuildPipeline.BuildPlayer(options);
        Debug.Log($"[Build] Status: {report.summary.result}  |  Errors: {report.summary.totalErrors}");
    }

    // Wird per -executeMethod aus der Kommandozeile aufgerufen
    public static void BuildFromCommandLine()
    {
        BuildWindows();
        if (Application.isBatchMode)
            EditorApplication.Exit(0);
    }
}
#endif
