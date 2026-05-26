using UnityEngine;

[RequireComponent(typeof(MapGenerator))]
public class OutdoorGround : MonoBehaviour
{
    public GameObject groundPlane;
    public float extraBorder = 100f;

    private MapGenerator _mapGen;

    private void Awake()
    {
        _mapGen = GetComponent<MapGenerator>();
        _mapGen.OnMapGenerated += Refresh;
    }

    private void OnDestroy()
    {
        if (_mapGen != null) _mapGen.OnMapGenerated -= Refresh;
    }

    public void Refresh()
    {
        if (groundPlane == null) return;
        Bounds b       = _mapGen.GetWorldBounds();
        float  mapSize = Mathf.Max(b.size.x, b.size.z);
        // Minimum 6000 units so the plane always reaches the fog horizon (~300 units at density 0.01)
        float  size    = Mathf.Max(mapSize + extraBorder * 2f, 6000f);
        groundPlane.transform.position   = new Vector3(b.center.x, -0.02f, b.center.z);
        groundPlane.transform.localScale = new Vector3(size / 10f, 1f, size / 10f);

        var mr = groundPlane.GetComponent<MeshRenderer>();
        if (mr != null && mr.sharedMaterial != null)
        {
            float tiling = size / 4f;
            mr.sharedMaterial.SetTextureScale("_MainTex", new Vector2(tiling, tiling));
            mr.sharedMaterial.SetTextureScale("_BumpMap", new Vector2(tiling, tiling));
        }
    }
}
