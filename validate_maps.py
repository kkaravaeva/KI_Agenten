"""
Map Feasibility Validator (standalone Python, no Unity needed)
Reads all MapData .asset files and runs BFS to check if Goal is reachable from Spawn.

CellType:
  Empty=0, Floor=1, Wall=2, Obstacle=3, Goal=4, SpawnPoint=5, Lava=6, Hole=7, Platform=8
"""

import os
import re
import struct
from collections import deque

LAYOUTS_DIR = os.path.join(os.path.dirname(__file__), "Assets", "Layouts")

# CellType constants
EMPTY      = 0
FLOOR      = 1
WALL       = 2
OBSTACLE   = 3
GOAL       = 4
SPAWNPOINT = 5
LAVA       = 6
HOLE       = 7
PLATFORM   = 8

WALKABLE = {FLOOR, SPAWNPOINT, GOAL, OBSTACLE, PLATFORM}
DIRS = [(1,0),(-1,0),(0,1),(0,-1)]


def parse_asset(path):
    """Returns (name, width, height, cells_list) or None on failure."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
    except Exception as e:
        return None

    m_name = re.search(r"m_Name:\s*(\S+)", content)
    m_width = re.search(r"\bwidth:\s*(\d+)", content)
    m_height = re.search(r"\bheight:\s*(\d+)", content)
    m_cells = re.search(r"\bcells:\s*([0-9a-fA-F]+)", content)

    if not (m_name and m_width and m_height and m_cells):
        return None

    name   = m_name.group(1)
    width  = int(m_width.group(1))
    height = int(m_height.group(1))
    hex_str = m_cells.group(1)

    # Each cell is 4 bytes little-endian int32 = 8 hex chars
    expected_len = width * height * 8
    if len(hex_str) < expected_len:
        return None

    cells = []
    for i in range(width * height):
        chunk = hex_str[i*8:(i+1)*8]
        val = struct.unpack("<I", bytes.fromhex(chunk))[0]
        cells.append(val)

    return (name, width, height, cells)


def get_cell(cells, width, x, y):
    return cells[y * width + x]


def in_bounds(width, height, x, y):
    return 0 <= x < width and 0 <= y < height


def has_dangerous_neighbour(cells, width, height, x, y):
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            if dx == 0 and dy == 0:
                continue
            nx, ny = x + dx, y + dy
            if not in_bounds(width, height, nx, ny):
                continue
            t = get_cell(cells, width, nx, ny)
            if t == LAVA or t == HOLE:
                return True
    return False


def check_map(name, width, height, cells):
    """Returns (status, detail) where status in {OK, NO_GOAL, NO_SPAWN, UNSOLVABLE}"""
    spawns = []
    goals  = set()

    for y in range(height):
        for x in range(width):
            t = get_cell(cells, width, x, y)
            if t == SPAWNPOINT:
                spawns.append((x, y))
            if t == GOAL:
                goals.add((x, y))

    # Fallback spawn: Floor cells without dangerous neighbours
    if not spawns:
        for y in range(height):
            for x in range(width):
                if get_cell(cells, width, x, y) == FLOOR:
                    if not has_dangerous_neighbour(cells, width, height, x, y):
                        spawns.append((x, y))

    # Second fallback: any Floor cell
    if not spawns:
        for y in range(height):
            for x in range(width):
                if get_cell(cells, width, x, y) == FLOOR:
                    spawns.append((x, y))

    if not goals:
        return "NO_GOAL", f"{width}x{height}"
    if not spawns:
        return "NO_SPAWN", f"{width}x{height}"

    # BFS
    visited = set(spawns)
    queue = deque(spawns)

    while queue:
        cx, cy = queue.popleft()
        if (cx, cy) in goals:
            return "OK", ""

        for dx, dy in DIRS:
            # Normal step
            nx, ny = cx + dx, cy + dy
            if in_bounds(width, height, nx, ny):
                t = get_cell(cells, width, nx, ny)
                if t in WALKABLE and (nx, ny) not in visited:
                    visited.add((nx, ny))
                    queue.append((nx, ny))

            # Jump over single Lava cell
            mx, my = cx + dx, cy + dy      # mid (lava)
            jx, jy = cx + dx*2, cy + dy*2  # jump target
            if in_bounds(width, height, mx, my) and get_cell(cells, width, mx, my) == LAVA:
                # Check lava is only 1 wide
                lx2, ly2 = mx + dx, my + dy
                lava_wide = in_bounds(width, height, lx2, ly2) and get_cell(cells, width, lx2, ly2) == LAVA
                if not lava_wide and in_bounds(width, height, jx, jy):
                    t = get_cell(cells, width, jx, jy)
                    if t in WALKABLE and (jx, jy) not in visited:
                        visited.add((jx, jy))
                        queue.append((jx, jy))

    return "UNSOLVABLE", f"{width}x{height}"


def main():
    results = {"OK": [], "NO_GOAL": [], "NO_SPAWN": [], "UNSOLVABLE": [], "INVALID": []}

    asset_paths = []
    for root, dirs, files in os.walk(LAYOUTS_DIR):
        for f in files:
            if f.endswith(".asset"):
                asset_paths.append(os.path.join(root, f))

    asset_paths.sort()
    print(f"Checking {len(asset_paths)} map assets...\n")

    for path in asset_paths:
        parsed = parse_asset(path)
        if parsed is None:
            rel = os.path.relpath(path, LAYOUTS_DIR)
            results["INVALID"].append(rel)
            continue

        name, width, height, cells = parsed
        status, detail = check_map(name, width, height, cells)
        results[status].append((name, detail))

    # Summary
    print("=" * 60)
    print(f"RESULTS ({len(asset_paths)} total):")
    print(f"  OK:          {len(results['OK'])}")
    print(f"  Unsolvable:  {len(results['UNSOLVABLE'])}")
    print(f"  No Goal:     {len(results['NO_GOAL'])}")
    print(f"  No Spawn:    {len(results['NO_SPAWN'])}")
    print(f"  Invalid:     {len(results['INVALID'])}")
    print("=" * 60)

    if results["UNSOLVABLE"]:
        print(f"\n[UNSOLVABLE] ({len(results['UNSOLVABLE'])}):")
        for name, detail in results["UNSOLVABLE"]:
            print(f"  {name}  ({detail})")

    if results["NO_GOAL"]:
        print(f"\n[NO GOAL] ({len(results['NO_GOAL'])}):")
        for name, detail in results["NO_GOAL"]:
            print(f"  {name}  ({detail})")

    if results["NO_SPAWN"]:
        print(f"\n[NO SPAWN] ({len(results['NO_SPAWN'])}):")
        for name, detail in results["NO_SPAWN"]:
            print(f"  {name}  ({detail})")

    if results["INVALID"]:
        print(f"\n[INVALID]:")
        for p in results["INVALID"]:
            print(f"  {p}")

    if not any([results["UNSOLVABLE"], results["NO_GOAL"], results["NO_SPAWN"], results["INVALID"]]):
        print("\nAll maps are solvable!")


if __name__ == "__main__":
    main()
