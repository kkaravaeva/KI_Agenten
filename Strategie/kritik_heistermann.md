# Projektübersicht — KI-Agent zur Labyrinth-Navigation

**Team:** Finn Ludwig, Ekaterina Karavaeva, David Pelcz, Alexander Bernecker
**Verbleibende Zeit:** ca. 6–8 Wochen

---

## 1. Fragen an Herrn Heistermann

- **Transformer-Integration:** Reicht es, das Standard-MLP in ML-Agents durch ein eigenes Transformer-Modell (z.B. GTrXL) zu ersetzen? Oder wird erwartet, dass ein komplett eigenes Training-Setup außerhalb von ML-Agents aufgebaut wird?
- **Nächste Einreichung:** Was genau ist die nächste Einreichung — ein überarbeiteter Zwischenstand/Projektbeschreibung oder bereits die Endabgabe? Gibt es einen festen Termin?

---

## 2. Offene Fragen

###  Dringend

- **Python/PyTorch-Kompetenz im Team abfragen** — Jedes Teammitglied soll ehrlich einschätzen: (a) Python-Erfahrung, (b) PyTorch/Deep-Learning-Erfahrung, (c) Bereitschaft sich einzuarbeiten. Ergebnis bestimmt den Transformer-Integrationsweg.
- **Nächste Einreichung bei Heistermann klären** — Zwischenstand oder Endabgabe? Fester Termin?
- **Feste Verantwortungsbereiche im Team zuweisen.** Heistermann schlägt vor: (1) 3D-Umgebung/Maps/Hindernisse, (2) RL-Problem/Reward/Baseline, (3) Transformer-Modell/Sequenzverarbeitung, (4) Evaluation/Doku/Reproduzierbarkeit. Im Team besprechen, wer welchen Bereich übernimmt.
- **GPU-Zugang klären:** Nur Laptops vorhanden — Transformer-Training auf CPU ist extrem langsam. Optionen prüfen: Uni-Rechenzentrum? Google Colab (Free/Pro)? Cloud-GPU? Oder Modellgröße so klein halten, dass CPU reicht?

### Technische Entscheidungen

- **Aktionsraum:** Diskret oder kontinuierlich oder hybrid? Empfehlung: Diskret ist einfacher zu trainieren und passt gut zu Grid-basiertem Labyrinth.
- **Prozedurale Map-Generierung:** Welcher Algorithmus? (z.B. Recursive Backtracking, Prim's, Randomized DFS, Cellular Automata) Wie werden Hindernisse (Lava, Löcher, Brücken) platziert? Wie wird Lösbarkeit garantiert?
- **Ray-Sensoren:** Wie viele Rays, welche Richtungen, welche Reichweite? Welche Tags sollen erkannt werden?
- **Reward-Funktion:** Konkrete Zahlenwerte müssen iterativ im Training ermittelt werden.
- **Zeitlimit:** Soll es ein maximales Step-Limit pro Episode geben? Wenn ja, wie viele Steps?
- **Systemarchitektur:** Wie werden die Komponenten aufgeteilt? Welche Scripts haben welche Verantwortung?
- **Prüfen ob Ray-Sensoren die richtige Wahl sind** oder ob Grid-Sensor/Camera-Sensor besser passen.

### Transformer & Framework

- Einarbeitung in Transformer-Architektur im RL-Kontext nötig (GTrXL, DI-engine/OpenDILab, oder eigenes PyTorch-Modell).
- Wie lässt sich ein Transformer in ML-Agents integrieren? Oder muss das Framework gewechselt werden?
- **Grundsatzfrage:** Ist ML-Agents überhaupt der richtige Weg, um alle Anforderungen (insbesondere Transformer) zu erfüllen? Alternativen prüfen.

### Evaluation & Dokumentation

- **Evaluationskonzept komplett erarbeiten:** Welche Metriken (Erfolgsrate, Episodenlänge, Reward-Kurven)? Was ist die Baseline? Wie sehen Generalisierungstests aus?
- **Ablationsstudie:** Wie konkret umsetzen? Erklärung: Eine Variable im System isoliert ändern, Rest gleich lassen, Ergebnis vergleichen. Naheliegende Optionen: (a) Transformer vs. MLP, (b) Reward-Shaping: ausgearbeitete vs. simple Reward-Funktion, (c) Sensorik: Ray vs. Grid-Sensor, (d) Curriculum: erst einfache dann schwere Maps vs. direkt alle. Mindestens eine Ablation ist Pflicht. Konkrete Wahl noch offen.
- **Beobachtbarkeitskonzept ausarbeiten:** Live-Viewer/Replays + Kennzahlen-Protokollierung (Reward, Erfolgsrate, Episodenlänge). TensorBoard + Unity-Recording + evtl. eigenes Logging. Aufgabenstellung fordert: Objektzustände, Kollisionen, Schalter/Türen-Status, getroffene Aktionen sichtbar.
- **Trainingsdaten auslesen und grafisch darstellen** — wie genau? TensorBoard oder eigene Lösung?
- **Methodische Begründung ausarbeiten:** Warum Unity, warum ML-Agents, warum PPO — Alternativen benennen und begründen.
- **Videodemos planen:** Aufgabenstellung fordert „kurze Videodemos" — wie aufnehmen? Unity Recorder? OBS? Welche Szenen zeigen (Lernphase + finale Läufe)?
- **Reproduzierbarkeit sicherstellen:** Aufgabenstellung fordert „reproduzierbares Git-Repository mit festen Zufalls-Seeds, Trainings-/Evaluationsskripte, Konfigurationen, Anleitung".
- **Neues, umfassendes Projektdokument aufsetzen,** das alle Kritikpunkte konkret adressiert.

---

## 3. Status Quo — Bereits entschieden / bekannt

### Agenten-Design

- Bewegungen: vorwärts, rückwärts, links, rechts, springen
- Sensorik: Ray-Sensoren geplant, Details noch offen
- Reward-Grundlogik: positiv fürs Ziel, negativ für Lava/Löcher/Zeitlimit, konkrete Werte noch offen — werden iterativ angepasst
- Episodenstart: Agent spawnt am definierten Spawnpunkt der jeweiligen Map
- Episodenende: Zielerreichung oder Tod (Lava, Loch)

### Framework & Lernverfahren

- ML-Agents mit PPO als Lernverfahren geplant — aber Standard-MLP reicht nicht, Transformer-Modell ist laut Aufgabenstellung zusätzlich gefordert
- Framework-Wahl: Unity wegen Vorerfahrung, ML-Agents als naheliegende Erweiterung — ob es die Transformer-Anforderung erfüllt ist noch offen

### Evaluation & Beobachtbarkeit

- Evaluation: Idee vorhanden — Werte grafisch darstellen, Trainingsläufe aufteilen/vergleichen. Konkrete Umsetzung noch offen.
- Beobachtbarkeit: Grundidee vorhanden, muss deutlich ausgearbeitet werden.
- Ablationsstudie: Konzept verstanden. Mindestens eine Pflicht. Konkrete Wahl noch offen.

### Team & Organisation

- Python/PyTorch-Kompetenz im Team: **noch ungeklärt** — Abfrage läuft
- Teamaufteilung: **bisher keine festen Bereiche** — muss geändert werden
- Bisherige Projektbeschreibung war bewusst nur als Richtungsabfrage gedacht, nicht als vollständiger Zwischenstand

### Noch ungeklärte Rahmenbedingungen

- Aktionsraum: **noch ungeklärt** — Team muss entscheiden
- Map-Generierung: **Prozedural geplant** — konkreter Algorithmus und Hindernisplatzierung noch offen
- Hardware: **Nur Laptops (CPU)** — GPU-Zugang muss geklärt werden
- Nächste Einreichung: **noch ungeklärt** — wird bei Heistermann erfragt

### Aktueller Umsetzungsstand

- Map-System: Code vorhanden (MapData, MapGenerator, CellType), MapData-Asset noch leer, prozedurale Generierung geplant aber noch nicht implementiert
- Prefabs: Floor, Wall, Goal, SpawnPoint, Lava, Hole als Platzhalter vorhanden
- Agent: noch nicht im Code, konkrete Umsetzung wird gerade geplant
- ML-Agents: noch nicht als Package eingebunden
- Training: noch nicht begonnen

### To-Dos

- Architekturdiagramm erstellen
- Umsetzungsstand transparent dokumentieren und bei nächster Einreichung mitliefern