# Projekt-Roadmap: KI-Agent zur Labyrinth-Navigation
---------konzeptionelle Roadmap, soll ausdrücklich on the go überarbeitet werden------------------

**Team:** Finn Ludwig, Ekaterina Karavaeva, David Pelcz, Alexander Bernecker

Diese Roadmap beschreibt den Ablauf des Projekts in Milestones. Jeder Milestone baut auf dem vorherigen auf und enthält konkrete Zwischenziele mit kurzer Beschreibung.

---

## Änderungshistorie

| Version | Datum       | Änderung                                                                                                       | Begründung                                                                                                           |
|---------|-------------|----------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|
| 1.0     | 2026-03-15  | Ursprüngliche Roadmap mit M1–M12 (MLP-Baseline, Transformer, Generalisierungstest, Erweiterungen, Bericht).    | Erststand der Projektplanung.                                                                                        |
| 2.0     | 2026-04-17  | M1–M5 als abgeschlossen markiert. M6–M11 komplett neu strukturiert. Alte M7–M12 in Archiv-Abschnitt verschoben. | Team hat sich für eine **Ablationsstudie** entschieden und die Meilensteinstruktur dafür auf GitHub neu aufgesetzt.  |

**Hinweis zur Version 2.0:** Die ursprüngliche Struktur (MLP-Baseline → Transformer → Generalisierungstest → Erweiterungen → Bericht) wurde aufgebrochen, um eine systematische Ablationsstudie über sechs Agentenvarianten (A1–A6) zu ermöglichen. Der neue Fokus liegt auf dem Vergleich von LSTM- und Transformer-Recurrence, mit und ohne CNN-basierten Kamerasensor, inklusive Multi-Sensor Fusion. Alte Meilensteine, die durch die Neustrukturierung abgelöst wurden, bleiben im Archiv-Abschnitt zur Nachvollziehbarkeit erhalten.

---

## Milestone 1 — Projektstruktur & Map-Grundsystem ✅ abgeschlossen

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 1.1 | Projektstruktur anlegen | Ordnerstruktur (Scripts/Map, Prefabs/Map, Scenes/Training) erstellen und ein zentrales MapRoot-GameObject in der Trainingsszene einrichten. |
| 1.2 | Map-Datenmodell & Generator | Grid-basiertes Datenmodell definieren (Zelltypen: Boden, Wand, Hindernis, Ziel, Spawn) und das Map-Generator-Script erstellen, das dieses Modell in GameObjects übersetzt. |
| 1.3 | Prefabs & Positionierung | Für jeden Zelltyp ein Prefab erstellen, Inspector-Referenzen im Generator anlegen und die Grid-zu-Welt-Koordinaten-Umrechnung implementieren. |
| 1.4 | Map-Erzeugung & Reset | Automatische Map-Generierung beim Szenenstart einbauen sowie eine Reset-Funktion, die alle Map-Objekte löscht und neu erzeugt. |

---

## Milestone 2 — Mehrere Maps & Sensorvorbereitung ✅ abgeschlossen

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 2.1 | Tag-System & Sensorvorbereitung | Tags (Wall, Obstacle, Goal) im Tag Manager anlegen und alle Prefabs mit passenden Collidern und Tags versehen, damit Ray-Sensoren sie erkennen können. |
| 2.2 | Mehrere Map-Layouts erstellen | Fünf unterschiedliche Map-Layouts definieren, die sich in Wandplatzierung, Hindernissen, Ziel- und Spawnposition sowie Offenheit unterscheiden. |
| 2.3 | Map-Auswahl & Rotation | Auswahlmechanismus implementieren (fest oder zufällig) und den Reset so erweitern, dass bei jeder Episode ein anderes Layout geladen wird. |
| 2.4 | Testszene & Validierung | Testszene einrichten, die alle fünf Maps durchläuft und korrekte Positionierung, Hierarchy, Tags und Collider überprüft. |

---

## Milestone 3 — Agent-Grundsystem ✅ abgeschlossen

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 3.1 | Agent-GameObject erstellen | Agent als ML-Agents-Agent konfigurieren mit Bewegungssteuerung (vorwärts, rückwärts, links, rechts) und physikbasierter Sprungmechanik. |
| 3.2 | Sensorik implementieren | Ray-basierte Sensoren einrichten, die über das Tag-System Wände, Hindernisse, Lava, Löcher und das Zielobjekt unterscheiden können. |
| 3.3 | Spawnpunkt-Integration | Agent-Spawn an das Map-Datenmodell koppeln, sodass der Agent bei jeder Episode am definierten Spawnpunkt der jeweiligen Map erscheint. |

---

## Milestone 4 — Hindernisse & Interaktion ✅ abgeschlossen

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 4.1 | Basis-Hindernisse umsetzen | Lavafelder (überspringbar, tödlich), Löcher/Abgründe (tödlich, nicht passierbar) und Sackgassen als Prefabs mit Kollisionslogik bauen. |
| 4.2 | Todeslogik & Episode-Reset | Kollisionserkennung mit tödlichen Feldern implementieren, die eine Episode sofort beendet und den Agenten zurücksetzt. |

---

## Milestone 5 — Reward-System & Training ✅ abgeschlossen

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 5.1 | Belohnungsstrategie umsetzen | Reward-Logik definieren: starke Belohnung fürs Ziel, Bestrafung für Lava/Löcher/Zeitlimit, neutrale bis leichte Belohnung für Hindernisüberwindung. |
| 5.2 | Trainingsumgebung konfigurieren | ML-Agents YAML-Konfiguration erstellen (Hyperparameter, Netzwerk, max Steps) und Multi-Agent-Setup ermöglichen. |
| 5.3 | Erstes Training & Iteration | Trainingsdurchläufe auf den fünf Maps starten, TensorBoard überwachen, Reward-Kurven analysieren und Parameter iterativ anpassen. |

---

## Milestone 6 — Orga 🟡 aktiv (2 open, 4 closed)

| Nr.  | Issue | Titel |
|------|-------|-------|
| 6.3  | #112  | M6.3 Evaluationsprotokoll & Reproduzierbarkeits-Framework definieren |
| 6.3  | #49   | 6.3 Evaluations- & Beobachtbarkeitssystem recherchieren |

---

## Milestone 7 — Transformer-Architektur & Ray-Agenten 🟡 aktiv (3 open)

| Nr.  | Issue | Titel |
|------|-------|-------|
| 7.1  | #113  | M7.1 Custom Transformer Policy implementieren (BufferSensor + PyTorch) |
| 7.2  | #114  | M7.2 Ray-Agenten trainieren: LSTM (A3) & Transformer (A4) |
| 7.3  | #115  | M7.3 Zwischenauswertung: Agent 3 (LSTM) vs. Agent 4 (Transformer) |

---

## Milestone 8 — Kamerasensor-Integration 🟡 aktiv (2 open)

| Nr.  | Issue | Titel |
|------|-------|-------|
| 8.1  | #116  | M8.1 CameraSensor in Unity einrichten (Prefab, RenderTexture, Stacking) |
| 8.2  | #117  | M8.2 Kamera-Agenten initial trainieren & CNN-Funktion verifizieren (A1, A2) |

---

## Milestone 9 — CNN-Architektur & Kamera-Agenten 🟡 aktiv (3 open)

| Nr.  | Issue | Titel |
|------|-------|-------|
| 9.1  | #118  | M9.1 Custom CNN Policy implementieren (PyTorch, ONNX-Export) |
| 9.2  | #119  | M9.2 Kamera-Agenten vollständig trainieren: CNN+LSTM (A1) & CNN+Transformer (A2) |
| 9.3  | #120  | M9.3 Auswertung: Agent 1 (CNN+LSTM) vs. Agent 2 (CNN+Transformer) |

---

## Milestone 10 — Multi-Sensor Fusion & Trainingsmatrix 🟡 aktiv (3 open)

| Nr.   | Issue | Titel |
|-------|-------|-------|
| 10.1  | #121  | M10.1 Multi-Sensor Fusion Architektur implementieren (Kamera + Ray → Latent-Raum) |
| 10.2  | #122  | M10.2 Multi-Sensor Agenten trainieren: CNN+LSTM (A6) & CNN+Transformer (A5) |
| 10.3  | #123  | M10.3 Vollständige Trainingsmatrix abschließen & Daten-Konsistenz prüfen |

---

## Milestone 11 — Wissenschaftliche Auswertung & Dokumentation 🟡 aktiv (4 open)

| Nr.   | Issue | Titel |
|-------|-------|-------|
| 11.1  | #124  | M11.1 Quantitative Auswertung aller Agenten nach Evaluationsprotokoll (M6.3) |
| 11.2  | #125  | M11.2 Real-World-Transfer-Analyse: Labyrinth → Serviceroboter |
| 11.3  | #126  | M11.3 Wissenschaftlichen Abschlussbericht verfassen & Repository finalisieren |
| –     | #109  | Verständnis TensorBoard |

---

**Kernziel des Projekts:** Labyrinth-Navigation mit KI-Agenten — von einfachen MLP/LSTM-Baselinen über Transformer-Architekturen bis hin zu CNN-basierten Kamera-Agenten mit Multi-Sensor Fusion. Abschluss mit wissenschaftlicher Auswertung und Real-World-Transfer-Analyse.

---

## Archiv — Stillgelegte / umstrukturierte Meilensteine

Die folgenden Meilensteine aus Version 1.0 der Roadmap wurden auf GitHub geschlossen und durch die neue Struktur (M6–M11 in Version 2.0) ersetzt. Einige zugehörige Issues sind jedoch noch offen und werden ggf. in die neuen Meilensteine überführt. Dieser Abschnitt dient der Nachvollziehbarkeit der Umstrukturierung.

| Alter Meilenstein | Alter Titel                                              | Noch offene Issues |
|-------------------|----------------------------------------------------------|--------------------|
| M7 (alt)          | Transformer-Modell Entwurf                               | #65, #67           |
| M8 (alt)          | MLP-Baseline, Modellvergleich & Ablationsstudie          | #51, #52, #53      |
| M9 (alt)          | Generalisierungstest                                     | #68, #70, #72      |
| M10 (alt)         | Beobachtbarkeit & Reproduzierbarkeit                     | #54, #55, #56      |
| M11 (alt)         | Erweiterungen                                            | #75, #76, #78      |
| M12 (alt)         | Schriftlicher Bericht & Video-Demos                      | #57, #58, #59      |

---
