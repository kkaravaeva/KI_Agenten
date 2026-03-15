# Projekt-Roadmap: KI-Agent zur Labyrinth-Navigation
---------konzeptionelle Roadmap, soll ausdrücklich on the go überarbeitet werden------------------

**Team:** Finn Ludwig, Ekaterina Karavaeva, David Pelcz, Alexander Bernecker

Diese Roadmap beschreibt den Ablauf des Projekts in Milestones. Jeder Milestone baut auf dem vorherigen auf und enthält konkrete Zwischenziele mit kurzer Beschreibung.

---

## Milestone 1 — Projektstruktur & Map-Grundsystem

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 1.1 | Projektstruktur anlegen | Ordnerstruktur (Scripts/Map, Prefabs/Map, Scenes/Training) erstellen und ein zentrales MapRoot-GameObject in der Trainingsszene einrichten. |
| 1.2 | Map-Datenmodell & Generator | Grid-basiertes Datenmodell definieren (Zelltypen: Boden, Wand, Hindernis, Ziel, Spawn) und das Map-Generator-Script erstellen, das dieses Modell in GameObjects übersetzt. |
| 1.3 | Prefabs & Positionierung | Für jeden Zelltyp ein Prefab erstellen, Inspector-Referenzen im Generator anlegen und die Grid-zu-Welt-Koordinaten-Umrechnung implementieren. |
| 1.4 | Map-Erzeugung & Reset | Automatische Map-Generierung beim Szenenstart einbauen sowie eine Reset-Funktion, die alle Map-Objekte löscht und neu erzeugt. |

---

## Milestone 2 — Mehrere Maps & Sensorvorbereitung

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 2.1 | Tag-System & Sensorvorbereitung | Tags (Wall, Obstacle, Goal) im Tag Manager anlegen und alle Prefabs mit passenden Collidern und Tags versehen, damit Ray-Sensoren sie erkennen können. |
| 2.2 | Mehrere Map-Layouts erstellen | Fünf unterschiedliche Map-Layouts definieren, die sich in Wandplatzierung, Hindernissen, Ziel- und Spawnposition sowie Offenheit unterscheiden. |
| 2.3 | Map-Auswahl & Rotation | Auswahlmechanismus implementieren (fest oder zufällig) und den Reset so erweitern, dass bei jeder Episode ein anderes Layout geladen wird. |
| 2.4 | Testszene & Validierung | Testszene einrichten, die alle fünf Maps durchläuft und korrekte Positionierung, Hierarchy, Tags und Collider überprüft. |

---

## Milestone 3 — Agent-Grundsystem

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 3.1 | Agent-GameObject erstellen | Agent als ML-Agents-Agent konfigurieren mit Bewegungssteuerung (vorwärts, rückwärts, links, rechts) und physikbasierter Sprungmechanik. |
| 3.2 | Sensorik implementieren | Ray-basierte Sensoren einrichten, die über das Tag-System Wände, Hindernisse, Lava, Löcher und das Zielobjekt unterscheiden können. |
| 3.3 | Spawnpunkt-Integration | Agent-Spawn an das Map-Datenmodell koppeln, sodass der Agent bei jeder Episode am definierten Spawnpunkt der jeweiligen Map erscheint. |

---

## Milestone 4 — Hindernisse & Interaktion

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 4.1 | Basis-Hindernisse umsetzen | Lavafelder (überspringbar, tödlich), Löcher/Abgründe (tödlich, nicht passierbar) und Sackgassen als Prefabs mit Kollisionslogik bauen. |
| 4.2 | Todeslogik & Episode-Reset | Kollisionserkennung mit tödlichen Feldern implementieren, die eine Episode sofort beendet und den Agenten zurücksetzt. |

---

## Milestone 5 — Reward-System & Training

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 5.1 | Belohnungsstrategie umsetzen | Reward-Logik definieren: starke Belohnung fürs Ziel, Bestrafung für Lava/Löcher/Zeitlimit, neutrale bis leichte Belohnung für Hindernisüberwindung. |
| 5.2 | Trainingsumgebung konfigurieren | ML-Agents YAML-Konfiguration erstellen (Hyperparameter, Netzwerk, max Steps) und Multi-Agent-Setup ermöglichen. |
| 5.3 | Erstes Training & Iteration | Trainingsdurchläufe auf den fünf Maps starten, TensorBoard überwachen, Reward-Kurven analysieren und Parameter iterativ anpassen. |

---

## Milestone 6 — Recherche & Entscheidungsfindung

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 6.1 | Transformer-Integrationsstrategie recherchieren | Evaluieren, ob der Transformer über die ML-Agents Custom Network API (eigenes PyTorch-Modul als `NetworkBody`) integriert wird oder ob ein separates Trainingsframework (z. B. reines PyTorch, Stable-Baselines3) neben ML-Agents aufgesetzt wird. Entscheidungskriterien dokumentieren: Aufwand, Kompatibilität mit bestehendem Reward-/Sensor-Setup, Vergleichbarkeit mit MLP-Baseline. Entscheidung treffen und begründen. |
| 6.2 | Ablationsstudien recherchieren & auswählen | Mögliche Ablationsstudien sammeln und bewerten (z. B. Entfernen der Attention-Layer, Variation der Sensordichte, Reward-Shaping-Varianten, Curriculum Learning, Ego- vs. Gott-Perspektive). Mindestens eine Studie auswählen, die den Beitrag einer zentralen Komponente quantifizierbar macht. Auswahlbegründung dokumentieren. |
| 6.3 | Evaluations- & Beobachtbarkeitssystem recherchieren | Recherchieren, welche Metriken und Visualisierungstools eingesetzt werden: Live-Viewer in Unity vs. Replay-System, TensorBoard-Konfiguration, zusätzliche Metriken (z. B. Heatmaps, Agenten-Trajektorien). Technische Machbarkeit und Aufwand bewerten, Entscheidung dokumentieren. |
| 6.4 | Konkreten Umsetzungsplan erstellen | Auf Basis der Recherche-Ergebnisse aus 6.1–6.3 einen detaillierten Umsetzungsplan für die folgenden Milestones (7–9) erstellen: Architekturdetails des Transformers, genaues Ablationsdesign mit Variablen und Kontrollbedingungen, Evaluationsprotokoll mit Metriken und Testprozedur. |

---

## Milestone 7 — Transformer-Modell: Entwurf, Implementierung & Training

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 7.1 | Transformer-Modell entwerfen & implementieren | Basierend auf der Entscheidung aus 6.1: Transformer-basiertes Entscheidungsmodell implementieren (Self-Attention auf die Sensor-Observations). Architektur umsetzen: Anzahl Attention-Heads, Embedding-Dimension, Positional Encoding für Ray-Sensor-Daten, Feed-Forward-Dimensionen. |
| 7.2 | Transformer-Training auf den fünf Maps | Training des Transformer-Agenten auf allen fünf Trainingsmaps durchführen. TensorBoard-Metriken loggen (Reward, Erfolgsrate, Episodenlänge) und mit dem ersten MLP-Training aus Milestone 5 vergleichen. Hyperparameter iterativ anpassen. |

---

## Milestone 8 — MLP-Baseline, Modellvergleich & Ablationsstudie

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 8.1 | MLP-Baseline formalisieren | Das Standard-MLP aus ML-Agents (oder dem gewählten Framework) als offizielle Baseline definieren. Gleiche Trainings-Maps, gleiche Hyperparameter-Suche, gleiche Episodenanzahl wie beim Transformer sicherstellen, damit ein fairer Vergleich möglich ist. |
| 8.2 | Vergleichsmetriken erheben | Einheitliches Evaluationsprotokoll (definiert in 6.4) durchführen: kumulative Reward-Kurven, Erfolgsrate (% Ziel erreicht), durchschnittliche Episodenlänge, Konvergenzgeschwindigkeit. Ergebnisse beider Modelle tabellarisch und grafisch gegenüberstellen. |
| 8.3 | Ablationsstudie(n) durchführen | Die in 6.2 ausgewählte(n) Ablationsstudie(n) durchführen. Ergebnisse systematisch dokumentieren, um den Beitrag einzelner Komponenten zu quantifizieren (z. B. Attention-Layer, Sensordichte, Reward-Shaping). |

---

## Milestone 9 — Generalisierungstest

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 9.1 | Unbekannte Test-Map(s) erstellen | Mindestens eine komplett neue Map entwerfen, die im Training nie verwendet wurde. Die Map soll bekannte Hindernistypen (Lava, Löcher, Sackgassen) in neuer Anordnung und Kombination enthalten. |
| 9.2 | Beide Modelle auf unbekannter Map evaluieren | Sowohl das Transformer-Modell als auch die MLP-Baseline ohne erneutes Training auf der unbekannten Map testen. Erfolgsrate, Reward und Episodenlänge messen. |
| 9.3 | Generalisierungsergebnisse auswerten | Ergebnisse analysieren: Zeigen die Modelle gelerntes Verhalten (Hindernisvermeidung, Sprungentscheidung) statt auswendig gelernte Pfade? Unterschiede zwischen Transformer und MLP in der Generalisierungsfähigkeit herausarbeiten. |

---

## Milestone 10 — Beobachtbarkeit & Reproduzierbarkeit

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 10.1 | Live-Viewer oder Replay-System umsetzen | Basierend auf der Entscheidung aus 6.3: Entweder einen Live-Viewer in Unity (Kamera-Verfolgung des Agenten während Training/Inference) oder ein Replay-System (Episoden aufzeichnen und nachträglich abspielen) implementieren. |
| 10.2 | TensorBoard-Dashboard finalisieren | Sicherstellen, dass alle Pflichtmetriken sauber geloggt werden: kumulativer Reward pro Episode, Erfolgsrate (Ziel erreicht vs. Tod vs. Timeout), durchschnittliche Episodenlänge. Optional: Heatmaps der Agentenbewegung pro Map. |
| 10.3 | Git-Repository aufsetzen & pflegen | Reproduzierbares Git-Repository anlegen mit: vollständigem Quellcode, Trainings-Konfigurationen (YAML), README mit Setup-Anleitung, Requirements/Dependencies, Seed-Konfiguration für deterministische Reproduzierbarkeit und trainierten Modell-Checkpoints (oder Anleitung zum Nachtrainieren). |

---

## Milestone 11 — Erweiterungen: Auswahl, Evaluierung & Analyse

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 11.1 | Erweiterungskandidaten recherchieren & priorisieren | Mögliche Erweiterungen systematisch bewerten und nach Machbarkeit, Aufwand und wissenschaftlichem Mehrwert priorisieren. Kandidaten umfassen u. a.: dynamische Hindernisse (ausfahrende Stacheln, sich bewegende Elemente), Brücken (nur per Sprung nutzbar), interaktive Mechaniken (Türen mit Knopfdruck), Sammelobjekte (Sterne zur Zeitstrafen-Reduktion), weitere Ablationsstudien (Curriculum Learning, Sensorik-Konfigurationen, Ego- vs. Gott-Perspektive), Erhöhung der Map-Anzahl oder prozedurale Map-Generierung, Multi-Agent-Setup (kooperative Labyrinth-Lösung). Begründete Auswahl von mindestens einer Erweiterung dokumentieren. |
| 11.2 | Ausgewählte Erweiterung(en) implementieren | Die priorisierten Erweiterungen in die bestehende Umgebung integrieren: Prefabs, Kollisionslogik, ggf. Reward-Anpassungen und Sensor-Erweiterungen umsetzen. Erneutes Training mit den Erweiterungen durchführen. |
| 11.3 | Auswirkungen analysieren & dokumentieren | Ergebnisse des Trainings mit Erweiterungen mit den Baseline-Ergebnissen (ohne Erweiterungen) vergleichen. Dokumentieren, wie sich die Erweiterungen auf Lernverhalten, Erfolgsrate und Generalisierung auswirken. Nicht umgesetzte Kandidaten als Ausblick für zukünftige Arbeit festhalten. |

---

## Milestone 12 — Schriftlicher Bericht & Video-Demos

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 12.1 | Schriftlichen Bericht verfassen | Studienbericht schreiben mit: Einleitung & Problemstellung, Recherche-Ergebnisse und Architekturentscheidungen (Transformer vs. MLP, Sensorik, Reward-Design), Trainingsmethodik, Ergebnisse des Modellvergleichs, Ablationsstudie, Generalisierungstest, Erweiterungen, Fazit und Ausblick. |
| 12.2 | Video-Demos erstellen | Mindestens zwei Video-Demos produzieren: (1) Lernphase — Ausschnitte aus dem Training, die den Fortschritt des Agenten über die Episoden zeigen (frühes zufälliges Verhalten → gelerntes Navigieren). (2) Finale Läufe — den trainierten Agenten auf bekannten und der unbekannten Map zeigen, inklusive Hindernisüberwindung. |
| 12.3 | Repository & Abgabe finalisieren | Git-Repository aufräumen (Branching bereinigen, README prüfen, Lizenzen), Bericht und Videos verlinken bzw. beilegen, und finalen Stand als Release taggen. |

---