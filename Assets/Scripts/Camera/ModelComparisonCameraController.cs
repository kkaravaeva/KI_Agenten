using UnityEngine;

public class ModelComparisonCameraController : MonoBehaviour
{
    int _current = 0;
    float _lerpSpeed = 4f;

    Vector3    _targetPos;
    Quaternion _targetRot;

    static readonly Vector3[] Positions = new Vector3[]
    {
        new Vector3( 80f, 150f, -10f),  // 0: Uebersicht
        new Vector3(  0f, 100f,  50f),  // 1: LSTM
        new Vector3( 80f, 100f,  50f),  // 2: Transformer
        new Vector3(160f, 100f,  50f),  // 3: MLP
    };

    static readonly Vector3[] Rotations = new Vector3[]
    {
        new Vector3(62f, 0f, 0f),
        new Vector3(62f, 0f, 0f),
        new Vector3(62f, 0f, 0f),
        new Vector3(62f, 0f, 0f),
    };

    static readonly string[] Labels = new string[]
    {
        "Uebersicht",
        "LSTM",
        "Transformer",
        "MLP",
    };

    void Start()
    {
        SetPreset(0, true);
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Alpha0) || Input.GetKeyDown(KeyCode.Tab))
            SetPreset(0);
        if (Input.GetKeyDown(KeyCode.Alpha1))
            SetPreset(1);
        if (Input.GetKeyDown(KeyCode.Alpha2))
            SetPreset(2);
        if (Input.GetKeyDown(KeyCode.Alpha3))
            SetPreset(3);

        transform.position = Vector3.Lerp(transform.position, _targetPos, Time.deltaTime * _lerpSpeed);
        transform.rotation = Quaternion.Slerp(transform.rotation, _targetRot, Time.deltaTime * _lerpSpeed);
    }

    void SetPreset(int index, bool instant = false)
    {
        _current   = index;
        _targetPos = Positions[index];
        _targetRot = Quaternion.Euler(Rotations[index]);
        if (instant)
        {
            transform.position = _targetPos;
            transform.rotation = _targetRot;
        }
    }

    void OnGUI()
    {
        GUI.Box(new Rect(Screen.width - 220f, 10f, 210f, 95f), "");
        GUI.Label(new Rect(Screen.width - 215f, 12f, 200f, 20f), "Ansicht: " + Labels[_current]);
        GUI.Label(new Rect(Screen.width - 215f, 32f, 200f, 20f), "[0/Tab] Uebersicht");
        GUI.Label(new Rect(Screen.width - 215f, 50f, 200f, 20f), "[1] LSTM");
        GUI.Label(new Rect(Screen.width - 215f, 68f, 200f, 20f), "[2] Transformer");
        GUI.Label(new Rect(Screen.width - 215f, 86f, 200f, 20f), "[3] MLP");
    }
}
