#if UNITY_EDITOR
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

/// Prueft alle MapData-Assets auf Loesbarkeit via BFS.
///
/// Menue: Tools / Map / Validate All Maps
///
/// Regeln:
///   - Begehbar:  Floor, SpawnPoint, Goal, Obstacle, Platform
///   - Sprung:    Lava-Zellen mit Breite 1 (horizontal/vertikal) koennen
///                uebersprungen werden (Abkuerzung im BFS)
///   - Unpassierbar: Hole, Wall, Empty, mehrzeilige Lava
///   - Kein SpawnPoint im Layout -> alle Floor-Zellen sind moegliche Spawns
///   - Kein Goal im Layout       -> Map gilt als nicht pruefbar (Warnung)
public static class MapFeasibilityValidator
{
    static readonly string[] SEARCH_FOLDERS = { "Assets/Layouts" };

    [MenuItem("Tools/Map/Validate All Maps")]
    public static void ValidateAllMaps()
    {
        string[] guids = AssetDatabase.FindAssets("t:MapData", SEARCH_FOLDERS);
        if (guids.Length == 0)
        {
            Debug.LogWarning("[MapValidator] Keine MapData-Assets in Assets/Layouts gefunden.");
            return;
        }

        int total = 0, ok = 0, noGoal = 0, noSpawn = 0, unsolvable = 0;
        var problems = new List<string>();

        foreach (string guid in guids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            var map = AssetDatabase.LoadAssetAtPath<MapData>(path);
            if (map == null || map.cells == null || map.cells.Length != map.width * map.height)
            {
                problems.Add($"[INVALID]  {map?.name ?? path} — Cells fehlen oder falsche Groesse");
                continue;
            }

            total++;
            var result = CheckMap(map);

            switch (result)
            {
                case Result.OK:
                    ok++;
                    break;
                case Result.NoGoal:
                    noGoal++;
                    problems.Add($"[NO GOAL]  {map.name}");
                    break;
                case Result.NoSpawn:
                    noSpawn++;
                    problems.Add($"[NO SPAWN] {map.name}");
                    break;
                case Result.Unsolvable:
                    unsolvable++;
                    problems.Add($"[UNSOLVABLE] {map.name}  ({map.width}x{map.height})");
                    break;
            }
        }

        // Zusammenfassung
        Debug.Log($"[MapValidator] ══ Ergebnis ══  {total} Maps geprueft");
        Debug.Log($"  OK:          {ok}");
        Debug.Log($"  Kein Goal:   {noGoal}");
        Debug.Log($"  Kein Spawn:  {noSpawn}");
        Debug.Log($"  Unloesbar:   {unsolvable}");

        if (problems.Count == 0)
        {
            Debug.Log("[MapValidator] Alle Maps sind loesbar!");
        }
        else
        {
            Debug.LogWarning($"[MapValidator] {problems.Count} Probleme gefunden:");
            foreach (var p in problems)
                Debug.LogWarning("  " + p);
        }

        EditorUtility.DisplayDialog(
            "Map Feasibility Check",
            $"Geprueft: {total}\n" +
            $"OK: {ok}   |   Unloesbar: {unsolvable}\n" +
            $"Kein Goal: {noGoal}   |   Kein Spawn: {noSpawn}\n\n" +
            (problems.Count > 0
                ? $"Details in der Console ({problems.Count} Probleme)."
                : "Alle Maps sind loesbar!"),
            "OK");
    }

    // ── Einzelne Map pruefen ──────────────────────────────────────────────────

    enum Result { OK, NoGoal, NoSpawn, Unsolvable }

    static Result CheckMap(MapData map)
    {
        // Alle Spawn- und Goal-Zellen sammeln
        var spawns = new List<Vector2Int>();
        var goals  = new HashSet<Vector2Int>();

        for (int y = 0; y < map.height; y++)
            for (int x = 0; x < map.width; x++)
            {
                CellType t = map.GetCell(x, y);
                if (t == CellType.SpawnPoint) spawns.Add(new Vector2Int(x, y));
                if (t == CellType.Goal)       goals.Add(new Vector2Int(x, y));
            }

        // Fallback Spawn: alle Floor-Zellen ohne gefaehrliche Nachbarn
        if (spawns.Count == 0)
        {
            for (int y = 0; y < map.height; y++)
                for (int x = 0; x < map.width; x++)
                    if (map.GetCell(x, y) == CellType.Floor && !HasDangerousNeighbour(map, x, y))
                        spawns.Add(new Vector2Int(x, y));
        }

        // Fallback: alle Floor-Zellen (ohne Sicherheitsabstand)
        if (spawns.Count == 0)
        {
            for (int y = 0; y < map.height; y++)
                for (int x = 0; x < map.width; x++)
                    if (map.GetCell(x, y) == CellType.Floor)
                        spawns.Add(new Vector2Int(x, y));
        }

        if (goals.Count == 0)  return Result.NoGoal;
        if (spawns.Count == 0) return Result.NoSpawn;

        // BFS von allen Spawn-Zellen, Goal muss erreichbar sein
        var visited = new HashSet<Vector2Int>();
        var queue   = new Queue<Vector2Int>();

        foreach (var s in spawns)
            if (visited.Add(s)) queue.Enqueue(s);

        var dirs = new[] {
            new Vector2Int(1,0), new Vector2Int(-1,0),
            new Vector2Int(0,1), new Vector2Int(0,-1)
        };

        while (queue.Count > 0)
        {
            var cur = queue.Dequeue();

            if (goals.Contains(cur)) return Result.OK;

            foreach (var d in dirs)
            {
                // Normaler Schritt
                var next = cur + d;
                if (IsWalkable(map, next) && visited.Add(next))
                    queue.Enqueue(next);

                // Sprung ueber 1-zellige Lava (horizontal oder vertikal)
                var mid  = cur + d;
                var jump = cur + d * 2;
                if (IsLava(map, mid) && !IsWideLava(map, mid, d) &&
                    IsWalkable(map, jump) && visited.Add(jump))
                    queue.Enqueue(jump);
            }
        }

        return Result.Unsolvable;
    }

    // ── Hilfsmethoden ─────────────────────────────────────────────────────────

    static bool InBounds(MapData map, Vector2Int p)
        => p.x >= 0 && p.y >= 0 && p.x < map.width && p.y < map.height;

    static CellType GetSafe(MapData map, Vector2Int p)
        => InBounds(map, p) ? map.GetCell(p.x, p.y) : CellType.Empty;

    static bool IsWalkable(MapData map, Vector2Int p)
    {
        if (!InBounds(map, p)) return false;
        CellType t = map.GetCell(p.x, p.y);
        return t == CellType.Floor || t == CellType.SpawnPoint ||
               t == CellType.Goal  || t == CellType.Obstacle   ||
               t == CellType.Platform;
    }

    static bool IsLava(MapData map, Vector2Int p)
        => InBounds(map, p) && map.GetCell(p.x, p.y) == CellType.Lava;

    // Prueft ob die Lava in Sprungrichtung breiter als 1 ist (dann nicht ueberspringbar)
    static bool IsWideLava(MapData map, Vector2Int lavaCell, Vector2Int dir)
        => IsLava(map, lavaCell + dir);   // naechste Zelle in selber Richtung = 2. Lava-Zelle

    static bool HasDangerousNeighbour(MapData map, int x, int y)
    {
        for (int dy = -1; dy <= 1; dy++)
            for (int dx = -1; dx <= 1; dx++)
            {
                if (dx == 0 && dy == 0) continue;
                var t = GetSafe(map, new Vector2Int(x + dx, y + dy));
                if (t == CellType.Lava || t == CellType.Hole) return true;
            }
        return false;
    }
}
#endif
