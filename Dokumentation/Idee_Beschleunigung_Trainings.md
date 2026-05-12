 Kurzantwort: Nicht direkt für Training-Areas — Unity's
  Hauptspiel-Loop (wo die Physics und MonoBehaviours laufen) ist
   single-threaded. Alle Areas teilen sich denselben Core.

  Was Unity intern auf mehrere Cores verteilt:
  - Rendering (teilweise)
  - Audio
  - Asset-Loading
  - Mit dem Job System/Burst Compiler geschriebener Code

  Aber das betrifft alles nicht die ML-Agents-Simulation selbst.

  Die echte Multi-Core-Lösung für ML-Agents:
  Mehrere separate Unity-Prozesse starten, jeder auf seinem
  eigenen Core. Das geht mit einem Standalone Build (nicht
  Editor):

  mlagents-learn config.yaml \
    --env=path/to/KI_Agenten.exe \
    --num-envs=4 \
    --base-port=5004

  --num-envs=4 startet 4 separate Unity-Prozesse, jeder auf
  einem eigenen CPU-Core. Das skaliert fast linear mit den
  Cores. Mit einem 8-Core-PC könntest du --num-envs=8 nutzen und
   8x mehr Daten sammeln als mit einer Editor-Instanz.

  Der Nachteil: Kein Live-Debugging in der Editor-Ansicht. Dafür
   deutlich schnellere Trainingszeiten für lange Runs.

  Für dieses Training bleibst du beim Editor-Ansatz. Aber für
  zukünftige lange Transformer-Läufe ist der Standalone-Build +
  --num-envs der nächste große Schritt.