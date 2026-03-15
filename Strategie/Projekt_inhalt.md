# Transformer-basierter RL-Agent in einer 3D-Labyrinthwelt

## Forschungsfrage

Kann ein Transformer-basierter RL-Agent in einer selbst gebauten 3D-Labyrinthwelt generalisierbares Navigations- und Hindernisvermeidungsverhalten erlernen, das sich auf unbekannte Map-Layouts übertragen lässt?

---

## Motivation und Problemstellung

**Warum ist das Problem interessant?** Im Gegensatz zu reinen Pathfinding-Problemen muss der Agent hier nicht nur einen Weg durch das Labyrinth finden, sondern auch situativ auf unterschiedliche Gefahren reagieren – springen, umdrehen, Brücken nutzen. Diese Vielschichtigkeit macht das Szenario außerdem beliebig erweiterbar (z. B. dynamische Hindernisse, Knöpfe, Sammelobjekte), wobei genau diese Erweiterungen konkreter Bestandteil der Arbeit sind.

**Was soll der Agent lernen?** Der Agent soll durch Sensoren Hindernisse wie Lava, Löcher und Sackgassen erkennen und selbstständig lernen, darauf richtig zu reagieren (z. B. springen, umdrehen, Brücken nutzen), um den Ausgang des Labyrinths zu finden.

**In welcher Umgebung befindet er sich?** Der Agent agiert in einer Unity-3D-Umgebung mit grid-basierten Labyrinthen, die über mehrere unterschiedliche Map-Layouts variieren und verschiedene Hindernistypen (Lava, Löcher, Brücken, Sackgassen) enthalten.

---

## Klare Definition der Aufgabe des Agenten

- **Startzustand:** Der Agent spawnt zu Beginn jeder Episode an einem map-spezifischen Spawnpunkt innerhalb eines grid-basierten 3D-Labyrinths und verfügt über keinerlei Vorwissen über das aktuelle Layout.
- **Zielzustand:** Die Episode gilt als erfolgreich abgeschlossen, wenn der Agent das Zielobjekt (Goal) erreicht; sie endet vorzeitig bei Kontakt mit tödlichen Hindernissen (Lava, Loch) oder evtl. bei Überschreitung eines Zeitlimits.
- **Mögliche Hindernisse:** Das Labyrinth enthält Wände, Lavafelder (tödlich bei Berührung, überspringbar), Löcher/Abgründe (tödlich, nicht passierbar), Sackgassen, sowie in Erweiterung: dynamische Elemente wie Stacheln, Türen mit Knopfdruck, Sammelobjekte und Brücken über Lava-Bereiche (nur per Sprung nutzbar).
- **Fähigkeiten des Agenten:** Der Agent kann sich in vier Richtungen bewegen (vorwärts, rückwärts, links, rechts) und springen; seine Wahrnehmung erfolgt über ray-basierte Sensoren, die per Tag-System zwischen Wänden, Hindernistypen und dem Ziel unterscheiden. Erweiterung mit einem Kamerasensor möglich.

---

## Minimalumfang des Projekts (Scope Definition)

### Pflicht

- Selbst gebaute 3D-Labyrinthwelt in Unity mit grid-basiertem Map-System und mindestens fünf unterschiedlichen Map-Layouts
- Agent mit Bewegung in vier Richtungen und physikbasierter Sprungmechanik
- Ray-basierte Sensorik zur Unterscheidung von Wänden, Hindernistypen und Ziel
- Basis-Hindernisse: Lavafelder (tödlich, überspringbar), Löcher (tödlich, nicht passierbar) und Sackgassen
- Transformer-basiertes Entscheidungsmodell als Kern des Agenten
- MLP-Baseline (einfaches Neuronales Netzwerk) zum direkten Vergleich mit dem Transformer-Modell
- Reward-System mit Belohnung für Ziel-Erreichen, Bestrafung für Lava/Loch (evtl. Zeitlimit)
- Mindestens eine Ablationsstudie und Generalisierungstest auf mindestens einer komplett unbekannten Map
- Beobachtbarkeit: Live-Viewer oder Replay-System, TensorBoard-Metriken (Reward, Erfolgsrate, Episodenlänge)
- Reproduzierbares Git-Repository
- Schriftlicher Bericht und Video-Demos der Lernphase und finalen Läufe

### Erweiterungen

- Dynamische Hindernisse wie ausfahrende Stacheln oder sich bewegende Elemente, Brücken (nur per Sprung nutzbar)
- Interaktive Mechaniken wie Türen mit Knopfdruck
- Sammelobjekte (z. B. Sterne zur Reduktion von Zeitstrafen)
- Weitere Ablationsstudien (z. B. Curriculum Learning, unterschiedliche Sensorik-Konfigurationen, Gott- und Ego-Perspektive)
- Erhöhung der Map-Anzahl oder prozedurale Map-Generierung
- Multi-Agent-Setup (z. B. kooperative Labyrinth-Lösung mit zwei Agenten)