Transformer V24 - Paket fuer Kollegen
======================================

Stand: 30.999.993 Trainings-Steps
Architektur: PPO + Transformer-Memory (sequence_length=16, memory_size=128)

Inhalt
------
results/v24/
  configuration.yaml                          Hyperparameter
  LabyrinthNavigator/
    checkpoint.pt                             Aktueller Modellzustand (zum Resumen/Inference)
    LabyrinthNavigator-*.pt                   Die letzten 5 Checkpoints
    events.out.tfevents.*                     TensorBoard-Logs
  run_logs/
    timers.json                               Performance-Stats
    training_status.json                      Trainings-Status

builds/
  Transformer_Generallisiert.exe + Daten      Unity-Build (generalisiert) zum Anschauen
                                              (Daten liegen in Transformer_Generallisiert_Data/,
                                               wurden aus 'KI Agenten_Data/' umbenannt, damit
                                               Unity sie zur exe findet)

Anschauen
---------

1) TensorBoard (nur Metriken):
   tensorboard --logdir results/v24

2) Inference im Unity-Build (Modell spielt selbst):
   WICHTIG: Es gibt KEIN .onnx-File. Transformer-Inference laeuft nur
   ueber Python ML-Agents, nicht direkt im Build.

   In dem Ordner wo "results/" liegt:
   mlagents-learn results/v24/configuration.yaml --run-id=v24 --resume --inference

   Dann den Unity-Build starten - er connected automatisch auf Port 5004.
   (Python ML-Agents Version muss zur Trainings-Version passen.)
