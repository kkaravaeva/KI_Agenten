# Projekt-Roadmap: KI-Agent zur Labyrinth-Navigation
---------konzeptionelle Roadmap, soll ausdrücklich on the go überarbeitet werden------------------

**Team:** Finn Ludwig, Ekaterina Karavaeva, David Pelcz, Alexander Bernecker

Diese Roadmap beschreibt den chronologischen Ablauf des Projekts in sechs Phasen. Jede Phase baut auf der vorherigen auf und enthält konkrete Zwischenziele mit kurzer Beschreibung.

---

## Phase 1 — Projektstruktur & Map-Grundsystem

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 1.1 | Projektstruktur anlegen | Ordnerstruktur (Scripts/Map, Prefabs/Map, Scenes/Training) erstellen und ein zentrales MapRoot-GameObject in der Trainingsszene einrichten. |
| 1.2 | Map-Datenmodell & Generator | Grid-basiertes Datenmodell definieren (Zelltypen: Boden, Wand, Hindernis, Ziel, Spawn) und das Map-Generator-Script erstellen, das dieses Modell in GameObjects übersetzt. |
| 1.3 | Prefabs & Positionierung | Für jeden Zelltyp ein Prefab erstellen, Inspector-Referenzen im Generator anlegen und die Grid-zu-Welt-Koordinaten-Umrechnung implementieren. |
| 1.4 | Map-Erzeugung & Reset | Automatische Map-Generierung beim Szenenstart einbauen sowie eine Reset-Funktion, die alle Map-Objekte löscht und neu erzeugt. |

---

## Phase 2 — Mehrere Maps & Sensorvorbereitung

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 2.1 | Tag-System & Sensorvorbereitung | Tags (Wall, Obstacle, Goal) im Tag Manager anlegen und alle Prefabs mit passenden Collidern und Tags versehen, damit Ray-Sensoren sie erkennen können. |
| 2.2 | Mehrere Map-Layouts erstellen | Fünf unterschiedliche Map-Layouts definieren, die sich in Wandplatzierung, Hindernissen, Ziel- und Spawnposition sowie Offenheit unterscheiden. |
| 2.3 | Map-Auswahl & Rotation | Auswahlmechanismus implementieren (fest oder zufällig) und den Reset so erweitern, dass bei jeder Episode ein anderes Layout geladen wird. |
| 2.4 | Testszene & Validierung | Testszene einrichten, die alle fünf Maps durchläuft und korrekte Positionierung, Hierarchy, Tags und Collider überprüft. |

---

## Phase 3 — Agent-Grundsystem

| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 3.1 | Agent-GameObject erstellen | Agent als ML-Agents-Agent konfigurieren mit Bewegungssteuerung (vorwärts, rückwärts, links, rechts) und physikbasierter Sprungmechanik. |
| 3.2 | Sensorik implementieren | Ray-basierte Sensoren einrichten, die über das Tag-System Wände, Hindernisse, Lava, Löcher und das Zielobjekt unterscheiden können. |
| 3.3 | Spawnpunkt-Integration | Agent-Spawn an das Map-Datenmodell koppeln, sodass der Agent bei jeder Episode am definierten Spawnpunkt der jeweiligen Map erscheint. |

---

## Phase 4 — Hindernisse & Interaktion


| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 4.1 | Basis-Hindernisse umsetzen | Lavafelder (überspringbar, tödlich), Löcher/Abgründe (tödlich, nicht passierbar) und Sackgassen als Prefabs mit Kollisionslogik bauen. |
| 4.2 | Brücken-Mechanik | Große Lava-/Loch-Bereiche mit Brücken erstellen, die nur durch gezielten Sprung passierbar sind. |
| 4.3 | Todeslogik & Episode-Reset | Kollisionserkennung mit tödlichen Feldern implementieren, die eine Episode sofort beendet und den Agenten zurücksetzt. |

---

## Phase 5 — Reward-System & Training


| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 5.1 | Belohnungsstrategie umsetzen | Reward-Logik definieren: starke Belohnung fürs Ziel, Bestrafung für Lava/Löcher/Zeitlimit, neutrale bis leichte Belohnung für Hindernisüberwindung. |
| 5.2 | Trainingsumgebung konfigurieren | ML-Agents YAML-Konfiguration erstellen (Hyperparameter, Netzwerk, max Steps) und Multi-Agent-Setup ermöglichen. |
| 5.3 | Erstes Training & Iteration | Trainingsdurchläufe auf den fünf Maps starten, TensorBoard überwachen, Reward-Kurven analysieren und Parameter iterativ anpassen. |

---

## Phase 6 — Erweiterung & Generalisierung


| Nr. | Zwischenziel | Beschreibung |
|-----|-------------|--------------|
| 6.1 | Erweiterte Hindernisse (optional) | Dynamische Elemente wie ausfahrende Stacheln, Türen mit Knopfdruck und Sammelobjekte (Sterne zur Zeitstrafen-Reduktion) ergänzen. |
| 6.2 | Generalisierungstest | Agenten auf komplett neuen, nicht trainierten Maps testen, um Transfer des gelernten Verhaltens statt Auswendiglernen zu validieren. |
| 6.3 | Feinschliff & Dokumentation | Reward-Balancing finalisieren, Edge Cases beheben und Projekt-Dokumentation sowie Ergebnisse zusammenfassen. |