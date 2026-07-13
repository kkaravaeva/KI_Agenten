#import "dhbw.typ": *
#import "appendix.typ": appendix
#import "abstract.typ": abstract
#import "acronyms.typ": acronyms

#show: dhbw.with(
  title: "Navigation von KI Agenten in einer 3D Welt",
  authors: (
    (name: "Finn Ludwig, Ekaterina Karavaeva, Alexander Bernecker, David Pelcz", student-id: "1437019, 6994562, 3732555, 6083851 ", course: "TIT23", course-of-studies: "Informationstechnik"),
  ),


  language: "de", // en, de
  at-dhbw: true, // true: kein Firmenname auf Titelseite, keine Vertraulichkeitserklärung
  show-confidentiality-statement: false,
  show-declaration-of-authorship: true,
  show-table-of-contents: true,
  show-acronyms: true,
  show-list-of-figures: true,
  show-list-of-tables: true,
  show-code-snippets: false,
  show-appendix: true,
  show-abstract: false,
  show-header: true,
  show-student-id: true,
  numbering-style: "1 von 1",
  numbering-alignment: center,
  abstract: abstract,
  appendix: appendix,
  acronyms: acronyms,
  university: "Dualen Hochschule Baden-Württemberg",
  university-location: "Ravensburg Campus Friedrichshafen",
  supervisor: "Dr. Jochen Heistermann",
  date: datetime.today(),
  bibliography: bibliography("sources.bib"),
  logo-left: image("assets/logos/dhbw.svg"),  logo-size-ratio: "2:1" // ratio between the right logo and the left logo height (left-logo:right-logo) only the right logo is resized
)




// ============================================================================
// HINWEIS: Dies ist ein erster Entwurf einer Inhaltsverzeichnis-Struktur,
// basierend auf dem aktuellen Projektstand (Stand: Milestone 7, ~Mai 2026).
// Quellen:
//   - AktuellerStand_KIArbeitshilfe.md (Gesamt-Entwicklungsstand)
//   - Forschungsplan_M6_M11.md (wissenschaftliche Rahmung)
//   - Strategie/Projekt_inhalt.md (Forschungsfrage, Scope)
//   - Dokumentation/Reward_Strategie.md
//   - Dokumentation/Transformer_Integration.md
//   - Dokumentation/LSTM_Integration.md
//   - Dokumentation/Prozedurale_Map_Generierung.md
//   - Dokumentation/Trainingsanalyse_Transformer_Milestone7.md
//   - Dokumentation/Architektur.md, ArtenSensoren.md, MlAgents.md, Actor_Critic_mit_PPO.md
// ============================================================================


// ============================================================================
// 1. EINLEITUNG
// ============================================================================


// - Kurze Übersicht der Kapitel
/*
#pagebreak()

// ############################################################################
// ############################################################################
// ##                                                                        ##
// ##   NEUSTRUKTURIERUNG (Entwurf 2) — narrativ entlang der Kausalkette      ##
// ##   Restaurant -> Abstraktion -> Generalisierung -> Messbarkeit ->       ##
// ##   Engine -> Sensorik -> Verarbeitung -> Gedächtnis -> LSTM/Transf.    ##
// ##                                                                        ##
// ##   HINWEIS: Dieser Block dupliziert die Kapitel-Überschriften von      ##
// ##   oben. Nach dem Review den ALTEN Block (oben) lschen, damit das     ##
// ##   Dokument nur EINE Gliederung enthält.                               ##
// ##                                                                        ##
// ############################################################################
// ############################################################################


// ----------------------------------------------------------------------------
// MIGRATIONS-KARTE  —  welcher Inhalt aus der ALTEN Struktur wohin wandert
// (Quelle = altes Kapitel oben im File  ->  Ziel = neues Kapitel unten)
// ----------------------------------------------------------------------------
//
// --- EINLEITUNG ---
// ALT 1 "Motivation und Kontext"          -> SPLIT auf mehrere neue Abschnitte:
//        · Serviceroboter/Einsatzkontext   -> NEU 1.1 (Ausgangsszenario)
//        · reale Umgebung -> Abstraktion    -> NEU 1.2 (+ Analogie-Tab. aus ALT 9.1)
//        · Generalisierung als Anforderung  -> NEU 1.3
//        · Forschungslücke/Arch.-Vergleich -> NEU 1.5
//        · (Messbarkeits-Argument NEU 1.4 ist neu, aus Generalisierungs-Inhalt)
// ALT 1 "Problemstellung/Forschungsfrage" -> NEU 1.5 (F1-F3, H1-H3)
// ALT 1 "Zielsetzung und Abgrenzung"      -> NEU 1.6 (1:1)
// ALT 1 "Aufbau der Arbeit"               -> NEU 1.7 (1:1)
//
// --- GRUNDLAGEN (bleibt Kapitel 2, nur Reihenfolge/Rahmung) ---
// ALT 2 "ML und Reinforcement Learning"   -> NEU 2.1 (1:1)
// ALT 2 "Proximal Policy Optimization"    -> NEU 2.2 (1:1)
// ALT 2 "Wahrnehmung in RL-Agenten"       -> NEU 2.3 (VORGEZOGEN vor Sequenzmodell.)
//        (die Sensor-Substanz speist zusätzlich die Entscheidung in NEU 4.4)
// ALT 2 "Sequenzmodellierung für RL"     -> NEU 2.4
//        · LSTM-Unterkapitel                -> NEU 2.4.2
//        · Transformer-Unterkapitel         -> NEU 2.4.3
//        · (Gedächtnisproblem NEU 2.4.1 ist neu/kurz, Motivation auch in 1.5)
// ALT 2 "Unity ML-Agents Toolkit"         -> NEU 2.5 (1:1)
//
// --- STAND DER TECHNIK ---
// ALT 3 "Stand der Technik"               -> NEU 3 (1:1)
//
// --- ACHTUNG: METHODIK (alt 4) und SYSTEMARCHITEKTUR (alt 5) TAUSCHEN ---
// ALT 5 "Gesamtüberblick"                -> NEU 4.1
// ALT 5 "Map-System / Datenmodell"        -> NEU 4.2.1
// ALT 5 "Map-System / MapGenerator"       -> NEU 4.2.2
// ALT 5 "Prozedurale Map-Generierung"     -> NEU 4.2.3 (UMGERAHMT: Rückgriff 1.4,
//                                            "Umsetzung der Messbarkeitsbedingung")
// ALT 5 "Agent-System" (alle Unterpunkte) -> NEU 4.3
// ALT 5 "Sensorik"                        -> NEU 4.4 (+ explizite Wahl "warum Ray")
// ALT 5 "Reward-System"                   -> NEU 4.5 (1:1)
// ALT 5 "Trainingsinfrastruktur"          -> NEU 4.6 (1:1)
//
// ALT 4 "Wissenschaftliche Rahmung"       -> NEU 5.1
// ALT 4 "Agenten-Matrix/Vergleichsdesign" -> NEU 5.2
// ALT 4 "Kontrollierte Variablen"         -> NEU 5.3 (Vorspann + 5.3.1)
//        (NEU 5.3.2 "Notwendige YAML-Abweichungen" ist ZUSATZ, Quelle:
//         02_Anforderungen_Fairer_Vergleich.md, Abschnitt A.2)
// ALT 4 "Evaluationsprotokoll"            -> NEU 5.4 (Primär/General./Statistik)
//
// --- MODELLARCHITEKTUREN ---
// ALT 6 "MLP / LSTM / Transformer / Geplante" -> NEU 6.1 / 6.2 / 6.3 / 6.4
//        ACHTUNG: der Bau-/Debugging-PROZESS des Transformers wandert nach
//        NEU 7.6, in 6.3 bleibt nur die statische ARCHITEKTUR-Beschreibung.
//
// --- UMSETZUNG ---
// ALT 7 "Milestones 1-2 / 3 / 4 / 5 / 6"  -> NEU 7.1 / 7.2 / 7.3 / 7.4 / 7.5 (1:1)
// ALT 7 "Milestone 7: Transformer-/LSTM-Integration" -> AUFTEILEN:
//        · Transformer-Teil + "Iterative Fehlerdiagnose" (Bug 1-5)
//                                           -> NEU 7.6, nach PROBLEMKLASSEN sortiert
//                                              (7.6.1 Patch, 7.6.2 A, 7.6.3 B, 7.6.4 C)
//        · LSTM-Teil                        -> NEU 7.7 (bewusst knapp)
// ALT 7 "Trainings-Iterationen V5-V13"    -> NEU 7.6.5 (verdichtete Tabelle,
//                                            erweitert bis V22, Detail -> Anhang)
//
// --- EVALUATION (nur FINALE Ergebnisse, keine Doppelung mit 7.6) ---
// ALT 8 "MLP-Baseline"                    -> NEU 8.1
// ALT 8 "Transformer-/LSTM-Iterationen"   -> WICHTIG: der ITERATIONS-VERLAUF
//        (Reward-Kurven V5-V13, Diagnose) gehrt nach NEU 7.6, NICHT hierher.
//        In Kap. 8 bleiben nur die abschliessenden Vergleichszahlen.
// ALT 8 "Paarweise Architektur-Vergleiche" -> NEU 8.2
// ALT 8 "Generalisierung held-out Maps"   -> NEU 8.3
// ALT 8 "Statistische Auswertung"         -> NEU 8.4
// ALT 8 "Diskussion"                      -> NEU 8.5
//
// --- ÜBERTRAGBARKEIT ---
// ALT 9 "Analogie Labyrinth <-> real"     -> ZWEIGETEILT:
//        · die Analogie-Tabelle/Rahmung     -> nach vorn zu NEU 1.2
//        · die praktische Auswertung         -> bleibt NEU 9.1
// ALT 9 "Hardware-/Software-Anforderungen" -> NEU 9.2 (1:1)
// ALT 9 "Bewertungsmatrix"                -> NEU 9.3 (1:1)
// ALT 9 "Limitationen der Übertragbarkeit"-> NEU 9.4 (1:1)
//
// --- FAZIT ---
// ALT 10 (alle Unterpunkte)               -> NEU 10.1-10.4 (1:1)
//
// --- ANHANG ---
// ALT Anhang                              -> NEU Anhang, ZUSÃ„TZLICH:
//        · YAML-Basis + markierte Abweichungen (stützt NEU 5.3.2)
//        · vollständige Iterationstabelle V1-V22 m. TensorBoard (stützt 7.6.5)
// ----------------------------------------------------------------------------


// ============================================================================
// 1. EINLEITUNG  — Kausalkette als roter Faden
//DAVID ============================================================================

// 2. THEORETISCHE GRUNDLAGEN  — als Werkzeugkasten, geordnet nach den Fragen
//DAVID ============================================================================

/*= Theoretische Grundlagen

== Maschinelles Lernen und Reinforcement Learning

// - Einordnung KI ⊃ ML ⊃ RL, supervised / unsupervised / reinforcement
// - Markov-Entscheidungsprozesse (MDP), Policy, Value-/Q-Function
// - On-Policy vs. Off-Policy

== Proximal Policy Optimization (PPO)

// - Actor-Critic-Framework (Actor-Netz + Critic-Netz)
// - Schulman et al. (2017): Clipping (ε = 0.2), GAE (λ = 0.95)
// - Vorteil ggue. Vanilla Policy Gradient (Stabilität)

== Wahrnehmung in RL-Agenten

// - Sensortypen als HINTERGRUND: Ray-Sensoren, Kamera (CNN), Vector-Observations
//   (Kamera nur theoretische Einordnung — wird NICHT empirisch untersucht,
//   keine Vergleichserwartung aufbauen)
// - Beobachtungsraeume und Normalisierung
// - Abschnitt läuft auf die Begründung der Ray-Wahl in 4.4 zu
//   (liefert die Substanz für diese Entscheidung, nicht für einen Vergleich)

== Sequenzmodellierung und Gedächtnis in RL

=== Das Gedächtnisproblem reaktiver Agenten

// - TRAGENDES ARGUMENT 2 (KURZ, konzeptionell, 1 Absatz):
//   Ein gedächtnisloser Agent kann nicht wissen, aus welcher Richtung er
//   kam -> reaktives Anlaufen gegen die nächste Wand in Sackgassen
// - Motiviert, warum überhaupt sequenzfähige Architekturen ntig sind
// - Querverweis auf 1.5 (Frage) und 7.6.4 (empirischer Beleg)

=== Long Short-Term Memory (LSTM)

// - Hochreiter & Schmidhuber (1997), Forget-/Input-/Output-Gates
// - Implizites Gedächtnis ohne expliziten Sequenz-Buffer
// - In ML-Agents standardmäßig verfügbar (network_settings.memory: memory_size,
//   sequence_length, use_recurrent ist Alt-Syntax)

=== Transformer-Architektur

// - Vaswani et al. (2017), Self-/Multi-Head-Attention, Positional Encoding
// - RL-Kontext: Decision Transformer (Chen 2021), GTrXL (Parisotto 2019)
// - Vor-/Nachteile ggue. LSTM NEUTRAL beschreiben (keine Wertung vorwegnehmen)

== Unity ML-Agents Toolkit

// - Architektur: Unity-Environment <-> Python-Trainer (gRPC)
// - Komponenten: Agent, Behavior Parameters, Decision Requester, Sensoren
// - Workflow: YAML-Config, ONNX-Export, TensorBoard, Version 0.30.0

*/
// ============================================================================
*/

*KI Hinweis*

Im Rahmen der vorliegenden Studienarbeit wurden KI-basierte Werkzeuge eingesetzt. Deren Nutzung war durch die Aufgabenstellung ausdrücklich gestattet und intendiert, ein erklärtes Lernziel bestand darin, Künstliche Intelligenz zur Förderung der eigenen fachlichen Fähigkeiten heranzuziehen. KI-basierte Werkzeuge kamen dabei ausschließlich als Hilfsmittel im Sinne der geltenden Regelungen der DHBW zum Einsatz und wurden weder als zitierfähige Quelle noch als Urheber herangezogen. Die wesentliche gedankliche und gestalterische Leistung, sowohl hinsichtlich der Dokumentation als auch der Umsetzung, wurde eigenständig erbracht, die Erstellung der Prüfungsleistung wurde nicht im Wesentlichen auf KI-basierte Werkzeuge übertragen. Art und Umfang des Einsatzes werden nachfolgend transparent dokumentiert. Die inhaltliche Verantwortung für die gesamte Arbeit einschließlich der mithilfe von KI erstellten Bestandteile verbleibt vollumfänglich bei den Verfassern.

#table(
  columns: (auto, 1fr),
  inset: 8pt,
  align: (left + top, left + top),
  stroke: 0.5pt,
  table.header(
    [*Werkzeug*], [*Beschreibung der Nutzung*],
  ),
  [Claude],
  [
    *Projektplanung*
    - Vorschläge zu Vorgehen und Startpunkten bei einem großen Projekt (Kapitel …)
    - Information darüber, welche bestehenden Lösungen/Werkzeuge nachgenutzt werden können (Kapitel …)

    *Entwicklung und Debugging*
    - Unterstützung beim Entwickeln, unter anderem Debugging und Fehlersuche in den einzelnen Iterationsschritten der KI-Modelle (Transformer, LSTM) (Kapitel …)

    *Training*
    - Starten und Überwachen von Trainingsläufen sowie Analyse der Trainingswerte, die daraus abgeleiteten Entscheidungen wurden von uns selbst getroffen (Kapitel …)

    *Dokumentation*
    - Korrektur von Rechtschreibfehlern (gesamt)
    - Verbesserung von Struktur und Reduktion von Wiederholungen (gesamt)
    - Gegenprüfung, ob die getroffenen Aussagen tatsächlich auf dem Code basieren (gesamt)
  ],
)
#pagebreak()
= Einleitung

//== Ausgangsszenario: Serviceroboter im Restaurant
== Motivation und Kontext

Autonome Serviceroboter gewinnen in Dienstleistungsbranchen zunehmend an Bedeutung. In der Gastronomie werden sie als Möglichkeit betrachtet, wiederkehrende Service- und Transportaufgaben zu automatisieren sowie Mitarbeitende bei alltäglichen Tätigkeiten zu entlasten. Die Fortschritte in den Bereichen Robotik, Sensorik und künstliche Intelligenz eröffnen dabei neue Möglichkeiten für den praktischen Einsatz intelligenter Systeme @wirtz_brave_2018[S. 9 ff.].

Eine Voraussetzung für den erfolgreichen Einsatz solcher Systeme ist die Fähigkeit zur autonomen Navigation. Ein Serviceroboter muss seine Umgebung wahrnehmen, Hindernisse erkennen und selbstständig Entscheidungen treffen, um ein vorgegebenes Ziel sicher zu erreichen. Im Gegensatz zu klassischen regelbasierten Systemen sollen moderne Roboter dabei flexibel auf Veränderungen ihrer Umgebung reagieren können. Für die Entwicklung solcher Navigationsstrategien hat sich Reinforcement Learning (RL) als vielversprechender Ansatz etabliert. Agenten lernen durch Interaktion mit ihrer Umgebung eigenständig, welche Aktionen langfristig zu einer erfolgreichen Zielerreichung führen @sutton_reinforcement_2018[S. 1 - 8].

Die Untersuchung entsprechender Lernverfahren auf realen Robotersystemen ist jedoch mit erheblichem Aufwand verbunden. Neben den Kosten für Hardware und Sensorik können Fehlentscheidungen während des Trainings zu Beschädigungen der Umgebung oder des Roboters führen. Darüber hinaus sind reale Experimente häufig zeitaufwendig und nur eingeschränkt reproduzierbar. Aus diesem Grund werden neue Verfahren zunächst in Simulationsumgebungen entwickelt und evaluiert @juliani_unity_2020[S. 1 - 6].

Um die für diese Arbeit relevante Navigationsaufgabe systematisch untersuchen zu können, wird die reale Umgebung eines Restaurants in ein abstrahiertes 3D-Labyrinth als Simulationsmodell überführt. Ziel dieser Abstraktion ist nicht die möglichst realitätsnahe Nachbildung eines Restaurants, sondern die Reduktion auf jene Eigenschaften, die für die Navigation eines autonomen Agenten wesentlich sind. Der Agent muss weiterhin Wege finden, Hindernisse vermeiden und ein Ziel erreichen. Gleichzeitig wird die Umgebung so vereinfacht, dass unterschiedliche Lernverfahren unter identischen Bedingungen untersucht und miteinander verglichen werden können.

Die Beziehung zwischen realem Anwendungsszenario und Simulationsmodell ist in @tab_abstraktion dargestellt.

#figure(
  table(
    columns: 2,
    [*Reale Umgebung*], [*Simulationsmodell*],

    [Restaurantgänge und Laufwege], [Korridore des Labyrinths],
    [Tische, Stühle oder blockierte Bereiche], [Hindernisse(Lava- und Hole-Felder)],
    [Zielposition des Serviceroboters], [Zielplattform],
    [Unterschiedliche Restaurantgrundrisse], [Variierende Kartenlayouts],
  ),
  caption: [Zuordnung zwischen realem Anwendungsszenario und Simulationsmodell],
) <tab_abstraktion>

Die Simulationsumgebung bildet damit die Grundlage für die kontrollierte Untersuchung unterschiedlicher Reinforcement-Learning-Ansätze für autonome Navigationsaufgaben.

// - Konkreter Anker: KI-gesteuerte Serviceroboter sollen autonom navigieren
// - Warum ein reales, greifbares Szenario als Ausgangspunkt (statt abstrakt)

//== Von der realen Umgebung zur testbaren Abstraktion
// habs mit claude ausdiskutiert: Warum ich nicht "verschieben" empfehlen würde.Wenn ihr diesen Absatz an eine spätere Stelle schiebt (z. B. nach Problemstellung oder Forschungsfrage, wo "Labyrinth" vielleicht schon fällt), verliert die Motivation ihren konkreten Anker — dann bliebe "abstraktes Simulationsmodell" viel zu lange vage, bevor der Leser überhaupt eine Vorstellung bekommt, wovon die Arbeit handelt. Das wäre ein größerer Rückschritt als der jetzige kleine Vorgriff.
// hab seine Empfehlung unmgesetzt
== Problemstellung

Das erfolgreiche Lösen des vorgestellten Labyrinths allein belegt jedoch noch kein intelligentes Navigationsverhalten. Hohe Erfolgsraten können auch dann erreicht werden, wenn der Agent lediglich spezifische Kartenstrukturen oder Bewegungsabfolgen auswendig lernt. In diesem Fall wäre das erlernte Verhalten eng an die Trainingsumgebung gebunden und nur eingeschränkt auf neue Situationen übertragbar.

//hab den Kommentar umgesetzt. Gefällt es dir so besser?

Für reale Anwendungen ist ein solches Verhalten jedoch unzureichend. Restaurants unterscheiden sich hinsichtlich ihrer Raumaufteilung, der Anordnung von Tischen und Laufwegen sowie möglicher Hindernisse. Darüber hinaus können sich diese Gegebenheiten während des Betriebs verändern. Ein autonomer Serviceroboter muss daher in der Lage sein, bereits erlernte Strategien auf unbekannte Umgebungen anzuwenden, anstatt ausschließlich bekannte Situationen wiederzuerkennen.

Diese Fähigkeit wird als Generalisierung bezeichnet. Im Kontext des Reinforcement Learnings beschreibt Generalisierung die Fähigkeit eines Agenten, auch in Umgebungen erfolgreich zu agieren, die während des Trainings nicht beobachtet wurden. Sie stellt eine zentrale Herausforderung moderner Lernverfahren dar, da eine gute Leistung auf Trainingsdaten nicht automatisch eine gute Leistung auf unbekannten Situationen garantiert @goodfellow_deeplearningbookorgcontentsmlhtml_nodate[S. 111 - 120].

Neben der Generalisierung spielt die Verarbeitung zeitlicher Zusammenhänge eine wichtige Rolle. Während sich einige Navigationsentscheidungen allein auf Basis der aktuellen Wahrnehmung treffen lassen, existieren auch Situationen, in denen Informationen aus vergangenen Beobachtungen relevant werden.

Vor diesem Hintergrund stellt sich die Frage, welchen Einfluss unterschiedliche Netzwerkarchitekturen auf die Fähigkeit eines Reinforcement-Learning-Agenten haben, robuste und übertragbare Navigationsstrategien zu erlernen.

// - Übersetzung realer Umgebung in eine vergleichbare, abstrahierte Welt
//   -> testbar ohne physischen Roboter
// - Analogie-Tabelle: Korridor <-> Gang, Lava <-> Stufe/Kabel,
//   prozedurales Layout <-> veränderliche Umgebung
//   (aus altem Kap. "Übertragbarkeit" nach vorn gezogen)

//== Generalisierung als zentrale Anforderung

// - Jedes Restaurant sieht anders aus -> Agent muss generalisieren,
//   nicht einen Grundriss auswendig lernen
// - Das ist die zentrale Anforderung, nicht bloss Memorierung

== Messbarkeit von Generalisierung <sec:messbarkeit>
Um Generalisierung tatsächlich nachzuweisen, reicht es nicht, die Leistung des Agenten allein auf bekannten Karten zu messen. Nachweisbar wird sie erst, wenn der Agent auf Umgebungen getestet wird, die er während des Trainings nie gesehen hat. Nur so lässt sich zeigen, dass das erlernte Verhalten tatsächlich übertragbar ist und nicht nur die bekannten Karten betrifft. // hab es umformuliert passt es dir so nun besser? 

Aus dieser Anforderung ergibt sich unmittelbar die Notwendigkeit einer Trennung zwischen Trainings- und Testumgebungen. Während Trainingskarten dem Agenten zum Lernen zur Verfügung stehen, dürfen Testkarten während des Trainingsprozesses niemals verwendet werden. Die Generalisierungsfähigkeit eines Agenten kann anschließend anhand seiner Leistung auf diesen zuvor ungesehenen Karten bewertet werden.

Die Erstellung einer ausreichend großen Anzahl voneinander unabhängiger Karten stellt dabei eine weitere Herausforderung dar. Eine manuelle Konstruktion wäre mit erheblichem Aufwand verbunden und würde die Vielfalt möglicher Umgebungen einschränken. Aus diesem Grund wird in dieser Arbeit eine prozedurale Kartengenerierung eingesetzt. Diese ermöglicht die automatische Erzeugung unterschiedlicher Kartenlayouts und damit die systematische Trennung von Trainings- und Testumgebungen.

Die prozedurale Kartengenerierung wird in dieser Arbeit daher nicht als eigenständiges Forschungsziel betrachtet. Sie stellt vielmehr eine notwendige Voraussetzung dar, um die Generalisierungsfähigkeit der untersuchten Agenten objektiv und reproduzierbar messen zu können.

// - TRAGENDES ARGUMENT 1:
//   Generalisierung ist nur nachweisbar auf Layouts, die im Training NIE
//   vorkamen -> setzt systematisch erzeugbare Layouts (prozedurale
//   Map-Generierung) UND ein zurückgehaltenes, ungesehenes Test-Set voraus
// - Map-Generierung ist damit Bedingung der Messbarkeit, kein Feature

== Offene Fragen und Forschungsfrage <sec:forschungsfrage>

Aus der dargestellten Problemstellung ergeben sich mehrere offene Fragestellungen. Zunächst muss untersucht werden, wie Reinforcement-Learning-Agenten innerhalb einer dreidimensionalen Simulationsumgebung implementiert werden können und welche Anforderungen sich daraus für die Gestaltung der Umgebung ergeben.
//Der aktuelle Absatz ist inhaltlich schon richtig aufgestellt — er stellt eine echte, noch offene technische Frage (wie wird das implementiert, welche Anforderungen ergeben sich), ohne etwas vorwegzunehmen, was schon beantwortet ist. Ich würde ihn so lassen, wie er ist, und dem Kollegen das kurz begründen: nicht weil "keine Verbesserung nötig", sondern weil der vorgeschlagene Weg eine Wiederholung einführen würde, die wir gerade erst an anderer Stelle beseitigt haben.

Darüber hinaus stellt sich die Frage, auf welcher Informationsgrundlage der Agent seine Entscheidungen trifft. Damit ein Agent zielgerichtet handeln kann, müssen relevante Eigenschaften der Umgebung erfasst und in einer für das neuronale Netzwerk verarbeitbaren Form bereitgestellt werden. Die konkrete Ausgestaltung der Wahrnehmung beeinflusst maßgeblich, welche Informationen dem Agenten während der Navigation überhaupt zur Verfügung stehen.

Eine weitere offene Fragestellung betrifft die Verarbeitung dieser Informationen. Während einige Navigationssituationen allein anhand der aktuellen Beobachtung lösbar sind, können in komplexeren Labyrinthstrukturen Situationen entstehen, in denen zusätzliche Kontextinformationen benötigt werden. Beispielsweise kann ein Agent in Sackgassen oder an mehrdeutigen Kreuzungen davon profitieren, Informationen aus vergangenen Beobachtungen in seine Entscheidungsfindung einzubeziehen.

Klassische Feed-Forward-Netzwerke treffen ihre Entscheidungen ausschließlich auf Basis der aktuellen Eingabe und verfügen über kein explizites Gedächtnis. Demgegenüber ermöglichen Architekturen wie Long Short-Term Memory Networks (LSTM) oder Transformer-Modelle die Berücksichtigung zeitlicher Zusammenhänge über mehrere Zeitschritte hinweg. Daraus ergibt sich die Vermutung, dass Gedächtnismechanismen insbesondere bei Navigationsaufgaben in partiell beobachtbaren Umgebungen einen Vorteil bieten könnten.

Vor diesem Hintergrund ergibt sich die zentrale Forschungsfrage dieser Arbeit:


"Welche neuronale Netzwerkarchitektur (MLP, LSTM oder Transformer) ist für einen Reinforcement-Learning-Agenten geeignet, um in einer prozedural generierten 3D-Labyrinthwelt generalisierbares Navigations- und Hindernisvermeidungsverhalten zu erlernen, das sich auf unbekannte Kartenlayouts übertragen lässt?"

Zur Beantwortung dieser Forschungsfrage werden die folgenden Teilfragen untersucht:

*F1: Mehrwert temporalen Gedächtnisses*

Verbessert ein temporaler Gedächtnismechanismus in Form eines LSTM- oder Transformer-Modells die Navigationsleistung eines Reinforcement-Learning-Agenten gegenüber einem MLP-Basisagenten ohne lernbares Sequenzgedächtnis?

*F2: Vergleich von LSTM und Transformer*

Welche Unterschiede zeigen LSTM- und Transformer-Architekturen hinsichtlich Lernverhalten, Trainingsdynamik und Leistungsfähigkeit bei der Ray-basierten Navigation in einer Labyrinthumgebung?

*F3: Generalisierung auf unbekannte Kartenlayouts*

Welche der untersuchten Architekturen (MLP, LSTM oder Transformer) generalisiert am zuverlässigsten auf prozedural generierte Karten, die während des Trainings nicht beobachtet wurden?

Die Teilfragen bauen logisch aufeinander auf. Zunächst wird untersucht, ob ein Gedächtnismechanismus für die betrachtete Navigationsaufgabe grundsätzlich einen Mehrwert bietet. Anschließend erfolgt ein direkter Vergleich der beiden Gedächtnisarchitekturen LSTM und Transformer. Abschließend wird analysiert, in welchem Umfang sich die erlernten Strategien auf bislang unbekannte Kartenlayouts übertragen lassen.

Zur Beantwortung der Forschungsfragen werden die folgenden Hypothesen aufgestellt:

*H1:* Agenten mit temporalem Gedächtnis (LSTM oder Transformer) erreichen eine höhere Navigationsleistung als ein MLP-Basisagent ohne lernbares Sequenzgedächtnis.

*H2:* Transformer-Architekturen erzielen eine höhere Endleistung als LSTM-Modelle, benötigen jedoch mehr Trainingsaufwand bis zur Konvergenz.

*H3:* Architekturen mit temporalem Gedächtnis weisen eine höhere Generalisierungsfähigkeit auf als ein MLP-Basisagent und zeigen ein geringeres Maß an Overfitting gegenüber den Trainingskarten.

Die Operationalisierung dieser Forschungsfragen erfolgt in @sec:rahmung, die zur Evaluation verwendeten Metriken und Auswertungsverfahren werden in @sec:evalprotokoll beschrieben.
// erledigt




// - Abgeleitete offene Fragen (in dieser Reihenfolge):
//     (a) Wie lassen sich KI-Agenten in einer 3D-Welt implementieren,
//         welche Herausforderungen bringt die Game-Engine mit?
//     (b) Welche Sensorik bildet reale Wahrnehmung ab -> warum Ray-basiert?
//     (c) Wie verarbeitet der Agent Informationen zu Entscheidungen?
//     (d) Sackgassen: ein gedächtnisloser Agent läuft reaktiv gegen die
//         Wand -> Gedächtnis ntig
// - Hauptforschungsfrage :
//   "Welche neuronale Netzwerkarchitektur (MLP, LSTM oder Transformer) ist
//    für einen RL-Agenten geeignet, um in einer prozedural generierten
//    3D-Labyrinthwelt generalisierbares Navigations- und Hindernis-
//    vermeidungsverhalten zu erlernen, das sich auf unbekannte Map-Layouts
//    übertragen lässt?"
// - Forschungsfragen F1-F3 (Gedächtnis-Mehrwert, LSTM vs. Transformer,
//   Generalisierung), Hypothesen H1-H3, Sensorfragen sind KEINE RQ mehr
//   (-> Ausblick Kap. 10), Übertragbarkeit qualitativ in Kap. 9
// In 1.5 nur die Haupt-Forschungsfrage plus F1-F3 als Fragen formulieren
// Vorwärtsverweis auf 5.1 setzen




== Zielsetzung und Abgrenzung <sec:abgrenzung>

Ziel dieser Arbeit ist die Entwicklung und Evaluation einer Reinforcement-Learning-Umgebung zur Untersuchung generalisierbarer Navigationsstrategien in dreidimensionalen Labyrinthwelten. Hierzu wird auf Basis der Unity-Spielengine und des ML-Agents Toolkits eine Simulationsumgebung entwickelt, in der autonome Agenten lernen, ein Ziel zu erreichen und gleichzeitig verschiedene Hindernisse zu vermeiden.

Im Mittelpunkt der Untersuchung steht der Vergleich dreier unterschiedlicher neuronaler Netzwerkarchitekturen. Neben einem Multi-Layer-Perceptron (MLP) als gedächtnislose Baseline werden ein Long Short-Term Memory Network (LSTM) sowie ein Transformer-Modell implementiert und unter vergleichbaren Bedingungen trainiert. Die Leistungsfähigkeit der Architekturen wird anhand ihrer Navigationsleistung sowie ihrer Fähigkeit zur Generalisierung auf zuvor ungesehene Kartenlayouts bewertet.
// habs entfernt. hattest recht
Zum Pflichtumfang der Arbeit gehören:

- die Entwicklung einer dreidimensionalen Labyrinthumgebung in Unity,
- die Implementierung eines Reinforcement-Learning-Agenten auf Basis von PPO,
- die Integration und Evaluation der Architekturen MLP, LSTM und Transformer,
- die Implementierung einer Ray-basierten Wahrnehmung,
- die Durchführung von Generalisierungstests auf zuvor ungesehenen Karten,
- die Dokumentation der Ergebnisse sowie die Bereitstellung einer reproduzierbaren Trainings- und Evaluationsumgebung.

Darüber hinaus umfasst die Zielsetzung mehrere optionale Erweiterungen, die über den Pflichtumfang hinausgehen: die prozedurale Kartengenerierung, Curriculum Learning zur schrittweisen Steigerung der Aufgabenschwierigkeit, Multi-Area-Training zur effizienteren Datensammlung sowie der direkte Vergleich unterschiedlicher Gedächtnisarchitekturen. // Claude meint es ist an der richtigen stelle

Von der Zielsetzung bewusst abgegrenzt werden Fragestellungen, die den Umfang dieser Arbeit überschreiten würden. Hierzu zählen insbesondere der Transfer der Ergebnisse auf reale Robotersysteme (Sim-to-Real), Mehragentenszenarien, dynamische Hindernisse, die Untersuchung unterschiedlicher Sensormodalitäten sowie die Entwicklung neuer Reinforcement-Learning-Algorithmen. Ebenso erfolgt keine quantitative Bewertung der Übertragbarkeit auf reale Serviceroboter. Diese wird stattdessen in Kapitel 9 qualitativ diskutiert.

Der zentrale Erkenntnisgewinn der Arbeit liegt auf der Frage, welchen Einfluss unterschiedliche neuronale Netzwerkarchitekturen auf das Erlernen und die Generalisierung von Navigationsverhalten in einer kontrollierten Simulationsumgebung besitzen. Die Entwicklung dieser Simulationsumgebung sowie die Einordnung der Ergebnisse in reale Anwendungsszenarien sind dafür notwendige, der Forschungsfrage jedoch nachgeordnete Bestandteile der Arbeit.
// passt es so besser?

// - Pflichtumfang: 3D-Labyrinth, 5 Maps, Ray-Sensorik, Lava/Hole/Sackgassen,
//   Transformer als Kernmodell, MLP-Baseline, >= 1 Ablationsstudie,
//   Generalisierungstest, reproduzierbares Repo, Bericht + Video-Demos
// - Optionale, umgesetzte Erweiterungen: prozedurale Map-Generierung,
//   Curriculum Learning, LSTM-Vergleich, Multi-Area-Training
// - NICHT geleistet: Sim-to-Real, Multi-Agent, dynamische Hindernisse

//== Aufbau der Arbeit

// - Kurze Übersicht der Kapitel




// 
// ============================================================================
// 2. THEORETISCHE GRUNDLAGEN
// ============================================================================
= Theoretische Grundlagen  //David
// >>> BLEIBT KAPITEL 2 — nur Reihenfolge/Rahmung geändert (ALT -> NEU):
//     "Maschinelles Lernen und RL"       -> 2.1
//     "Proximal Policy Optimization"     -> 2.2
//     "Wahrnehmung in RL-Agenten"        -> 2.3  (VORGEZOGEN, vor Sequenzmodellierung)
//     "Sequenzmodellierung für RL"      -> 2.4  (LSTM -> 2.4.2, Transformer -> 2.4.3)
//     "Unity ML-Agents Toolkit"          -> 2.5
//     (NEU 2.4.1 Gedächtnisproblem: NEU/kurz, Motivation auch in 1.5)

== Künstliche Intelligenz
Künstliche Intelligenz (KI) bezeichnet den Bereich der Informatik, der sich mit der Entwicklung maschinenbasierter Systeme befasst, die Aufgaben ausführen können, die  menschliche Intelligenz erfordern, wie beispielsweise Problemlösung, Sprachverständnis oder Mustererkennung @bhagwan_comprehensive_2024[S. 276 ]
== Maschinelles Lernen und wichtige Methoden
Maschinelles Lernen (ML) ist ein Teilgebiet der KI und befasst sich mit der Entwicklung von Algorithmen, die aus Daten lernen und auf Grundlage dieser Daten Vorhersagen treffen  @bhagwan_comprehensive_2024[S. 276 f.]. Dabei müssen keine Entscheidungsregeln explizit programmiert werden, da diese während des Trainingsprozesses aus den vorhandenen Daten abgeleitet werden. Abhängig davon, welche Art von Daten dem Modell zur Verfügung stehen und wie der Lernprozess organisiert ist, lassen sich verschiedene Lernparadigmen unterscheiden. Zu den grundlegenden Ansätzen zählen Supervised Learning (überwachtes Lernen), Unsupervised Learning (unüberwachtes Lernen) und Reinforcement Learning (bestärkendes Lernen) @shaveta_review_2023[S. 282 f.].
=== Supervised Learning (überwachtes Lernen)
Beim überwachten Lernen (Supervised Learning) wird ein Modell anhand von annotierten Trainingsdaten trainiert. Jeder Eingabe ​$x_i$ ist dabei ein bekanntes Ziel $y_i$ zugeordnet. Das Ziel des Lernprozesses besteht darin, eine Funktion $f: X -> Y$ zu erlernen, die für neue, unbekannte Eingaben möglichst korrekte Vorhersagen liefert. Typische Anwendungsgebiete sind die Klassifikation, bei der Daten vordefinierten Klassen zugeordnet werden, sowie die Regression, bei der kontinuierliche Werte vorhergesagt werden @shaveta_review_2023[S. 282]. Der Lernfortschritt wird durch den Vergleich der Modellausgabe mit den bekannten Zielwerten bewertet und über geeignete Optimierungsverfahren verbessert.
=== Unsupervised Learning (unüberwachtes Lernen)
Im Gegensatz dazu stehen beim unüberwachten Lernen (Unsupervised Learning) keine Zielwerte oder Labels zur Verfügung. Das Modell erhält ausschließlich die Eingabedaten und versucht selbstständig, darin enthaltene Strukturen, Zusammenhänge oder Muster zu identifizieren. Häufige Verfahren sind das Clustering, bei dem ähnliche Datenpunkte zu Gruppen zusammengefasst werden, sowie die Dimensionsreduktion, die darauf abzielt, die wesentlichen Informationen eines Datensatzes in einer kompakteren Darstellung abzubilden @shaveta_review_2023[S. 283]. Unüberwachtes Lernen eignet sich insbesondere zur explorativen Datenanalyse und zur Entdeckung bisher unbekannter Strukturen.
=== Reinforcement Learning (bestärkendes Lernen)
Das für diese Arbeit zentral relevante Verfahren ist das bestärkende Lernen (Reinforcement Learning, RL). Dieses verfolgt einen anderen Ansatz. Hier interagiert ein Agent fortlaufend mit einer Umgebung und trifft Entscheidungen in Form von Aktionen. Für diese Aktionen erhält er ein Feedback in Form eines sogenannten Reward-Signals. Anders als beim überwachten Lernen werden dem Agenten keine direkten Korrekturen für einzelne Entscheidungen gegeben. Stattdessen muss er durch Versuch und Irrtum selbst erlernen, welche Handlungsstrategien langfristig zu einem möglichst hohen kumulativen Reward führen @sutton_reinforcement_2018[S. 1 f.]. Aufgrund dieses Ansatzes eignet sich Reinforcement Learning besonders für komplexe Entscheidungsprobleme mit zeitlicher Abhängigkeit, beispielsweise in der Robotik, Navigation oder bei der Entwicklung von Spielstrategien.
Eine besondere Herausforderung im bestärkenden Lernen stellt das sogenannte Exploration-Exploitation-Dilemma dar. Der Agent muss kontinuierlich abwägen, ob er bereits bekannte und erfolgversprechende Aktionen ausführt (Exploitation) oder neue, bislang wenig erforschte Aktionen ausprobiert (Exploration), die langfristig zu einer höheren Belohnung führen könnten @sutton_reinforcement_2018[S. 3]. Die Balance zwischen diesen beiden Strategien ist ein zentraler Aspekt vieler Reinforcement-Learning-Verfahren und hat entscheidenden Einfluss auf deren Leistungsfähigkeit.
=== Markov-Entscheidungsprozess

Der theoretische Rahmen des Reinforcement Learning wird durch den Markov-Entscheidungsprozess (Markov Decision Process, MDP) beschrieben. Ein MDP modelliert die Interaktion eines Agenten mit seiner Umgebung und bildet damit eine zentrale Grundlage vieler Reinforcement-Learning-Verfahren. Dabei befindet sich der Agent zu einem Zeitpunkt in einem Zustand, wählt eine Aktion aus, erhält anschließend eine Belohnung und gelangt in einen Folgezustand @sutton_reinforcement_2018[S. 47 f.].

Ein MDP umfasst dabei insbesondere einen Zustandsraum $S$, einen Aktionsraum $A$, Übergangswahrscheinlichkeiten, eine Rewardfunktion sowie einen Diskontierungsfaktor $gamma$. Der Zustandsraum $S$ enthält die möglichen Zustände der Umgebung. Der Aktionsraum $A$ beschreibt die Aktionen, die dem Agenten zur Verfügung stehen. Die Übergangswahrscheinlichkeit $p(s' | s,a)$ gibt an, mit welcher Wahrscheinlichkeit der Agent nach Ausführung der Aktion $a$ im Zustand $s$ in den Folgezustand $s'$ übergeht.

Die Rewardfunktion beschreibt die unmittelbare Rückmeldung, die der Agent nach einer Zustandsänderung erhält. In dieser Arbeit wird sie als erwartete unmittelbare Belohnung eines Übergangs verstanden. Sie kann daher abhängig vom aktuellen Zustand $s$, der ausgeführten Aktion $a$ und dem Folgezustand $s'$ betrachtet werden. Der Diskontierungsfaktor $gamma$ bestimmt, wie stark zukünftige Belohnungen gegenüber unmittelbar erhaltenen Belohnungen gewichtet werden. Werte nahe 0 führen dazu, dass kurzfristige Belohnungen stärker berücksichtigt werden, während Werte nahe 1 langfristige Strategien begünstigen.

Eine zentrale Annahme des MDP ist die Markov-Eigenschaft. Sie besagt, dass die zukünftige Entwicklung des Systems durch den aktuellen Zustand und die gewählte Aktion hinreichend beschrieben wird. Frühere Zustände und Aktionen liefern keine zusätzlichen Informationen, sofern der aktuelle Zustand alle für die Zukunft relevanten Informationen enthält. Durch diese Annahme lassen sich sequenzielle Entscheidungsprobleme strukturiert modellieren und für Reinforcement-Learning-Verfahren nutzbar machen @sutton_reinforcement_2018[S.48 ff.].

=== Policy und Value-Funktionen

Das zentrale Ziel eines Reinforcement-Learning-Agenten besteht darin, eine möglichst gute Policy zu erlernen. Eine Policy beschreibt das Verhalten des Agenten, indem sie festlegt, welche Aktion in einem bestimmten Zustand ausgewählt wird. Bei einer stochastischen Policy gibt $pi(a | s)$ die Wahrscheinlichkeit an, im Zustand $s$ die Aktion $a$ auszuwählen @sutton_reinforcement_2018[S. 58]. 
Ziel des Lernprozesses ist es, eine Policy zu finden, die über die Zeit einen möglichst hohen erwarteten Return erzielt. Der Return $G_t$ beschreibt die diskontierte Summe der zukünftigen Rewards, die ein Agent nach dem Zeitpunkt $t$ erhält. Formal ergibt sich der diskontierte Return zu:


$G_t = sum_(k=0)^infinity gamma^k R_(t+k+1)$


Dabei bezeichnet $R_(t+k+1)$ den Reward zu einem zukünftigen Zeitpunkt und $gamma$ den Diskontierungsfaktor. Durch die Diskontierung haben unmittelbar eintretende Rewards einen stärkeren Einfluss auf den Return als weiter in der Zukunft liegende Rewards. Der Agent wird dadurch dazu angehalten, nicht nur kurzfristige Belohnungen, sondern auch langfristige Konsequenzen seiner Handlungen zu berücksichtigen @sutton_reinforcement_2018[S. 58 f.].

Um Zustände und Aktionen hinsichtlich ihres erwarteten langfristigen Nutzens bewerten zu können, werden im Reinforcement Learning sogenannte Value-Funktionen verwendet. Die State-Value-Funktion $v_pi (s)$ beschreibt den erwarteten Return, den ein Agent erzielt, wenn er sich im Zustand $s$ befindet und anschließend der Policy $pi$ folgt:

$v_pi (s) = EE_pi [G_t | S_t = s]$
Die State-Value-Funktion bewertet somit Zustände. Sie gibt an, wie vorteilhaft es langfristig ist, sich unter einer bestimmten Policy in einem bestimmten Zustand zu befinden.

Neben der Bewertung von Zuständen ist häufig auch die Bewertung konkreter Aktionen relevant. Die Action-Value-Funktion $q_pi(s,a)$ beschreibt den erwarteten Return, wenn der Agent im Zustand $s$ zunächst die Aktion $a$ ausführt und anschließend der Policy $pi$ folgt:

$q_pi (s, a) = EE_pi [G_t | S_t = s, A_t = a]$

Damit erlaubt die Action-Value-Funktion eine detailliertere Bewertung möglicher Handlungsalternativen. Sie ist insbesondere für Verfahren relevant, bei denen Aktionen anhand ihres erwarteten langfristigen Nutzens verglichen werden, beispielsweise bei Q-Learning oder Deep Q-Networks. In solchen Verfahren werden Action-Value-Funktionen genutzt oder approximiert, um in einem Zustand geeignete Aktionen auszuwählen @sutton_reinforcement_2018[S. 58-68 ].
=== On-Policy und Off-Policy

Reinforcement-Learning-Verfahren lassen sich unter anderem danach unterscheiden, ob sie on-policy oder off-policy lernen. Bei On-Policy-Verfahren wird die Policy verbessert, die auch zur Erzeugung der Trainingsdaten verwendet wird. Der Agent lernt somit aus Erfahrungen, die mit seiner aktuellen oder nur leicht veränderten Policy gesammelt wurden. Ein klassisches Beispiel für ein On-Policy-Verfahren ist Sarsa @sutton_reinforcement_2018[S. 129] .

Bei Off-Policy-Verfahren wird hingegen zwischen einer Ziel-Policy und einer Verhaltens-Policy unterschieden. Die Verhaltens-Policy erzeugt die Trainingsdaten, während die Ziel-Policy gelernt oder verbessert wird. Dadurch können Off-Policy-Verfahren auch aus Erfahrungen lernen, die nicht direkt durch die aktuell zu optimierende Policy erzeugt wurden. Ein klassisches Beispiel hierfür ist Q-Learning @sutton_reinforcement_2018[S. 131 ].

Für diese Arbeit ist die Unterscheidung relevant, da Proximal Policy Optimization (PPO) zu den On-Policy-Verfahren zählt. Die Trainingsdaten werden daher mit der aktuellen Policy des Agenten gesammelt und anschließend zur schrittweisen Verbesserung dieser Policy genutzt.

// - Einordnung: KI ⊃ ML ⊃ RL
// - Abgrenzung supervised / unsupervised / reinforcement learning
// - Markov-Entscheidungsprozesse (MDP): Zustände, Aktionen, Übergänge, Reward,
//   Discount-Faktor γ
// - Policy, Value-Function, Q-Function
// - On-Policy vs. Off-Policy

== Proximal Policy Optimization (PPO)
Proximal Policy Optimization (PPO) ist ein Policy-Gradient-Verfahren, das zwischen der Datenerhebung durch Interaktion mit der Umgebung und der Optimierung einer sogenannten Surrogate-Zielfunktion wechselt. Im Gegensatz zu einfachen Policy-Gradient-Verfahren erlaubt PPO mehrere Optimierungsschritte auf denselben gesammelten Rollout-Daten, ohne dass die Policy dabei zu stark verändert werden soll @schulman_proximal_2017[S. 1].
=== Actor-Critic-Framework
PPO wird in der Praxis häufig im Actor-Critic-Framework eingesetzt. Dabei übernimmt der Actor die Repräsentation der Policy $pi_theta (a | s)$ und bestimmt, mit welcher Wahrscheinlichkeit eine Aktion $a$ in einem Zustand $s$ ausgewählt wird. Der Critic schätzt den langfristigen Nutzen eines Zustands über eine Value-Funktion und dient damit als Bewertungsinstanz für die vom Actor gewählten Aktionen.
Ein zentrales Konzept hierbei ist der Advantage. Der Advantage beschreibt, ob eine ausgeführte Aktion besser oder schlechter war als vom Critic erwartet. Ist der Advantage positiv, spricht dies dafür, dass die gewählte Aktion in einer vergleichbaren Situation wahrscheinlicher werden sollte. Ist der Advantage negativ, sollte ihre Wahrscheinlichkeit entsprechend reduziert werden. Durch diese Trennung zwischen Actor und Critic kann die Varianz der Policy-Gradient-Schätzung reduziert und das Training stabilisiert werden @sutton_reinforcement_2018[S. 331 - 336].
=== Clipped Surrogate Objective
Das zentrale Problem klassischer Policy-Gradient-Methoden besteht darin, dass zu große Aktualisierungsschritte die Policy stark verschlechtern können. PPO adressiert dieses Problem durch ein Clipping-Verfahren, das die Wirkung zu großer Änderungen im Policy-Update begrenzt @schulman_proximal_2017[S. 3 f.].
Dazu wird zunächst das Wahrscheinlichkeitsverhältnis zwischen neuer und alter Policy für die tatsächlich ausgeführte Aktion definiert:
$ r_t (theta) = frac(pi_theta (a_t | s_t), pi_(theta_"old")(a_t | s_t)) $

Dieses Verhältnis beschreibt, wie stark sich die Wahrscheinlichkeit der gewählten Aktion unter der neuen Policy im Vergleich zur alten Policy verändert hat. Ein Wert von $r_t (theta) = 1$ bedeutet, dass beide Policies die Aktion gleich wahrscheinlich bewerten. Werte größer als 1 bedeuten, dass die neue Policy die Aktion wahrscheinlicher macht. Werte kleiner als 1 bedeuten, dass sie die Aktion weniger wahrscheinlich macht.Die zentrale PPO-Zielfunktion mit Clipping lautet:
$ L^"CLIP" (theta) = EE_t [  min(    r_t (theta) hat(A)_t,    op("clip")(r_t (theta), 1 - epsilon, 1 + epsilon) hat(A)_t  )] $
Dabei bezeichnet $hat(A)_t$ den geschätzten Advantage zum Zeitpunkt $t$. Der erste Term entspricht dem ungeclippten Policy-Gradient-Ziel. Der zweite Term begrenzt das Wahrscheinlichkeitsverhältnis auf den Bereich $[1 - epsilon, 1 + epsilon]$. Durch den Minimum-Operator wird verhindert, dass Änderungen der Policy, die zu einer zu starken Verbesserung des Zielfunktionswertes führen würden, unbeschränkt ausgenutzt werden. Dadurch wirkt PPO großen und potenziell destruktiven Policy-Updates entgegen @schulman_proximal_2017[S. 3 f.]. Ein häufig verwendeter Wert ist $epsilon = 0.2$. Dies bedeutet jedoch nicht, dass sich die gesamte Policy maximal um 20 % ändern darf. Korrekt ist, dass das Wahrscheinlichkeitsverhältnis im geclippten Term auf den Bereich $[0.8, 1.2]$ begrenzt wird @schulman_proximal_2017[S. 3 f.].

=== Generalized Advantage Estimation (GAE)
Für die praktische Schätzung des Advantage wird in PPO häufig Generalized Advantage Estimation (GAE) verwendet. GAE kombiniert Informationen aus mehreren Zeitschritten und steuert über den Parameter $lambda$ den Trade-off zwischen Bias und Varianz der Advantage-Schätzung. Kleine Werte von $lambda$ reduzieren typischerweise die Varianz, können aber stärkeren Bias verursachen. Große Werte verringern den Bias, erhöhen jedoch meist die Varianz. In vielen PPO-Konfigurationen wird $lambda = 0.95$ verwendet @schulman_high-dimensional_2018[S. 1 f.] @schulman_proximal_2017[S. 10].


=== Trainingszyklus und Hyperparameter

Ein PPO-Trainingszyklus besteht typischerweise aus mehreren Schritten. Zunächst sammelt der Agent mit seiner aktuellen Policy Rollouts in der Umgebung. Anschließend werden Advantage-Schätzungen berechnet. Danach wird die Policy über mehrere Epochen mit Minibatches der gesammelten Daten aktualisiert. Nach Abschluss der Optimierung wird die aktualisierte Policy zur neuen alten Policy für die nächste Datensammlung @schulman_proximal_2017[S. 4 f.].

Für diese Arbeit ist PPO besonders geeignet, da es als On-Policy-Verfahren gut zu kontrollierten Simulationsumgebungen passt und im Unity ML-Agents Framework als etablierter Trainingsalgorithmus verfügbar ist. Gegenüber DQN, das wertbasiert und off-policy arbeitet, sowie SAC, das insbesondere für kontinuierliche Aktionsräume verbreitet ist, stellt PPO für die untersuchte Navigationsaufgabe eine robuste und praktikable Wahl dar.

// - Actor-Critic-Framework: Policy-Netz (Actor) + Value-Netz (Critic)
// - Schulman et al. (2017): Clipping-Mechanismus (ε = 0.2)
// - GAE (Generalized Advantage Estimation): λ = 0.95
// - Vorteil gegenüber Vanilla Policy Gradient (Stabilität)
// - Quelle: Dokumentation/Actor_Critic_mit_PPO.md

== Sequenzmodellierung für RL <sec:sequenzmodellierung>


Der MDP setzt durch die Markov-Eigenschaft voraus, dass der aktuelle Zustand alle für zukünftige Entscheidungen relevanten Informationen enthält. In praktischen Anwendungen ist diese Voraussetzung aus Sicht des Agenten jedoch häufig nicht vollständig erfüllt, da der Agent meist nur eine begrenzte Beobachtung der Umgebung erhält. Sutton und Barto betonen, dass eine Zustandsrepräsentation nicht auf unmittelbare Sensordaten beschränkt sein muss, sondern auch aus vergangenen Wahrnehmungen oder einem internen Gedächtnis aufgebaut werden kann @sutton_reinforcement_2018[S. 49].

Bei einem Agenten mit Ray-Sensoren beschreibt ein einzelner Timestep beispielsweise nur einen lokalen Ausschnitt der Umgebung. Dadurch kann der Agent aus einer einzelnen Beobachtung nicht zuverlässig ableiten, ob er sich bereits in einer Sackgasse befindet oder welchen Weg er zuvor genommen hat. Solche Problemstellungen lassen sich als partiell beobachtbare Entscheidungsprobleme auffassen, bei denen vergangene Beobachtungen und Aktionen zusätzliche Informationen für die Entscheidungsfindung liefern können.

Sequenzmodelle wie LSTM oder Transformer können diese zeitlichen Informationen nutzen, indem sie mehrere vergangene Zeitschritte berücksichtigen. Dadurch kann der Agent eine bessere interne Repräsentation seiner aktuellen Situation aufbauen und fundiertere Entscheidungen treffen.


=== Long Short-Term Memory (LSTM)
Long Short-Term Memory (LSTM) ist eine spezielle Variante rekurrenter neuronaler Netze (Recurrent Neural Networks, RNNs), die entwickelt wurde, um Informationen über lange Zeiträume hinweg speichern und verarbeiten zu können @goodfellow_deeplearningbookorgcontentsrnnhtml_2026[S. 404]. Während klassische RNNs grundsätzlich für die Verarbeitung sequenzieller Daten geeignet sind, stoßen sie bei langen Eingabesequenzen häufig an ihre Grenzen. Ursache hierfür ist das sogenannte Vanishing-Gradient-Problem, bei dem die während des Trainings berechneten Gradienten mit zunehmender Sequenzlänge immer kleiner werden. Dadurch wird es für das Netzwerk schwierig, Abhängigkeiten zwischen weit auseinanderliegenden Zeitschritten zu erlernen und relevante Informationen langfristig zu speichern @goodfellow_deeplearningbookorgcontentsrnnhtml_2026[S. 404].
Um dieses Problem zu lösen, erweitert LSTM die Architektur klassischer RNNs um eine Speicherstruktur, die als Zellzustand bezeichnet wird. Dieser dient als internes Gedächtnis und ermöglicht die Weitergabe wichtiger Informationen über viele Zeitschritte hinweg. Der Informationsfluss innerhalb des Netzwerks wird dabei durch mehrere lernbare Steuermechanismen, sogenannte Gates, kontrolliert @goodfellow_deeplearningbookorgcontentsrnnhtml_2026[S. 404 ff.].
Das Forget Gate entscheidet, welche Informationen aus dem bisherigen Gedächtnis beibehalten und welche verworfen werden. Dadurch kann das Netzwerk nicht mehr relevante Informationen gezielt vergessen. Das Input Gate bestimmt, welche neuen Informationen aus dem aktuellen Eingabeschritt in den Zellzustand aufgenommen werden. Das Output Gate legt schließlich fest, welche Teile des internen Gedächtnisses als Ausgabe an den nächsten Zeitschritt beziehungsweise an nachfolgende Netzwerkschichten weitergegeben werden @goodfellow_deeplearningbookorgcontentsrnnhtml_2026[S. 406 f.].
Durch das Zusammenspiel dieser Gates kann ein LSTM relevante Informationen über viele Zeitschritte hinweg speichern und gleichzeitig irrelevante Informationen verwerfen. Dadurch eignet sich die Architektur besonders für Aufgaben, bei denen zeitliche Abhängigkeiten eine wichtige Rolle spielen, beispielsweise bei der Sprachverarbeitung, Zeitreihenanalyse oder im Reinforcement Learning.
Das Gedächtnis eines LSTM wird durch einen kontinuierlich aktualisierten internen Zustand repräsentiert. Welche Informationen gespeichert, überschrieben oder vergessen werden, wird nicht manuell festgelegt, sondern während des Trainings automatisch erlernt. Im Kontext von Reinforcement Learning ermöglicht dies dem Agenten, Informationen aus vergangenen Beobachtungen zu berücksichtigen und dadurch fundiertere Entscheidungen zu treffen. In Unity ML-Agents ist LSTM bereits integriert und wird über den Konfigurationsblock memory aktiviert. Dadurch erhält der Agent eine Form von Gedächtnis, die es ihm erlaubt, auch in teilweise beobachtbaren Umgebungen historische Informationen in seine Entscheidungsfindung einzubeziehen.
// - Hochreiter & Schmidhuber (1997)
// - Gates: Forget / Input / Output
// - Implizites Gedächtnis ohne expliziten Sequenz-Buffer
// - In ML-Agents standardmäßig verfügbar (use_recurrent: true)

=== Transformer-Architektur
Die Transformer-Architektur wurde von Vaswani et al. im Jahr 2017 in der einflussreichen Arbeit "Attention Is All You Need" vorgestellt und hat die Verarbeitung sequenzieller Daten grundlegend verändert @vaswani_attention_2023. Ursprünglich wurde sie für Anwendungen der natürlichen Sprachverarbeitung entwickelt, findet heute jedoch auch in zahlreichen anderen Bereichen des maschinellen Lernens Anwendung.
Im Gegensatz zu rekurrenten Architekturen wie LSTM verarbeitet ein Transformer eine Sequenz nicht schrittweise, sondern betrachtet alle Elemente eines definierten Sequenzfensters gleichzeitig. Dadurch können Abhängigkeiten zwischen verschiedenen Positionen einer Sequenz parallel analysiert werden, was sowohl die Trainingsgeschwindigkeit erhöht als auch die Modellierung weitreichender Zusammenhänge erleichtert.
Das zentrale Element der Architektur ist der sogenannte Self-Attention-Mechanismus. Dieser ermöglicht es dem Modell, die Relevanz einzelner Sequenzelemente für die Verarbeitung eines bestimmten Zeitschritts zu bewerten. Jedes Element einer Sequenz kann somit direkt Informationen von allen anderen Elementen berücksichtigen, unabhängig davon, wie weit diese zeitlich voneinander entfernt sind. Auf diese Weise lassen sich langfristige Abhängigkeiten erfassen, ohne die Einschränkungen rekurrenter Strukturen in Kauf nehmen zu müssen @vaswani_attention_2023[S. 6 f.].
Zur weiteren Steigerung der Modellkapazität wird häufig Multi-Head-Attention eingesetzt. Dabei werden mehrere Attention-Mechanismen parallel ausgeführt, sodass unterschiedliche Beziehungen und Muster innerhalb derselben Sequenz gleichzeitig erlernt werden können. Die einzelnen Aufmerksamkeitsköpfe fokussieren sich dabei auf verschiedene Aspekte der Eingabedaten und tragen gemeinsam zu einer umfassenderen Repräsentation der Sequenz bei @vaswani_attention_2023[S. 4 f.].
Da die Transformer-Architektur keine rekurrenten Verbindungen besitzt und somit keine inhärente Kenntnis über die Reihenfolge der Eingabedaten hat, muss die Positionsinformation explizit bereitgestellt werden. Dies geschieht durch sogenannte Positional Encodings, welche die Position jedes Sequenzelements kodieren und dem Modell ermöglichen, zeitliche oder räumliche Zusammenhänge innerhalb der Daten zu berücksichtigen @vaswani_attention_2023[S. 2–6].
Auch im Reinforcement Learning haben Transformer-Modelle in den vergangenen Jahren zunehmend an Bedeutung gewonnen. Parisotto et al. entwickelten mit Gated Transformer-XL (GTrXL) eine speziell angepasste Transformer-Architektur, die stabile Lernprozesse bei sequenziellen Entscheidungsaufgaben ermöglicht und die Anwendung von Transformern im Reinforcement Learning erheblich voranbrachte @parisotto_stabilizing_2019. Aufbauend auf diesen Erfolgen zeigten Chen et al. mit dem Decision Transformer, dass Reinforcement-Learning-Probleme als reine Sequenzmodellierungsaufgaben formuliert werden können. Anstatt eine klassische Wertfunktion oder Policy zu lernen, erzeugt das Modell Aktionen auf Basis vergangener Zustände, Aktionen und angestrebter Returns und nutzt dabei die Stärken der Transformer-Architektur für die Entscheidungsfindung @chen_decision_2021.
Durch ihre Fähigkeit, langfristige Abhängigkeiten effizient zu modellieren und Sequenzen parallel zu verarbeiten, stellen Transformer mittlerweile eine vielversprechende Alternative zu rekurrenten Architekturen wie LSTM dar und werden zunehmend auch für komplexe Aufgaben im Reinforcement Learning eingesetzt.
// - Vaswani et al. (2017): Attention is All You Need
// - Self-Attention, Multi-Head-Attention, Positional Encoding
// - Anwendung im RL-Kontext: Decision Transformer (Chen 2021), GTrXL (Parisotto 2019)
// - Vor- und Nachteile gegenüber LSTM
// - Quelle: Dokumentation/Transformer_Integration.md, Dokumentation/LSTM_Integration.md

== Wahrnehmung in RL-Agenten
Die Qualität der Wahrnehmung bestimmt maßgeblich, welche Informationen dem Agenten zur Entscheidungsfindung zur Verfügung stehen. In Unity ML-Agents werden Beobachtungen als Eingabevektoren an das neuronale Netz übergeben. Je nach Sensortyp unterscheiden sich Informationsdichte, Rechenaufwand und die Anforderungen an die Netzwerkarchitektur erheblich.
=== Vektorbeobachtungen (VectorSensor)
Die einfachste Form der Wahrnehmung in Unity ML-Agents erfolgt über Vektorbeobachtungen (Vector Observations). Dabei werden ausgewählte Zustandsinformationen der Umgebung als numerischer Vektor direkt an das neuronale Netzwerk übergeben. Typische Beobachtungen umfassen beispielsweise die Position, Geschwindigkeit, Orientierung oder den Abstand zu relevanten Objekten. Da keine zusätzliche Merkmalsextraktion notwendig ist, sind Vektorbeobachtungen besonders recheneffizient und eignen sich vor allem für Szenarien, in denen sich der Zustand der Umgebung durch mathematische Größen vollständig beschreiben lässt @juliani_unity_2020[S. 12 f.].
Im Rahmen dieser Arbeit erhält der Agent pro Zeitschritt insgesamt 31 numerische Beobachtungswerte, darunter die normalisierte Eigengeschwindigkeit, ein Bodenkontakt-Indikator (isGrounded), Zieldistanz und -richtung, vier Wand-Raycasts, ein Line-of-Sight-Flag sowie die Werte eines manuell implementierten Bodensensors. Dieser basiert auf nubwäts, deren Ursprünge untervor dm Agnenie diagnaud seitlich veelt sid, udlieft je Strahl(Typ-Code)nddie Informationen eines manuell implementierten Bodensensors aus 9 abwärts gerichteten Raycasts, der je Strahl die erkannte Bodenart und die normierte Distanz liefert (18 Werte). (18 Beobachtungswerte). Die vollständige Spezifikation enthält @tab:sensorspez.
=== Ray-Sensoren (RayPerceptionSensor)
Neben Vektorbeobachtungen bietet Unity ML-Agents die Möglichkeit, die Umgebung mithilfe von Ray-Sensoren (RayPerceptionSensor) wahrzunehmen. Hierbei werden virtuelle Strahlen vom Agenten ausgesendet, die Kollisionen mit Objekten in der Umgebung erkennen. Für jeden Strahl werden Informationen über den erkannten Objekttyp sowie dessen Entfernung zum Agenten erfasst. Dadurch entsteht eine kompakte und effiziente Repräsentation der unmittelbaren Umgebung, ohne dass eine aufwendige Bildverarbeitung erforderlich ist @juliani_unity_2020[S.12f].

In dieser Arbeit wird ein RayPerceptionSensor3D eingesetzt, der insgesamt elf Strahlen über einen Sichtwinkel von 120° aussendet. Jeder Strahl kann sechs unterschiedliche Objekttypen erkennen: Wall, Lava, Hole, Goal, Obstacle und Bridge. Die maximale Reichweite beträgt zwölf Zellen. Zusätzlich werden zwei aufeinanderfolgende Beobachtungen gestapelt (Stacked Raycasts = 2). Durch diese zeitliche Erweiterung erhält der Agent implizite Informationen über Veränderungen in seiner Umgebung und kann beispielsweise Bewegungen oder Richtungsänderungen besser erkennen.

=== Beobachtungsraum und Normalisierung
Unabhängig vom verwendeten Sensortyp spielt die Vorverarbeitung der Beobachtungsdaten eine wichtige Rolle für die Stabilität des Lernprozesses. Damit einzelne Merkmale das Training nicht aufgrund ihrer Größenordnung dominieren, sollten sämtliche Eingabewerte in vergleichbaren Wertebereichen vorliegen @goodfellow_deeplearningbookorgcontentsconvnetshtml_nodate[S.179]. Nicht normalisierte Eingaben können zu instabilen Gradienten und einer schlechteren Konvergenz des neuronalen Netzes führen.
Die durch den VectorSensor bereitgestellten Beobachtungen dieser Arbeit folgen dabei keinem einheitlichen Intervall, sondern größenordnungsmäßig vergleichbaren, je nach Größe eigenen Wertebereichen (@tab:sensorspez): Der Typ-Code des Bodensensors reicht bis −1,5, die Eigengeschwindigkeit ist nach oben auf 1,6 gekappt und in x/z-Richtung ungeclampt, und auch die Zieldistanz bleibt mit einem Bereich von rund [0, 2,25] ungeclampt. Lediglich die Zielrichtung ist tatsächlich auf [−1,1] normiert. Die vom RayPerceptionSensor erzeugten Distanz- und Klassifikationsinformationen werden dagegen automatisch durch Unity ML-Agents auf [0,1] normalisiert. Trotz dieser unterschiedlichen Wertebereiche bewegen sich alle Beobachtungen in einer vergleichbaren Größenordnung, was ein stabiles Training unterstützt. // wurde verbessert
== Unity ML-Agents Toolkit
Das Unity ML-Agents Toolkit ist ein Open-Source-Framework, das die Entwicklung und das Training von Reinforcement-Learning-Agenten innerhalb der Unity-Spielengine ermöglicht @juliani_unity_2020[S.11f]. Es verbindet die leistungsfähigen Simulations- und Visualisierungsmöglichkeiten von Unity mit modernen Verfahren des maschinellen Lernens. Hierzu wird eine Unity-basierte Simulationsumgebung mit einem Python-basierten Trainingsprozess gekoppelt, sodass Agenten mithilfe von Deep-Reinforcement-Learning-Algorithmen wie beispielsweise Proximal Policy Optimization (PPO) trainiert werden können @juliani_unity_2020[S.11f].
=== Architektur
Die Architektur des ML-Agents Toolkits besteht aus zwei voneinander getrennten Komponenten: der Simulationsumgebung in Unity und dem Trainingsprozess in Python @juliani_unity_2020[S.11ff].
Auf der Unity-Seite befinden sich die Agenten und die Trainingsumgebung. Der Agent sammelt während der Interaktion Beobachtungen aus seiner Umgebung, führt Aktionen aus und erhält hierfür entsprechende Rewards. Die Umgebung simuliert dabei die Auswirkungen der Aktionen und stellt die aktuellen Zustände für den nächsten Zeitschritt bereit.
Auf der Python-Seite läuft der eigentliche Trainingsprozess. Dieser empfängt die von der Unity-Simulation erzeugten Rollouts, berechnet anhand der gesammelten Erfahrungen die Gradienten des neuronalen Netzes und aktualisiert die Modellparameter. Anschließend werden die aktualisierten Gewichte zurück an die Unity-Umgebung übertragen. Die Kommunikation zwischen beiden Komponenten erfolgt über gRPC (Google Remote Procedure Call). Durch diese Trennung können Simulation und Training unabhängig voneinander ausgeführt und flexibel erweitert werden @juliani_unity_2020[S.11ff].
=== Komponenten
Für die Implementierung von RL-Agenten stellt das ML-Agents Toolkit mehrere zentrale Komponenten bereit.
Die wichtigste Komponente ist die Klasse Agent, welche die grundlegende Schnittstelle zwischen Agent und Trainingsumgebung bildet. Über Methoden wie CollectObservations() werden Beobachtungen erfasst, während OnActionReceived() die vom neuronalen Netzwerk ausgegebenen Aktionen verarbeitet. Mit OnEpisodeBegin() kann zudem die Umgebung zu Beginn einer neuen Episode zurückgesetzt werden @unity_agents_nodate .
Die Behavior Parameters definieren die Eigenschaften eines Agenten, insbesondere den Aktionsraum und den Beobachtungsraum. Darüber hinaus legen sie fest, welches trainierte Modell beziehungsweise welches Trainingsverhalten mit dem Agenten verknüpft ist @unity_agents_nodate .
Der Decision Requester steuert, in welchen zeitlichen Abständen der Agent neue Entscheidungen anfordert. Dadurch kann festgelegt werden, ob der Agent in jedem Simulationsschritt oder nur in bestimmten Intervallen eine neue Aktion auswählt @unity_agents_nodate-1.
Ergänzt wird das System durch verschiedene Sensor Components, welche die Wahrnehmung der Umgebung ermöglichen. Hierzu zählen beispielsweise der VectorSensor für numerische Zustandsinformationen, der RayPerceptionSensor für strahlbasierte Umgebungswahrnehmung sowie der CameraSensor für bildbasierte Beobachtungen @unity_agents_nodate-2 .
=== Trainings-Workflow
Der Trainingsprozess wird über eine YAML-Konfigurationsdatei gesteuert. In dieser werden unter anderem der verwendete Lernalgorithmus, Hyperparameter, Netzwerkarchitektur und Trainingsdauer definiert. Dadurch kann das Verhalten des Trainingsprozesses flexibel an unterschiedliche Anwendungsfälle angepasst werden @unity_training_nodate.
Während des Trainings sammelt der Agent Erfahrungen innerhalb der Simulationsumgebung, die vom Python-Trainer verarbeitet werden. Nach Abschluss des Trainings wird das resultierende Modell im ONNX-Format (Open Neural Network Exchange) gespeichert, sodass es direkt in Unity für die Inferenz verwendet werden kann @unity_unity_nodate.
Zur Überwachung des Lernfortschritts können Trainingsmetriken wie Reward, Episodenlänge sowie Verluste der Policy- und Value-Netzwerke mit TensorBoard visualisiert werden @unity_using_nodate.
Im Rahmen dieser Arbeit wird die Version 0.30.0 des Unity ML-Agents Toolkits eingesetzt. Da diese Version keine öffentliche Schnittstelle zur Implementierung eigener Policy-Architekturen bereitstellt, werden die untersuchten LSTM- und Transformer-Modelle durch Anpassungen der Python-Trainingsumgebung integriert. Dadurch können neben den standardmäßig verfügbaren Netzwerkarchitekturen auch sequenzielle Gedächtnismodelle evaluiert werden.

// Betreffen die kkommentare mich?
// ============================================================================

= Stand der Technik

Nachdem in Kapitel 2 die theoretischen Grundlagen der eingesetzten Verfahren erläutert wurden, ordnet dieses Kapitel die vorliegende Arbeit in den aktuellen Forschungsstand ein. Zunächst werden etablierte Simulationsplattformen für das Deep Reinforcement Learning verglichen und die Wahl des Unity-ML-Agents-Frameworks begründet. Anschließend wird der Forschungsstand zur lernbasierten Navigation in dreidimensionalen Umgebungen betrachtet vom Umgang mit partieller Beobachtbarkeit über die Belohnungsgestaltung bis zur Generalisierung auf unbekannte Umgebungen. Abschließend wird aus dem dargestellten Forschungsstand der Handlungsbedarf abgeleitet, an dem die vorliegende Arbeit ansetzt.

== Simulationsumgebungen und das Unity-ML-Agents-Framework

Verfahren des Deep Reinforcement Learning benötigen typischerweise Millionen von Interaktionsschritten, bis sich ein brauchbares Verhalten einstellt. Das Training findet daher fast ausschließlich in simulierten Umgebungen statt, in denen die Simulationsgeschwindigkeit gegenüber der Echtzeit erhöht und Episoden beliebig oft wiederholt werden können. In der Forschung haben sich hierfür verschiedene Plattformen etabliert. DeepMind Lab stellt auf Basis der Quake-III-Engine prozedural erzeugbare 3D-Labyrinthe bereit und wurde gezielt für die Navigations- und Explorationsforschung entwickelt. @beattie_deepmind_2016 Einen ähnlichen Ansatz verfolgt ViZDoom auf Basis der Doom-Engine, das RL-Forschung mit rein visuellen Beobachtungen ermöglicht. @kempka_vizdoom_2016 Beide Plattformen sind jedoch auf ihre jeweilige Engine festgelegt und erlauben nur begrenzte Anpassungen der Weltlogik.

Das Unity-ML-Agents-Toolkit verfolgt demgegenüber einen allgemeineren Ansatz: Es verbindet die Unity-Engine als frei gestaltbare Simulationsumgebung mit einer Python-Schnittstelle für das Training. Juliani et al. @juliani_unity_2020 argumentieren, dass Spiele-Engines wie Unity durch ihre flexible Physiksimulation, die visuelle Gestaltungsfreiheit und die Steuerbarkeit der Simulationsgeschwindigkeit besonders geeignete Plattformen für die Entwicklung intelligenter Agenten darstellen. Für die vorliegende Arbeit ist darüber hinaus entscheidend, dass die Weltlogik: Zelltypen, Gefahrenfelder, prozedurale Layouterzeugung, vollständig selbst gestaltbar ist, was bei den engine-gebundenen Plattformen nur eingeschränkt möglich wäre. 
== Lernbasierte Navigation in 3D-Umgebungen

Die autonome Navigation in dreidimensionalen Umgebungen zählt zu den klassischen Anwendungsfeldern des Deep Reinforcement Learning. Im Hinblick auf die Zielsetzung dieser Arbeit, einen Agenten zu entwickeln, der generalisierbares Navigationsverhalten in Labyrinthen mit Gefahrenfeldern erlernt, ist es unabdingbar, den Forschungsstand zur lernbasierten Navigation, zum Umgang mit partieller Beobachtbarkeit, zur Belohnungsgestaltung und zur Generalisierung näher zu betrachten. In den folgenden Teilkapiteln wird der Forschungsstand hierzu erläutert.

=== Anfänge der lernbasierten Navigationsforschung

Die moderne Erforschung der lernbasierten Navigation in 3D-Umgebungen nahm ihren Ausgang mit dem Erfolg des Deep Reinforcement Learning auf zweidimensionalen Spielumgebungen durch Mnih et al. @mnih_human-level_2015 im Jahr 2015. In der Folge verlagerte sich der Forschungsschwerpunkt auf komplexere dreidimensionale Welten.

Erstmals untersuchten Mirowski et al. @mirowski_learning_2017 im Jahr 2017 systematisch das Navigationslernen in großen 3D-Labyrinthen allein auf Basis visueller Beobachtungen. Sie erkannten, dass reine End-to-End-Navigation aus Rohbeobachtungen äußerst datenhungrig ist, und führten zusätzliche Hilfsaufgaben (engl. Auxiliary Tasks) ein, darunter die Vorhersage von Tiefeninformationen und die Erkennung bereits besuchter Orte. In ihren Untersuchungen kamen sie zum Ergebnis, dass diese Hilfsaufgaben das Navigationslernen erheblich beschleunigen, da sie dem Netz zusätzliches Struktursignal über die räumliche Beschaffenheit der Umgebung liefern. Zudem setzten sie rekurrente Netzarchitekturen ein, um Informationen über die Zeit hinweg zu aggregieren. @mirowski_learning_2017

Im selben Jahr veröffentlichten Zhu et al. @zhu_target-driven_2017 ihre Forschungsergebnisse zur zielgerichteten visuellen Navigation in Innenraumszenen. Sie untersuchten einen Ansatz, bei dem das anzusteuernde Ziel selbst Teil der Netzeingabe ist, sodass ein einzelnes trainiertes Modell unterschiedliche Ziele ansteuern kann, ohne für jedes Ziel neu trainiert werden zu müssen. @zhu_target-driven_2017 Dieses Prinzip, das Ziel nicht fest in die Policy einzubauen, sondern als variable Information bereitzustellen, findet sich auch im Aufbau der vorliegenden Arbeit wieder, in der Start- und Zielposition in jeder Episode zufällig neu platziert werden.

=== Grundlagen des Lernens unter partieller Beobachtbarkeit <sec:partielle-beobachtbarkeit>

Wie in @sec:sequenzmodellierung erläutert, sind Labyrinthumgebungen partiell beobachtbar: Der Agent nimmt in jedem Zeitschritt nur einen lokalen Ausschnitt der Welt wahr. Eine rein reaktive Policy, die ausschließlich die aktuelle Beobachtung verarbeitet, erreicht in solchen Umgebungen schnell eine Leistungsgrenze, da sie mehrdeutige Situationen nicht auflösen kann. Typische Fehlerbilder sind das Oszillieren in Sackgassen oder das wiederholte Absuchen bereits erkundeter Bereiche. @hausknecht_deep_2015

Hausknecht und Stone @hausknecht_deep_2015 zeigten bereits 2015, dass die Erweiterung eines tiefen Q-Netzes um eine rekurrente LSTM-Schicht die Leistung in partiell beobachtbaren Aufgaben deutlich verbessert. Das LSTM verdichtet die Historie vergangener Beobachtungen in einem internen Zustandsvektor und stellt dem Agenten damit ein implizites Gedächtnis zur Verfügung. @hausknecht_deep_2015 Auch Mirowski et al. @mirowski_learning_2017 setzten für ihre Labyrinthnavigation auf gestapelte rekurrente Einheiten. Rekurrente Gedächtnisarchitekturen stellen damit den etablierten Ausgangspunkt für Navigationsaufgaben unter partieller Beobachtbarkeit dar. In ML-Agents sind sie in Form eines optionalen LSTM-Speichers direkt in die PPO-Trainingspipeline integriert. @juliani_unity_2020

=== Grundlagen der Belohnungsgestaltung

Neben dem Lernalgorithmus und der Modellarchitektur hat die Gestaltung der Belohnungsfunktion wesentlichen Einfluss auf den Trainingserfolg. In Navigationsaufgaben ist die natürliche Belohnung: das Erreichen des Ziels spärlich (engl. sparse), da sie erst am Ende einer erfolgreichen Episode auftritt. Ein zufällig explorierender Agent findet das Ziel in großen Labyrinthen anfangs nur selten, wodurch das Lernsignal weitgehend ausbleibt. @sutton_reinforcement_2018

Als Reward Shaping wird die Anreicherung der Belohnungsfunktion um Zwischenbelohnungen bezeichnet, etwa Strafen für Zeitverbrauch oder für das Betreten gefährlicher Felder. Ng et al. @ng_policy_1999 zeigten bereits 1999, dass potentialbasiertes Reward Shaping die optimale Policy nicht verändert, während naiv gewählte Zwischenbelohnungen unerwünschtes Verhalten hervorrufen können, beispielsweise das wiederholte Einsammeln derselben Teilbelohnung anstelle der eigentlichen Zielerreichung.Ein verbreitetes Grundmuster für Navigationsaufgaben ist die Kombination aus einer positiven Terminalbelohnung für das Erreichen des Ziels, negativen Terminalbelohnungen für das Scheitern sowie einer kleinen negativen Belohnung pro Zeitschritt, die als Zeitdruck wirkt und passives Verhalten verhindert. @sutton_reinforcement_2018

=== Generalisierung auf unbekannte Umgebungen

Ein zentrales Qualitätskriterium lernender Navigationsagenten ist, dass sie nicht einzelne Karten auswendig lernen, sondern übertragbares Verhalten entwickeln. Dieses Problem ist in der Forschung als Generalisierungsproblem bekannt. Zhang et al. @zhang_study_2018 untersuchten 2018 das Überanpassungsverhalten von Deep-RL-Agenten und kamen zum Ergebnis, dass Agenten bei Training auf einer festen, kleinen Menge von Umgebungen massiv überanpassen: Ihre Leistung bricht auf strukturell ähnlichen, aber ungesehenen Varianten drastisch ein, obwohl die Trainingsleistung hoch ist. @zhang_study_2018

Cobbe et al. @cobbe_quantifying_2019 quantifizierten diesen Effekt ein Jahr später systematisch anhand prozedural generierter Level. Sie wiesen nach, dass überraschend große Trainingsmengen, in ihren Experimenten mehrere Tausend Levelvarianten, erforderlich sein können, bevor die Leistung auf ungesehenen Leveln mit der Trainingsleistung gleichzieht. @cobbe_quantifying_2019 Als Konsequenz etablierten Cobbe et al. @cobbe_leveraging_2020 mit dem Procgen Benchmark eine Evaluationsumgebung, in der Trainings- und Testlevel strikt getrennt prozedural erzeugt werden, um tatsächliche Generalisierung anstelle von Memorierung zu messen. @cobbe_leveraging_2020

Aus diesen Arbeiten lassen sich zwei methodische Anforderungen für die vorliegende Arbeit ableiten. Erstens muss die Trainingsumgebung ausreichende Variation bereitstellen. Das in dieser Arbeit entwickelte Map-System mit mehreren Grundlayouts, prozeduraler Layouterzeugung sowie pro Episode zufällig platzierten Start-, Ziel- und Hindernispositionen dient genau diesem Zweck. Zweitens muss die Evaluation auf zurückgehaltenen Karten erfolgen, die während des Trainings nicht verwendet wurden, da Erfolgsraten auf Trainingskarten die tatsächliche Fähigkeit des Agenten systematisch überschätzen würden. @zhang_study_2018 @cobbe_quantifying_2019

== Ableitung des Handlungsbedarfs für die vorliegende Arbeit

Der dargestellte Stand der Technik zeigt, dass die einzelnen Bausteine der vorliegenden Arbeit jeweils gut erforscht sind: PPO ist ein etabliertes, robustes Trainingsverfahren @schulman_proximal_2017, Unity ML-Agents eine erprobte Plattform für selbst gestaltete Trainingsumgebungen @juliani_unity_2020, die Labyrinthnavigation ein klassisches Untersuchungsfeld @mirowski_learning_2017 und die Notwendigkeit von Umgebungsvariation für die Generalisierung empirisch belegt @zhang_study_2018 @cobbe_quantifying_2019. Der Einsatz von Transformern als Entscheidungsmodell im Online-Reinforcement-Learning ist durch den GTrXL prinzipiell demonstriert @parisotto_stabilizing_2019, allerdings überwiegend auf großskaligen Forschungsplattformen mit erheblichem Rechenaufwand.

Trotz dieser breiten Vorarbeiten bleibt eine Forschungslücke bestehen. Die genannten Arbeiten behandeln die für diese Arbeit relevanten Aspekte jeweils isoliert: Navigation in 3D-Umgebungen, den Umgang mit partieller Beobachtbarkeit durch rekurrente Architekturen oder den Nachweis von Generalisierung anhand prozedural erzeugter Level. Ein direkter, kontrollierter Vergleich der drei Architekturklassen unter identischem Lernverfahren und identischer Aufgabenstellung ist hingegen bislang nicht systematisch erfolgt. Insbesondere für Ray-basierte Navigation in generierten 3D-Labyrinthen mit garantiert lösbaren Karten und heterogenen Gefahrenfeldern liegt ein solcher Vergleich nach Kenntnis der Autoren nicht vor. Die vorhandenen Transformer-Nachweise im Reinforcement Learning stammen zudem überwiegend von großskaligen Forschungsplattformen, ob sich der berichtete Vorteil auch unter den Randbedingungen einer selbst entworfenen Umgebung mit begrenzten Rechenressourcen reproduzieren lässt, ist offen.

Genau an dieser Stelle setzt die vorliegende Arbeit an. Ein MLP ohne Gedächtnis, ein rekurrenter LSTM-Agent und ein Transformer über einer Beobachtungshistorie werden unter kontrollierten, weitestgehend identischen Bedingungen (@sec:yaml-abweichungen) mit PPO trainiert und anhand von Erfolgsrate, durchschnittlicher Belohnung sowie der Generalisierung auf zurückgehaltene Karten verglichen. Nach der Einordnung in den Forschungsstand wird im folgenden Kapitel die entwickelte Simulationsumgebung mit ihren Komponenten vorgestellt.


// ============================================================



// ============================================================================
// 4. SYSTEMARCHITEKTUR UND UMGEBUNG  — erst die Welt bauen (vor Methodik)
//FINN ============================================================================
= Systemarchitektur und Umgebung

Dieses Kapitel beschreibt das entwickelte System in seinem finalen Zustand als Versuchsapparat. Es zeigt, welche Voraussetzungen das Experiment erfüllen muss, um die Forschungsfragen F1–F3 beantworten zu können. Zunächst wird die Systemumgebung beschrieben, da sich das Vergleichsdesign (Kapitel 5) nur vor dem Hintergrund der Umgebung nachvollziehen lässt, in der die Messungen durchgeführt werden. Die Entwicklung des Systems sowie die einzelnen Überarbeitungen werden anschließend in Kapitel 7 (siehe @sec:iterationen) dokumentiert. Während dieses Kapitel den Endzustand beschreibt, erläutert Kapitel 7 den Entwicklungsprozess.

== Gesamtüberblick

Das Gesamtsystem besteht aus einem geschlossenen Regelkreis zwischen Unity, dem PPO-Trainer und TensorBoard. Während die Unity-Umgebung Beobachtungen und Belohnungssignale bereitstellt, optimiert der Python-Trainer die Policy und übermittelt die daraus resultierenden Aktionen zurück an die Simulation. TensorBoard zeichnet den Trainingsverlauf auf. Das Vergleichsdesign wird in Kapitel 5 erläutert.

#figure(
  image("assets/Komponentendiagramm des Trainingssystems.png", width: 100%),
  caption: [Komponentendiagramm des Trainingssystems],
)

Die Umgebung diente als reproduzierbarer Testbereich zur Untersuchung der Forschungsfragen F1–F3. Die Topologie eines Layouts wird deterministisch aus einem Seed erzeugt. Da die Hindernisplatzierung jedoch einen nicht seedgebundenen Zufallsstrom verwendet, ist eine vollständige Karte nicht allein aus dem Seed bitgenau reproduzierbar. Die Reproduzierbarkeit wird deshalb durch das einmalige Offline-Erzeugen und anschließende Einfrieren der Layout-Assets sichergestellt. Dadurch ließ sich eine Karte bereits vor dem Training festlegen, beliebig oft wiederverwenden oder gezielt vom Training ausschließen (siehe @sec:prozgen). Die verwendeten Softwareversionen sowie die Struktur des Repositories sind in @tab:systemstack zusammengefasst.

#figure(
  table(
    columns: 2,
    align: (left, left),
    [*Komponente*], [*Spezifikation*],
    [Engine], [Unity 6 (6000.2.6f1)],
    [ML-Agents (Unity-Paket)], [`com.unity.ml-agents` 2.0.2],
    [ML-Agents (Python-Trainer)], [`mlagents` 0.30.0 (Details: @tab:traininginfra)],
    [Kopplung Unity--Trainer], [ML-Agents-gRPC, je `--num-envs`-Instanz ein eigener Headless-Unity-Prozess mit eigenem Port],
    [`Assets/Scripts/`], [Laufzeitcode: Map, Agent, Camera, Audio, Competition, Visual],
    [`Assets/Editor/`], [Offline-Werkzeuge: Generatoren, Szenen-Builder, Validatoren],
    [`Assets/Scenes/`, `Assets/Prefabs/`], [Szenen und Prefabs],
    [`training/`], [Patch-Skript, Custom-Policies, Export, Reports],
    [`config/`], [Trainer-Konfigurationen (YAML)],
    [`results/`], [Trainingsläufe, Checkpoints, ONNX-Exporte],
  ),
  caption: [Software-Stack und Repository-Struktur des Gesamtsystems.],
) <tab:systemstack>

== Map-System

=== Datenmodell <sec:datenmodell>

Eine Karte besteht aus typisierten Zellen, die in einem zweidimensionalen Raster angeordnet sind (@tab:datenmodell). Mehrere Eigenschaften dieses Datenmodells sind für die Beantwortung der Forschungsfragen relevant. Zum einen sorgen die Zelltypen Lava und Loch in Kombination mit den Sackgassen der prozedural generierten Layouts für eine vielfältigere Form der Teil-Observabilität, mit der das temporale Gedächtnis umgehen muss (F1, siehe @sec:partielle-beobachtbarkeit). Zum anderen verbindet der Zelltyp Plattform den Kartenaufbau mit dem Konzept der Lösbarkeit. Lavafelder lassen sich mithilfe einer Plattform oder durch einen Sprung aus einer Höhe von 1 überwinden. Diese Spielmechanik bildet die Grundlage des in @sec:prozgen beschriebenen Lösbarkeitskonzepts und ist gleichzeitig die Ursache der Fehler, die in der Generalisierungsmetrik untersucht werden (F3).

#figure(
  table(
    columns: 2,
    align: (left, left),
    [*Element*], [*Spezifikation*],
    [CellType (Enum, 9 Werte)], [Empty, Floor, Wall, Obstacle, Goal, SpawnPoint, Lava, Hole, Platform],
    [MapData (ScriptableObject)], [`width`, `height`, `CellType[] cells`, Zellindex `y * width + x`, Zugriff über `GetCell`/`SetCell`],
    [Laufzeitfelder], [`cellHeightOffsets` (Default 0.75), Flag `noRuntimeObstacles`],
  ),
  caption: [Datenmodell der Karten: Zelltyp-Satz und Felder von MapData.],
) <tab:datenmodell>

=== MapGenerator zur Laufzeit

Zur Laufzeit instanziiert der MapGenerator nur ein bestimmtes Layout als 3D-Szene. Er fungiert allein als Renderer. Wie in der Offline-Pipeline (@sec:prozgen) detailliert beschrieben, erfolgen die Hinderniskonstruktion und die Überprüfung der Lösbarkeit außerhalb des MapGenerators. Weil Erzeugung und Instanziierung getrennt sind, können Karten vor dem Training offline erzeugt, eingefroren und als ungesehenes Bewertungsset zurückgehalten werden. Nur so lässt sich garantieren, dass eine Testkarte dem Training nie präsentiert wurde, eine notwendige Bedingung der Generalisierungsmessung (@sec:messbarkeit, @sec:evalprotokoll).

Das Curriculum ist als eigener Training Mode implementiert und nicht als Karten-Auswahlmodus (@tab:mapgen). Die gestufte Schwierigkeit ist bewusst als kontrollierte Trainingsbedingung konzipiert und entsteht nicht zufällig durch die Kartenauswahl. Die methodische Begründung folgt in Kapitel 5, die technische Umsetzung in Kapitel 7.

Für den Architekturvergleich ist außerdem der Multi-Area-Betrieb entscheidend. Mehrere identische Trainingsflächen pro Szene gewährleisten für jede Architektur denselben Sampling-Durchsatz und schaffen damit die Voraussetzung für einen fairen Vergleich. Kapitel 5 erläutert das Versuchsdesign. Die Vergleichs-Szene, in der alle drei Architekturen gleichzeitig mit derselben Anzahl an Trainingsflächen trainieren, bildet dabei die Grundlage dieser Aussage. Die Anzahl der Trainingsflächen pro Szene ist in @tab:mapgen dokumentiert.

#figure(
  table(
    columns: 2,
    align: (left, left),
    [*Element*], [*Spezifikation*],
    [Tile-Pool], [wiederverwendete Kacheln mit Prefab-Mapping je Zelltyp, kein Instantiate/Destroy je Episode],
    [Spawn- und Zielposition], [im Trainings-Prefab vordefiniert aus den gebackenen Layout-Zellen (Modi PredefinedSpawnPoints/PredefinedGoalSpawnPoints): Spawn = zufällig gewählte gebackene SpawnPoint-Zelle, Ziel = zufällig gewählte gebackene Goal-Zelle mit Ziel ≠ Spawn, nur die dynamische Meide-Logik (Lava-/Hole-Nachbarn) ist Fallback, falls keine gebackene Zelle nutzbar ist, Ziel-Variation entsteht offline über den Layout-Pool (@tab:curriculum), nicht zur Laufzeit, Marker um +0.5 auf der Y-Achse versetzt, optionales Kamera-Framing],
    [KillZone], [persistente Trigger-Box bei y = −20, terminiert Episoden nach Sturz in ein Loch (Terminierungsmechanik, Entstehung: Kapitel 7)],
    [Platzierungs-Modi], [Spawn-, Goal- und ObstaclePlacementMode, MapSelectionMode {Fixed, Random, Sequential}, Curriculum-Quelle: `CurriculumTracker.GetNextLayout()`],
    [Trainingsflächen je Szene], [Training_MultiArea: 10, Transformer_Test_V2: 16, Vergleichs-Szene „Training Area“: 27 (3 × 9, d. h. 9 je Architektur), Einzelszenen: 1 je Prozess, skaliert über `--num-envs`],
  ),
  caption: [Laufzeit-Kartenaufbau: Objektverwaltung, Platzierungslogik und Trainingsflächen je Szene.],
) <tab:mapgen>

=== Prozedurale Generierung als Umsetzung der Messbarkeitsbedingung <sec:prozgen>

Die prozedurale Generierung schafft die in @sec:messbarkeit begründete Voraussetzung für den Nachweis von Generalisierung (F3): systematisch erzeugbare Layouts und ein zurückgehaltenes, im Training nie gesehenes Test-Set.

Die Layouts entstehen in einer graphbasierten Pipeline aus Räumen und Korridoren (@tab:prozgen). Jede erzeugte Karte durchläuft abschließend eine Lösbarkeitsprüfung: Der SemanticPathfinder verifiziert per Breitensuche über die 4er-Nachbarschaft, dass vom Startpunkt ein begehbarer Pfad zum Ziel existiert. Welche Zelltypen dabei als begehbar gelten, folgt exakt der Hindernis-Semantik des Datenmodells (@sec:datenmodell, Regeln in @tab:prozgen). Diese Garantie ist für die Interpretation aller späteren Ergebnisse entscheidend: Scheitert ein Agent an einer Karte, ist das Scheitern dem Agenten zuzuschreiben, nicht einer unlösbaren Karte (F3).

Die Topologie jedes Layouts geht deterministisch aus einem Seed hervor (System.Random(seed)), die Hindernisplatzierung nutzt dagegen einen nicht seed-gebundenen Zufallsstrom, sodass eine Karte nicht allein aus ihrem Seed bit-genau reproduziert wird. Reproduzierbar wird das Evaluations-Set deshalb nicht durch erneutes Generieren, sondern durch das einmalige Erzeugen und anschließende Einfrieren der gebackenen Layout-Assets: Jedes Test-Layout wird offline generiert, als Asset gespeichert und als unveränderlicher Bestand zurückgehalten. Darauf beruht das im Training nie gesehene Evaluations-Set, das den in @sec:evalprotokoll definierten Overfitting-Index messbar macht (Ergebnisse in @sec:generalisierung).

Die erzeugten Layouts sind zudem nach Schwierigkeit gestuft (@tab:curriculum). Diese aufsteigende Schwierigkeitsleiter definiert die Progression des Curriculum-Trainings, deren Wirkung auf die Konvergenz der Architekturen später gemessen wird (F1/F2, @sec:architekturvergleiche). Die zugehörige Trainingsbedingung legt Kapitel 5 fest, ihre Entstehung schildert Kapitel 7.

Schließlich erzeugt die Hindernis-Semantik der Pipeline gezielt Situationen, die für die Forschungsfragen entscheidend sind: Terminal-Korridore enden blind in einem Loch, Lava bildet Sprung-Hürden und Verzweigungen führen in Sackgassen. Gerade diese partiell observierbaren Situationen erfordern temporales Gedächtnis (F1). Die Schwierigkeit der Umgebung entsteht damit nicht zufällig, sondern ist gezielt konstruiert.

#figure(
  table(
    columns: 2,
    align: (left, left),
    [*Stufe*], [*Spezifikation*],
    [Einstiegspunkt], [`ProceduralLayoutGenerator.GenerateLayout(seed, difficulty)`, bis zu 10 Generierungsversuche je Aufruf, Aufruf ausschließlich in Editor-Skripten (MapGeneratorEditor, CurriculumV2Builder), nicht zur Laufzeit],
    [Pipeline], [BuildTopology → Räume → Korridore → Wände → Spawn/Ziel → Coverage ≥ 15 % → Hindernis-Cluster → Platforms → Pfad-Check],
    [RoomCorridorGraph], [`BORDER` = 2, `MIN_CORRIDOR_LEN` = 4, Korridore 2 Kacheln breit, Raumtypen Start, Goal, DeadEnd, Goal-Raum ist der Knoten mit größter Manhattan-Distanz (zu 75 %), mit 25 % Wahrscheinlichkeit der zweitweiteste (`goalIndex` = 1 bei `rng` \< 0.25), optionale Loops],
    [ObstacleClusterPlacer], [je Korridortyp: Goal-Korridor Lava der Tiefe 1/2/3 (Platform ab Tiefe \> 1), DeadEnd-/Terminal-Korridor Hole der Tiefe 2, Loop-Korridor zu 50 % Lava der Tiefe 1, DeadEnd-Korridor wahlweise kein Hindernis, Hole oder Lava],
    [SemanticPathfinder], [Breitensuche (BFS) über die 4er-Nachbarschaft, begehbar: Floor, SpawnPoint, Goal, Platform sowie CellType.Obstacle (Rückwärtskompatibilität zu Alt-Assets), Hole nie, Lava nur bei Tiefe 1 oder mit Platform],
  ),
  caption: [Offline-Generierungspipeline: Einstiegspunkt, Konstanten und Lösbarkeitsregeln.],
) <tab:prozgen>

#figure(
  table(
    columns: 2,
    align: (left, left),
    [*Element*], [*Spezifikation*],
    [DifficultyLevel-Enum (Reihenfolge)], [Trivial → TrivialCorr → TrivialBranch → TrivialHole → TrivialHazard → Easy → Medium → Hard, zusätzlich TrivialLava],
    [Trainiertes 8-Phasen-Curriculum (CurriculumV2Builder)], [Trivial → TrivialCorr → TrivialHole → TrivialLava → TrivialHazard → Easy → Medium → Hard, TrivialBranch ist keine Phase (100 erzeugte Layouts bleiben ungenutzt), TrivialLava ist reguläre Phase 3],
    [Phasen-Schleife], [`loopPhases` = true: nach Hard Rücksprung auf Easy (relevant für die Interpretation der Trainings-Erfolgsrate, @sec:evalprotokoll)],
    [Layout-Pool], [100--200 Seeds je Stufe, offline erzeugt und eingefroren],
    [Konstruktion], [Trivial fix 7 × 7, übrige Trivial-Stufen direkte Konstruktion mit variabler Größe (Räume 2--4, Korridorlänge 4--9, vier Formtypen), TrivialLava aus separatem LavaMapGenerator, Easy/Medium/Hard über die Graph-Pipeline (@tab:prozgen)],
    [DifficultySettings je Stufe], [Grid-Größe, Korridorzahl, Verzweigungstiefe, Hindernis-Wahrscheinlichkeiten],
  ),
  caption: [Schwierigkeitsleiter und trainiertes Curriculum: Enum-Reihenfolge, Phasenfolge und Konstruktionsparameter der Layout-Pools.],
) <tab:curriculum>

== Agent-System

Die gesamte Agentenlogik (Beobachtungsaufbau, Aktionsausführung und Belohnungsvergabe) liegt in der Klasse LabyrinthAgent (`Assets/Scripts/Agent/LabyrinthAgent.cs`) und ist für alle Architekturen identisch. Die drei Vergleichsagenten unterscheiden sich ausschließlich durch ihren Behavior-Namen und die dahinterliegende Netzarchitektur (@tab:behaviors). 



=== Aktionsraum

Der Agent handelt über einen diskreten Aktionsraum mit drei Branches (Bewegung, Drehung und Sprung).
#figure(
  table(
    columns: 3,
    align: (left, center, left),
    [*Branch*], [*Größe*], [*Semantik*],
    [0 (Bewegung)], [3], [keine Bewegung / vorwärts / rückwärts],
    [1 (Drehung)], [3], [keine Drehung / links / rechts],
    [2 (Sprung)], [3], [effektiv binär (nur Wert 1 belegt), einzelner AddForce-Impuls, ausgeführt nur bei Bodenkontakt],
  ),
  caption: [Diskreter Aktionsraum der drei Vergleichsagenten (drei Branches der Größe 3).],
) <tab:aktionsraum>

=== Observation-Space <sec:obsspace>

Alle drei Vergleichsagenten erhalten denselben Beobachtungssatz: 31 Vektor-Beobachtungen und 176 Ray-Beobachtungen. Der Szenen-Builder weist MLP_Navigator, LSTM_Navigator und Transformer_Navigator über dasselbe Prefab identische Eingaben zu (kontrollierte Variable des Vergleichs, Abschnitt 5.3). Beobachtete Leistungsunterschiede können jedoch sowohl aus der Netzarchitektur als auch aus den in @sec:yaml-abweichungen dokumentierten architekturspezifischen Trainerparametern resultieren.

Die vollständige Spezifikation des Beobachtungssatzes enthält @tab:sensorspez (@sec:sensorik). Für alle Agenten gilt außerdem `NumStackedVectorObservations = 1`, sodass die Vektor-Beobachtungen nicht zusätzlich gestapelt werden.

=== Bewegungs- und Sprungphysik

Der Agent bewegt sich physikbasiert über einen Rigidbody, die Kinematik-Parameter (@tab:physik) sind für alle drei Architekturen identisch. Zwei dieser Parameter sind unmittelbar experimentell relevant. moveSpeed normiert die Geschwindigkeits-Beobachtung (@tab:sensorspez), während die Sprungkraft die Lösbarkeitssemantik der Karten bestimmt, indem sie Lava der Tiefe 1 per Sprung überwindbar macht (@sec:prozgen). Im Endzustand umfasst die Sprungphysik außerdem einen Wall-Climb-Guard sowie eine Begrenzung der vertikalen Geschwindigkeit (Werte in @tab:physik). Die Hintergründe beider Mechanismen werden in der Iterationsdarstellung in Kapitel 7 erläutert (@sec:iterationen).

// TODO: jumpForce 10.5 und maxUpwardVelocity 8 sind die EFFEKTIVEN Werte aus
// Agent.prefab, die Script-Defaults weichen ab (9.0 / 7.0) — Kennzeichnung in
// @tab:physik beibehalten, optional Script-Defaults angleichen.

#figure(
  table(
    columns: 3,
    align: (left, center, left),
    [*Parameter*], [*Wert*], [*Anmerkung*],
    [turnSpeed], [180°/s], [],
    [moveSpeed], [5], [Bezugsgröße der Geschwindigkeits-Normierung (@tab:sensorspez)],
    [jumpForce], [10.5], [effektiver Wert aus Agent.prefab, Impuls nur bei Bodenkontakt],
    [maxUpwardVelocity], [8], [effektiver Wert aus Agent.prefab, begrenzt die vertikale Geschwindigkeit],
    [wallClimbMaxY], [5], [Wall-Climb-Guard (@sec:iterationen)],
    [Masse], [1], [Rotation um X- und Z-Achse fixiert (FreezeRotation)],
    [GroundCheck], [Raycast abwärts], [trifft Floor, Bridge, Platform, Goal, Bedingung für den Sprung],
  ),
  caption: [Bewegungs- und Sprungphysik des Agenten. jumpForce und maxUpwardVelocity sind die effektiven Werte aus Agent.prefab (Script-Defaults abweichend).],
) <tab:physik>

== Sensorik — und die begründete Wahl der Ray-Wahrnehmung <sec:sensorik>

Die Beschränkung auf Ray-basierte Wahrnehmung ist methodisch begründet. Erstens isoliert die einheitliche Ray-Sensorik aller drei Agenten die Wirkung der temporalen Architektur von der Wirkung des visuellen Encoders: Bei Kamera-Agenten wäre unklar, ob beobachtete Unterschiede aus dem Temporal-Modul oder aus dem CNN-Modul stammen. Zweitens erlaubt die niedrigdimensionale Ray-Repräsentation (Float-Vektoren statt Pixel-Arrays) deutlich kürzere Trainingszeiten und damit eine höhere Anzahl vollständiger Experiment-Wiederholungen — eine Voraussetzung statistischer Aussagekraft. Drittens liefern die typisierten Treffer der Detectable Tags direkt interpretierbare Information darüber, welcher Hindernistyp wahrgenommen wurde. In der Generalisierungsanalyse (@sec:generalisierung) lässt sich damit untersuchen, woran das Verhalten auf ungesehenen Karten scheitert (F3). Der ursprünglich erwogene Sensormodalitäts-Vergleich (Kamera, Sensor-Fusion) wird als zurückgestellte Erweiterung im Ausblick (@sec:ausblick) wieder aufgegriffen.

@tab:sensorspez spezifiziert den vollständigen Sensor- und Beobachtungssatz der drei Vergleichsagenten. Die Tabelle ist die autoritative und einzige Quelle dieser Spezifikation, alle übrigen Stellen der Arbeit verweisen hierher, ohne Werte zu wiederholen.

#show figure: set block(breakable: true)

#figure(
  table(
    columns: 4,
    align: (left, center, left, left),
    [*Komponente*], [*Dimension*], [*Inhalt*], [*Wertebereich*],
    [RayPerceptionSensor3D (horizontal)], [176], [11 Rays ($2 times 5 + 1$) über 120° (MaxRayDegrees 60), Reichweite 12, SphereCast 0.25, 6 Detectable Tags (Wall, Obstacle, Lava, Hole, Goal, Bridge), je Ray Tag-Kodierung, Trefferflag und normierte Distanz, stacked = 2], [$[0,1]$ (automatisch normalisiert)],
    [Boden-Sensor (manuell, VectorSensor)], [18], [9 Raycasts abwärts (Reichweite 2), Positionen unter/vorne 1--2/diagonal/seitlich, je \[Typ-Code, norm. Distanz\], Codes: Floor $+1$, Bridge $+0.5$, Hole $-0.5$, Lava $-1$, kein Treffer $-1.5$], [Typ-Code $[-1.5, 1]$, Distanz $[0,1]$],
    [Eigengeschwindigkeit], [3], [lokale Geschwindigkeit, normiert auf moveSpeed], [y nach oben auf $+1.6$ gekappt (maxUpwardVelocity/moveSpeed = 8/5), x, z und freier Fall ungeclampt],
    [Bodenkontakt], [1], [isGrounded-Flag], [${0,1}$],
    [Zieldistanz], [1], [Distanz zum Ziel / maxObservationDistance (20), ungeclampt], [$[0, approx 2.25]$],
    [Zielrichtung], [3], [normierter Richtungsvektor zum Ziel], [$[-1,1]$],
    [Wand-Raycasts], [4], [normierte Distanzen in vier Richtungen], [$[0,1]$],
    [Line-of-Sight], [1], [Sichtlinien-Flag zum Ziel], [${0,1}$],
  ),
  caption: [Vollständige Sensor- und Beobachtungsspezifikation der drei Vergleichsagenten (autoritative Quelle): 31 Vektor-Beobachtungen plus 176 Ray-Beobachtungen.],
) <tab:sensorspez>
// TODO: Zieldistanz-Obergrenze (ungeclampt, ~2.25) gegen den Code verifizieren —
// SSOT belegt nur "ungeclampt, > 1 ab Ist-Distanz > 20", keinen konkreten Maximalwert.

== Reward-System <sec:reward-system>

Die Belohnungsfunktion ist für alle drei Architekturen identisch (kontrollierte Variable des Vergleichs, Abschnitt 5.3) und wurde vor Beginn der Vergleichsläufe festgelegt (@tab:reward). Sie bildet damit die gemeinsame Zielvorgabe des Experiments. F1 und F2 sollen Unterschiede der Netzarchitektur messen, nicht des Belohnungsdesigns. Die Herleitung der einzelnen Terme sowie ihre beobachtete Wirkung sind bewusst nicht Gegenstand dieses Kapitels. Sie gehören zur Entstehungsgeschichte des Systems und werden in Kapitel 7 behandelt. Hier wird ausschließlich die gemeinsame, im Experiment unveränderte Belohnungsfunktion beschrieben.

Vom Belohnungssystem des Agenten zu unterscheiden ist das Curiosity-Signal, denn es ist kein Bestandteil der Reward-Funktion, sondern ein trainerseitiges intrinsisches Signal. In der Vergleichskonfiguration ist Curiosity in allen drei Behaviors aktiv, die Asymmetrie zwischen den Architekturen liegt in der Signalstärke. Diese Abweichung wird in @sec:yaml-abweichungen begründet und dokumentiert (@tab:yaml-abweichungen).

#figure(
  table(
    columns: 3,
    align: (left, left, left),
    [*Term*], [*Wert*], [*Anmerkung*],
    [Zielerreichung (goalReward)], [+30], [],
    [Tod durch Lava bzw. Loch], [−3], [lava-/holeDeathPenalty],
    [Timeout (timeoutPenalty)], [−10], [],
    [Schritt-Malus (stepPenalty)], [−0.002], [je Timestep],
    [Distanz-Shaping (PBRS)], [$F = ("prevDist" - gamma dot "currDist") dot "scale"$], [$gamma = 1.0$, scale = 0.01],
    [Lava-Sprung-Versuch], [+1.5], [degressiv: bei Wiederholung 1/4 bzw. 1/8 des Werts, danach 0],
    [Lava-Überquerung], [+8], [Der Bonus ist nominell Teil der eingefrorenen
Belohnungsfunktion; einer der beiden Auslösepfade ist
strukturell unerreichbar, der andere greift nur bei Zonen-Austritt
mit gleichzeitigem Bodenkontakt. Im Vergleichslauf wurde keine
Überquerung gezählt; der Zähler ist als Messartefakt zu
behandeln (@ProblemklasseC).],
    [Loch-Überflug], [−1], [],
    [Sichtlinie zum Ziel (Line-of-Sight)], [+0.005], [],
    [Wall-Climb], [−1], [vgl. @sec:iterationen],
    [phaseMaxSteps], [600 / 1200 (vier Phasen) / 1500 / 2000 / 2500], [maximale Episodenlänge je Curriculum-Phase (@tab:curriculum)],
    [Vergabe], [zentral im LabyrinthAgent], [externe Trigger (Lava, KillZone) melden ausschließlich über OnTriggerEnter],
  ),
  caption: [Belohnungsfunktion der drei Vergleichsagenten — identisch für alle Architekturen und vor den Vergleichsläufen eingefroren. Die Curiosity-Stärken je Behavior sind Teil der Trainer-Konfiguration und stehen in @tab:yaml-abweichungen.],
) <tab:reward>

== Trainingsinfrastruktur <sec:trainingsinfrastruktur>

Das Training läuft in einer Python-Umgebung (venv) mit ML-Agents 0.30.0, die für den Vergleich benötigte Transformer-Policy ist in dieser Version nicht enthalten und wird über ein Patch-Skript in die virtuelle Umgebung nachgerüstet. Der venv-Patch hält die Nachrüstung reproduzierbar und auf wenige, klar umrissene Eingriffe begrenzt. Begründung und Integrationsprozess dokumentiert @sec:transformer-integration.
Die Trainer-Konfigurationen unterscheiden sich systematisch zwischen den Architekturen. Maßgeblich für den Vergleich sind die beiden finalen Läufe `model_comparison_final_v2.yaml` und `model_comparison_final_v3.yaml`, die jeweils alle drei Behaviors (MLP, LSTM, Transformer) in einem einzigen Lauf trainieren. Welche Parameter über beide Läufe und alle drei Architekturen identisch gehalten werden, worin sich die Läufe unterscheiden und wie die architekturbedingten Abweichungen begründet sind, dokumentiert die Methodik in Abschnitt 5.3 (Tabellen @tab:identische-parameter und @tab:yaml-abweichungen). Die Bestandteile der Trainingsinfrastruktur fasst @tab:traininginfra zusammen.
// TODO: PyTorch-Version der Trainings-venv per "pip show torch" verifizieren und in
// @tab:traininginfra festschreiben (2.0.1+cu118 ist bislang nur in der Arbeitshilfe
// dokumentiert, der Segfault-Workaround-Kommentar in transformer_policy.py stützt 2.0.x).
// Die Export-venv nutzt separat torch 1.8.1+cpu — getrennt dokumentieren (bereits in
// @tab:traininginfra ausgewiesen).
// TODO: Hardware-Zeile in @tab:traininginfra ergänzen (CPU/GPU/RAM, Trainingsdauer) —
// stützt die Hardware-Anforderungen in Kapitel 9.
#figure(
  table(
    columns: 2,
    align: (left, left),
    [*Bestandteil*], [*Spezifikation*],
    [Trainings-venv], [`mlagents` 0.30.0],
    [Patch], [`training/patch_mlagents.py`: kopiert `transformer_memory.py`, erweitert `settings.py` und `networks.py`, `start_training.py` wendet den Patch automatisch an],
    [Export-venv], [separat (`setup_and_export.ps1`), `torch` 1.8.1+cpu],
    [Historische Solo-Konfigurationen (Meilenstein 7)], [`labyrinth_training.yaml` (PPO-Baseline: Lernrate 3e-4, Batch 512, Buffer 10 240, $gamma$ = 0.99, MLP 256 × 2, normalize false, max_steps 6.4 M), `labyrinth_transformer.yaml` (sequence_length 16, memory_size 128, Curiosity 0.05, $gamma$ = 0.997, max_steps 60 M), `labyrinth_lstm*.yaml`],
    [Vergleichslauf F1--F3 (maßgeblich)], [`model_comparison_final_v2.yaml` und `model_comparison_final_v3.yaml`: je drei Behaviors (MLP, LSTM, Transformer) in einem Lauf. Die identisch gehaltenen Basisparameter, die architekturbedingten Abweichungen und die Unterschiede zwischen v2 und v3 (Transformer-Hyperparameter, erreichte Schrittzahl, effektive num\_envs, venv-Stand) dokumentiert Abschnitt 5.3 (@tab:identische-parameter und @tab:yaml-abweichungen)],
    [Parallelisierung], [Multi-Area (@tab:mapgen) plus Headless-Prozesse über `--num-envs`,  je Worker ein eigener gRPC-Port und eine eigene Curriculum-State-Datei],
  ),
  caption: [Trainingsinfrastruktur: Umgebungen, Patch-Mechanismus und Konfigurationsebenen.],
) <tab:traininginfra>


// ============================================================================
// 5. METHODIK UND EXPERIMENTELLES DESIGN  — nach dem System
//ALLE ============================================================================
= Methodik und experimentelles Design

== Wissenschaftliche Rahmung <sec:rahmung>

Die Einleitung hat mit den Forschungsfragen F1–F3 sowie den zugehörigen Hypothesen H1–H3 den Untersuchungsrahmen dieser Arbeit definiert (siehe Abschnitt 1.4). Das Ziel der nachfolgenden Methodik besteht darin, diese Fragestellungen durch einen kontrollierten Vergleich der drei Netzwerkarchitekturen MLP, LSTM und Transformer empirisch zu beantworten.

Grundlage des Untersuchungsdesigns ist die Annahme, dass beobachtete Unterschiede zwischen den Agenten nur dann auf die Netzwerkarchitektur zurückgeführt werden können, wenn alle übrigen Randbedingungen konstant gehalten werden. Innerhalb eines Trainingslaufs ist diese Bedingung erfüllt: Die drei Architekturen durchlaufen als parallele Behaviors dieselbe Simulationsumgebung, dieselben Kartenlayouts und dasselbe Curriculum und werden anhand identischer Aufgabenstellungen bewertet. Unterschiede im Verhalten innerhalb desselben Laufs lassen sich damit auf die jeweilige Architektur zurückführen.

Der empirische Vergleich stützt sich auf zwei finale Vergleichsläufe (v2 und v3), deren Abgrenzung und Konfigurationsunterschiede in den Abschnitten 5.2 und 5.3 dokumentiert sind, weshalb die nachstehend definierten Metriken für jeden Lauf getrennt erhoben und die Hypothesen H1–H3 je Lauf geprüft werden.

Für jede Forschungsfrage wird eine geeignete Bewertungsgröße definiert. @tab:operationalisierung ordnet den Forschungsfragen die jeweils verwendeten Metriken, die zugehörigen Hypothesen, die erforderlichen Architekturvergleiche sowie die Abschnitte zu, in denen die Ergebnisse ausgewertet werden.

Die konkrete Definition dieser Metriken ist nicht Gegenstand dieses Abschnitts. Die Operationalisierung der Erfolgsrate, der Konvergenzgeschwindigkeit sowie der Generalisierungsmetriken erfolgt ausschließlich im Evaluationsprotokoll in @sec:evalprotokoll.

#figure(
  table(
    columns: 5,
    align: (left, left, left, left, left),
    [*Frage*], [*Metrik*], [*Hypothese*], [*zuständiger Vergleich*], [*beantwortet in*],
    [F1: Mehrwert temporalen Gedächtnisses], [Erfolgsrate (Definition: @sec:evalprotokoll)], [H1], [MLP vs. LSTM/Transformer], [@sec:architekturvergleiche],
    [F2: LSTM vs. Transformer], [Konvergenzgeschwindigkeit, finaler Leistungsscore (Definitionen: @sec:evalprotokoll)], [H2], [LSTM vs. Transformer], [@sec:architekturvergleiche],
    [F3: Generalisierung auf unbekannte Maps], [Overfitting-Index auf held-out Maps (Definition: @sec:evalprotokoll)], [H3], [alle drei Architekturen], [@sec:generalisierung],
  ),
  caption: [Operationalisierung der Forschungsfragen: Metrik, Hypothese, zuständiger Vergleich und Ergebnis-Abschnitt. Alle Metriken werden für beide finalen Läufe (v2 und v3) getrennt erhoben.],
) <tab:operationalisierung>

== Vergleichsdesign

Grundlage aller in @tab:operationalisierung dargestellten Vergleiche ist ein gemeinsames Vergleichsdesign. Die drei Agentenvarianten MLP, LSTM und Transformer werden nicht in voneinander getrennten Experimenten trainiert, sondern als parallele Behaviors (MLP_Navigator, LSTM_Navigator und Transformer_Navigator) innerhalb desselben Trainingslaufs ausgeführt.

Dadurch durchlaufen alle drei Architekturen dieselbe Simulationsumgebung, dieselben Kartenlayouts sowie denselben Trainingszeitraum. Unterschiede im beobachteten Verhalten innerhalb eines Laufs lassen sich somit nicht auf unterschiedliche Umgebungsbedingungen oder Trainingsphasen zurückführen, sondern auf die jeweilige Netzwerkarchitektur und die zu ihr gehörende, in Abschnitt 5.3 dokumentierte Konfiguration.

Methodisch handelt es sich um einen praxisnahen Architekturvergleich, nicht jedoch um eine strikte Ablationsstudie. Neben dem Gedächtnistyp unterscheiden sich mehrere architekturspezifische Hyperparameter. Die Ergebnisse beschreiben daher die Leistung der jeweils optimierten Gesamtkonfigurationen. Eine isolierte Aussage über den kausalen Effekt des Gedächtnismoduls allein ist auf Grundlage dieses Designs nicht möglich. Die MLP-Baseline ohne lernbares Sequenzgedächnis bildet die Variante, in der die Gedächtniskomponente entfernt ist, während LSTM und Transformer dieselbe Aufgabe mit temporalem Gedächtnis lösen. Der Beitrag des temporalen Gedächtnisses wird dadurch isoliert, dass zwischen Baseline und Gedächtnisarchitekturen gezielt diese eine Komponente variiert wird (F1). Die Gegenüberstellung von LSTM und Transformer variiert innerhalb der Gedächtnisarchitekturen zusätzlich den Gedächtnistyp und trennt so den Effekt der konkreten Gedächtnisrealisierung vom Effekt des Gedächtnisses an sich (F2).

Das Vergleichsdesign orientiert sich unmittelbar an den Forschungsfragen F1 bis F3. Für die Beantwortung von F1 wird die MLP-Baseline den beiden Gedächtnisarchitekturen LSTM und Transformer gegenübergestellt. F2 betrachtet ausschließlich die Unterschiede zwischen den beiden Gedächtnisarchitekturen. F3 bewertet schließlich die Generalisierungsfähigkeit aller drei Architekturen auf Kartenlayouts, die während des Trainings nicht verwendet wurden.

Diese Innerhalb-Lauf-Kontrolle gilt für jeden der beiden finalen Vergleichsläufe (v2 und v3) einzeln. Keiner der beiden Läufe stellt alle drei Architekturen gleichzeitig unter optimale Bedingungen: In v3 trainiert der Transformer mit seiner best-getunten Konfiguration über das volle Trainingsbudget, während der frühere Lauf final_v2 den Transformer noch mit einer nicht-optimalen Konfiguration und einem kürzeren Budget fährt. MLP und LSTM sind in beiden Läufen identisch konfiguriert. 

Welche Parameter im Vergleich bewusst identisch gehalten werden und an welchen Stellen architekturbedingte Abweichungen notwendig sind, wird im folgenden Abschnitt 5.3 dokumentiert. Der vorliegende Abschnitt beschreibt ausschließlich die grundsätzliche Vergleichslogik und nicht die konkrete Parametrisierung der Experimente.


== Kontrollierte Variablen und begründete Abweichungen

Das Grundprinzip des kontrollierten Vergleichs meint, dass sich zwischen den drei Architekturen innerhalb eines Trainingslaufs nur der Vergleichsgegenstand unterscheidet. Alles andere bleibt eingefroren. Diese Bedingung ist die Messgrundlage für die folgenden Unterabschnitte. Zwischen den drei Agenten darf sich nur der eigentliche Vergleichsgegenstand, also die Netzarchitektur unterscheiden, während alle anderen Bedingungen gleich bleiben. Innerhalb jedes einzelnen Laufs gilt sie uneingeschränkt. Zwischen den beiden finalen Läufen v2 und v3 gilt sie dagegen nicht vollständig. Über die Transformer-Konfiguration aus Abschnitt 5.3.2 hinaus unterscheiden sich die beiden Läufe auch in laufweiten Randbedingungen. Das betrifft das tatsächlich erreichte Trainingsbudget und die Trainingsumgebung, also den venv- beziehungsweise Framework-Stand und die Anzahl paralleler Umgebungen. Diese laufweiten Unterschiede wirken auf alle drei Architekturen gleichermaßen. Sie sind daher kein Bestandteil des architekturbezogenen Vergleichs. Ihre Konsequenz für die Auswertung wird in Abschnitt 5.5 behandelt.

=== Identische Parameter

Das Gleichhalten der Randbedingungen ist in zwei Ebenen umgesetzt.

Die erste Ebene ist die Umgebung und ist vollständig identisch, da alle drei Architekturen gleichzeitig im selben Trainingslauf trainieren. Das bedeutet, dass bei allen drei Architekturen die gleiche Szene, die gleichen Karten, das gleiche Curriculum mit exakt denselben Erfolgs-Gattern und Episodenlimits vorliegt. Ebenfalls teilen sich alle drei die gleiche Physik und die gleiche Belohnungsfunktion. Auch das Agentenskript und der Beobachtungsraum sind identisch, da jeder Agent dieselben 31 Vektorobservations inklusive Zielrichtungsvektor und dieselbe Ray-Sensorik bekommt. Auch Unterbrechungen und Neustarts während des Trainings wirken sich gleichermaßen auf alle aus.

Die zweite Ebene ist die Trainer-Konfiguration. Hier sind alle Parameter identisch, die nicht im nachfolgenden Abschnitt 5.3.2 als begründete Abweichung aufgeführt werden. Die folgende Tabelle listet ausschließlich die Parameter, die über alle drei Behaviors und über beide finalen Läufe unverändert sind.

#figure(
    block(width: 100%)[
      #set text(size: 8.5pt)
      #table(
        columns: (1.9fr, 1.6fr, 2.7fr),
        align: (left + horizon, left + horizon, left + horizon),
        inset: (x: 5pt, y: 4pt),
        stroke: 0.5pt + luma(210),
        table.header(
          [Parameter], [Wert (alle drei Behaviors)], [Bedeutung],
        ),
        [trainer\_type], [ppo],
          [verwendeter RL-Algorithmus (Proximal Policy Optimization)],
        [epsilon (PPO-Clipping)], [0.2],
          [begrenzt, wie stark sich die Policy pro Update ändern darf],
        [lambd (GAE)], [0.95],
          [Bias-Varianz-Abwägung bei der Vorteilsschätzung (Generalized Advantage Estimation)],
        [num\_epoch], [3],
          [wie oft dieselben gesammelten Daten je Update wiederverwendet werden],
        [hidden\_units / num\_layers (Encoder)], [256 / 2],
          [Breite und Tiefe des gemeinsamen Encoder-Netzes vor Policy und Critic],
        [sequence\_length (LSTM und Transformer)], [16],
          [Länge der Zeitfenster, über die das Gedächtnis zurückblickt (16 Entscheidungen)],
        [extrinsic strength], [1.0],
          [Gewicht des aufgabenbezogenen (extrinsischen) Belohnungssignals],
        [Curiosity: gamma / Lernrate / Netz], [0.99 / 3e-4 / 128 × 2],
          [intrinsisches Explorationssignal (belohnt Neuartiges): Discount / eigene Lernrate / eigenes Netz. Das Gewicht (strength) ist nur in v2 über alle drei Behaviors identisch und wird in v3 zur Transformer-Abweichung (Abschnitt 5.3.2)],
        [seed], [42],
          [Zufalls-Startwert zur Reproduzierbarkeit des Laufs. In beiden Läufen identisch (ein einziger Trainings-Seed, siehe Abschnitt 5.5)],
        [summary\_freq / checkpoint\_interval / keep\_checkpoints], [10.000 / 200.000 / 5],
          [Takt für TensorBoard-Logging / Checkpoint-Speicherung / Anzahl behaltener Checkpoints],
        [threaded], [true],
          [Umgebungs-Sampling läuft parallel zum Policy-Update (höherer Durchsatz)],
        [max\_steps (Trainingsbudget)], [30.000.000 (Planwert)],
          [geplantes Trainingsbudget je Agent. Erreicht wurden in v2 rund 16,6 Mio. Schritte (Stopp nach fünf Curriculum-Loops) und in v3 volle 30 Mio. Schritte],
        [num\_envs / time-scale], [3 / 40 (v2), 5 / 40 (v3 effektiv)],
          [Anzahl paralleler Umgebungen / Simulationsbeschleunigung. Über die drei Behaviors identisch, aber laufweit verschieden. In v3 wurde num\_envs zur Laufzeit auf 5 gesetzt],
      )
    ],
    caption: [Trainer-Parameter, die über alle drei Behaviors und über beide finalen Läufe (v2 und v3) identisch sind. Bei max\_steps und num\_envs ist der Wert über die Behaviors identisch, unterscheidet sich aber zwischen den Läufen.],
  ) <tab:identische-parameter>

=== Notwendige und bewusste Abweichungen und ihre Begründung <sec:yaml-abweichungen>

// EINZIGE HEIMAT der Abweichungsliste. Andere Abschnitte verweisen nur
// hierher (@tab:yaml-abweichungen), keine Kopien. Volle YAMLs im Anhang.

Die Trainer-Konfigurationen der drei Architekturen sind nicht zu 100 % identisch. Die Abweichungen zerfallen in zwei Klassen. Zwingend erforderlich ist einzig und allein memory_type. Ohne diesen Parameter gäbe es keinen Vergleichsgegenstand. Man kann Transformer und LSTM nicht vergleichen, ohne den Gedächtnistyp zu ändern. Jeden einzelnen Parameter anzugleichen wäre an dieser Stelle nicht fairer, sondern sinnlos. Alle weiteren Unterschiede sind dagegen nicht zwingend, sondern eine bewusste Entscheidung. Jede Architektur trainiert mit den Hyperparametern, die sich in ihrer eigenen Optimierung als am besten erwiesen haben.

MLP und LSTM werden in beiden finalen Läufen mit identischer Konfiguration gefahren. Der Transformer wird dagegen in zwei Konfigurationen geführt. Die in Lauf final_v3 verwendete Konfiguration ist die best-getunte Variante. Sie ist das Ergebnis der in Abschnitt 5.4 dokumentierten Tuning-Iterationen. Für sie gilt der Begriff „Best vs. Best". Der frühere Lauf final_v2 verwendet für den Transformer eine nicht-optimale Konfiguration. Für diese Architektur handelt es sich in v2 also gerade nicht um einen Best-vs-Best-Vergleich. Beide Konfigurationen werden ausgewiesen, weil beide Läufe berichtet werden. Die Konsequenzen für die Interpretation stehen in Abschnitt 5.5. Die folgende Tabelle listet sämtliche Abweichungen. Die vier Parameter, in denen sich die Transformer-Konfiguration zwischen final_v2 und final_v3 unterscheidet, sind hervorgehoben.

// TODO ALEX: d_model / Kopfzahl (256 / 4 à 64) gegen die Transformer-Implementierung
// prüfen und ggf. in die memory_size-Begründung aufnehmen. In der SSOT nicht belegt.

#figure(
    block(width: 100%)[
      #set text(size: 7.5pt)
      #table(
        columns: (1.3fr, 0.5fr, 0.5fr, 0.75fr, 0.75fr, 2.3fr),
        align: (left + horizon, center + horizon, center + horizon, center + horizon, center + horizon, left + horizon),
        inset: (x: 4pt, y: 4pt),
        stroke: 0.5pt + luma(210),
        table.header(
          [Parameter], [MLP], [LSTM], [Transf. (v2)], [Transf. (v3)], [Begründung],
        ),
        [memory\_type], [—], [lstm], [transformer], [transformer],
          [konstitutiv, definiert den Vergleichsgegenstand],
        [memory\_size], [—], [256], [128], [128],
          [jeweils erprobte Gedächtnisdimensionierung],
        [learning\_rate], [3e-4], [3e-4], [1e-4], [1e-4],
          [eine höhere Lernrate destabilisierte den Transformer],
        [batch\_size], [512], [512], [1024], [1024],
          [größere Batches glätten die Attention-Gradienten],
        [buffer\_size], [40960], [40960], [81920], [81920],
          [folgt der Batch-Größe],
        [beta], [5e-3], [5e-3], [1.0e-3], [*5.0e-4*],
          [Entropie-Regularisierung. In v3 weiter abgesenkt zur Stabilisierung der Transformer-Konvergenz],
        [beta\_schedule], [—], [—], [—], [*constant*],
          [in v3 konstant gehalten statt implizit linear abklingend],
        [learning\_rate\_schedule], [linear], [linear], [linear], [*constant*],
          [eine konstante Lernrate stabilisiert den Transformer in v3],
        [curiosity.strength], [0.05], [0.05], [0.05], [*0.02*],
          [schwächeres intrinsisches Explorationssignal in v3],
        [time\_horizon], [512], [512], [256], [256],
          [kürzere Trajektorienabschnitte passend zum Attention-Fenster],
        [gamma], [0.995], [0.995], [0.997], [0.997],
          [längerer Planungshorizont des Transformers],
        [normalize], [false], [true], [false], [false],
          [Normalisierung stabilisiert den LSTM-Encoder bei wechselnden Kartengrößen (Abschnitt 7.3)],
      )
    ],
    caption: [Abweichungen der Trainer-Konfigurationen zwischen den Architekturen für beide finalen Läufe (v2 und v3). MLP und LSTM sind über beide Läufe identisch. Der Transformer wird in zwei Konfigurationen geführt. Fett markiert sind die vier Parameter, in denen sich v2 und v3 beim Transformer unterscheiden. Alle übrigen Parameter sind identisch (Abschnitt 5.3.1).],
  ) <tab:yaml-abweichungen>

// TODO ALEX: Begründungsspalte je Zeile gegen die YAML-Kommentare schärfen
// (welches konkrete Stabilitäts-/Tuning-Argument steckt hinter jedem Wert?)

== Abweichung in Tuning-Iterationen <sec:tuning-abweichungen>

Nachdem in den vorangegangenen Abschnitten die kontrollierten Variablen beschrieben wurden, dokumentiert dieser Abschnitt die im Verlauf der Arbeit durchgeführten Tuning-Iterationen und die dabei aufgetretenen Abweichungen zwischen erwartetem und tatsächlich beobachtetem Trainingsverhalten. Wie Belohnungsfunktion, Beobachtungsraum, Netzarchitektur und Hyperparameter zusammenwirken, lässt sich im Vorfeld nur begrenzt vorhersagen, das tatsächliche Agentenverhalten zeigt sich erst im Experiment. Die systematische Dokumentation der dabei auftretenden Abweichungen macht daher transparent, welche Entwurfsentscheidungen sich bewährt haben, welche verworfen wurden und aus welchen Gründen ist sie damit Bestandteil der wissenschaftlichen Nachvollziehbarkeit dieser Arbeit.

Der Tuning-Aufwand verteilt sich dabei sehr ungleich auf die drei Architekturen: Die MLP-Baseline kam ohne eigene Tuning-Iterationen aus, die LSTM-Integration erforderte eine einzelne Korrektur-Runde und eine kurze Abstimmungsserie, der Transformer durchlief dagegen 22 dokumentierte Iterationen. Diese Asymmetrie ist nicht methodischer Nachlässigkeit geschuldet, sondern strukturell bedingt: Der Iterationsbedarf wächst mit dem Abstand einer Architektur zu den nativ im ML-Agents-Framework vorgesehenen Integrationspfaden. Die technische Entstehungsgeschichte der einzelnen Iterationen dokumentieren die Integrationsabschnitte @sec:mlp-integration, @sec:lstm-integration und @sec:transformer-integration. Der vorliegende Abschnitt beschreibt zunächst das einheitliche Bewertungsschema und ordnet anschließend für jede Architektur ein, warum der jeweilige Aufwand entstand und welche Abweichungen dabei auftraten.

=== Vorgehensweise und Bewertungsgrundlage

Jede Tuning-Iteration wurde nach einem einheitlichen Schema durchgeführt und bewertet. Ausgehend von einer Hypothese über eine erwartete Verbesserung wurde eine Konfigurationsänderung vorgenommen, ein Trainingslauf gestartet und dessen Verlauf anhand der über TensorBoard protokollierten Metriken analysiert. Als Bewertungsgrundlage dienten dabei der durchschnittliche kumulierte Episoden-Reward (Environment/Cumulative Reward) als Hauptindikator, dessen Standardabweichung als Maß für die Stabilität der Policy, die mittlere Episodenlänge sowie ergänzend die Verlustgrößen des Trainings (Policy Loss, Value Loss) und die Entropie der Policy als Indikator für den Explorationsgrad. Eine Abweichung liegt im Sinne dieses Abschnitts immer dann vor, wenn das beobachtete Verhalten von der zuvor formulierten Erwartung abweicht, unabhängig davon, ob die Abweichung negativ oder positiv ausfällt. 

=== Iterationen der MLP-Baseline

Für die MLP-Baseline waren keine architekturspezifischen Tuning-Iterationen erforderlich, sodass ihre einmal aus den PPO-Standardwerten abgeleitete Konfiguration unverändert in beide finalen Läufe (v2 und v3) einging, während sich die erwarteten Grenzen der gedächtnislosen Policy (@sec:mlp-erwartungen) erst im Ergebnis zeigen (@sec:eval-mlp-baseline) und die native Framework-Integration als Ursache des geringen Aufwands in @sec:mlp-integration behandelt wird.

=== Iterationen der LSTM-Integration

Die LSTM-Integration nimmt beim Tuning-Aufwand eine Mittelstellung ein. Zwar bringt ML-Agents eine native LSTM-Unterstützung mit, aus Gründen der Vergleichbarkeit wurde das Gedächtnismodul jedoch als eigene Implementierung über denselben venv-Patch eingebunden wie die Transformer-Policy (@sec:lstm-integration). Der Iterationsbedarf blieb dennoch gering, weil dieser Integrationspfad durch die Transformer-Arbeiten bereits etabliert war und die rekurrente Arbeitsweise des LSTM den Sequenz-Annahmen des Frameworks entspricht.

Die aufgetretenen Abweichungen blieben auf der Integrations- und Messebene: Der erste Lauf lstm_v1 brach infolge von Verdrahtungsfehlern der Integrationsschicht unmittelbar nach dem Start ab und wurde in einer einzigen Korrektur-Runde behoben, die anschließende Serie lstm_v2 bis lstm_v7b diente der Absicherung der Konfigurationsbasis, insbesondere der Balance zwischen Todesstrafen und Zielprämie. Keine dieser Beobachtungen erforderte einen Eingriff in die Architektur oder den Integrationsmechanismus selbst, und die resultierende Konfiguration ging unverändert in die finale Vergleichskonfiguration ein. Die einzelnen Läufe, Fehlerbilder und daraus abgeleiteten Entscheidungen dokumentiert @sec:lstm-integration. Die finale Vergleichskonfiguration ging unverändert in beide finalen Läufe ein.  



=== Iterationen der Transformer-Integration

Der mit Abstand größte Iterationsbedarf entfiel auf den Transformer. Anders als MLP und LSTM ist er in der eingesetzten ML-Agents-Version nicht als Policy-Architektur vorgesehen und musste über einen Patch der Python-Trainingsumgebung nachgerüstet werden (@sec:transformer-integration). Jede Anpassung dieser Integration erzeugte zusätzlichen Iterationsbedarf, da sich Implementierungsfehler und Hyperparameter-Effekte zunächst nicht voneinander trennen ließen. Ein ausbleibender Lernfortschritt konnte gleichermaßen auf einen Fehler in der nachgerüsteten Sequenzverarbeitung wie auf eine ungeeignete Konfiguration zurückgehen.

Insgesamt durchlief der Transformer 22 dokumentierte Iterationen (V1 bis V22), deren Abweichungen sich vier Problemklassen zuordnen lassen. Diese sind Framework- und Engine-Einschränkungen, Inkonsistenzen zwischen Inferenz und Training, Pathologien des Belohnungs- und Curriculum-Designs sowie Konfigurations-Drift zwischen Unity und Python. Exemplarisch für Abweichungen im Sinne dieses Abschnitts stehen ein Langzeitlauf ohne jeden Lernfortschritt, dessen Diagnose auf eine Inkonsistenz der Sequenzverarbeitung zwischen Inferenz und Training führte, sowie scheinbar hohe Episoden-Rewards, die sich als Artefakt des Reward-Shapings und nicht als Navigationserfolg erwiesen. Die einzelnen Iterationen, ihre Hypothesen und die belegten Kennzahl-Wirkungen fasst die verdichtete Übersicht in @sec:iterationen zusammen. Der Kontrast zwischen genau einem komplikationslosen Baseline-Lauf und dieser Iterationshistorie ist zugleich der empirische Beleg für die eingangs beschriebene Asymmetrie. Sie spiegelt nicht unterschiedliche Sorgfalt wider, sondern den unterschiedlichen Reifegrad der Framework-Integration der drei Architekturen.

Das Ergebnis dieser Iterationen ist die best-getunte Transformer-Konfiguration, die im finalen Lauf final_v3 zum Einsatz kommt. Sie umfasst die vier Werte, die den v3-Transformer von der v2-Fassung unterscheiden. Das sind ein abgesenktes beta, ein konstantes beta_schedule, eine konstante learning_rate_schedule und eine reduzierte curiosity.strength (@tab:yaml-abweichungen). Der frühere finale Lauf final_v2 fuhr den Transformer dagegen noch mit einer nicht-optimalen Konfiguration, die vor Abschluss dieser Iterationen entstand. Warum trotzdem beide Läufe berichtet werden und wie sich das auf die Interpretation auswirkt, behandelt Abschnitt 5.5.



== Evaluationsprotokoll <sec:evalprotokoll>
Der zentrale Erfolgsmaßstab ist die Erfolgsrate, verstanden als Anteil der Episoden, in denen der Agent das Ziel erreicht. Als Fehlschlag gilt jede Episode, in der der Agent in Lava oder ein Loch fällt oder in der die Zeitgrenze überschritten wird. Ermittelt wird dieser Wert nicht aus dem laufenden Training, sondern aus separaten Evaluationsläufen, die nach Abschluss des Trainings im Inferenzmodus auf einem zurückgehaltenen Kartensatz durchgeführt werden. Dieselbe Auswertung wird auf beide finalen Checkpoint-Sätze angewandt, also auf den Lauf final_v2 und den Lauf final_v3, und verwendet für beide dieselbe Testharness, dieselbe Szene, dieselben 155 Karten und dieselben paarweisen Seeds. Für v3 werden die Checkpoints zuvor von CUDA auf CPU konvertiert. Die Inferenz erfolgt für alle drei Architekturen einheitlich in Python über denselben Evaluations-Build. Ausschlaggebend für diese Entscheidung ist, dass der Transformer unter Barracuda nicht lauffähig ist (@sec:framework-workarounds). Die einheitliche Laufzeitumgebung stellt zugleich sicher, dass Laufzeitunterschiede der Inferenz-Engines das Vergleichsergebnis nicht beeinflussen.

Auf derselben Erfolgsgröße setzt die Konvergenzgeschwindigkeit auf. Die Konvergenzgeschwindigkeit erfasst, wie rasch ein Modell verlässlich erfolgreich agiert, und misst dazu die kumulierten Behavior-Steps bis zu dem Punkt, an dem die rollierende Erfolgsrate im gleitenden Fenster 80 Prozent überschreitet. Bleibt diese Schwelle unerreicht, wird der Wert rechtszensiert. Der finale Leistungsscore beschreibt hingegen das erreichte Leistungsniveau und entspricht dem mittleren kumulativen Episoden-Reward. Dieser Reward stammt aus der trainingsseitigen Aufzeichnung und nicht aus den Evaluationsläufen, weil deren Ausgabedaten keinen Reward enthalten.

Wie stark ein Modell auf die Trainingskarten zugeschnitten ist, drückt der Overfitting-Index aus. Er wird je Schwierigkeitskategorie gebildet, indem von der Trainings-Erfolgsrate die Erfolgsrate auf dem zurückgehaltenen Kartensatz abgezogen wird, wobei auf der Trainingsseite der Erfolg im Endzustand und nicht der zwischenzeitliche Höchstwert eingeht. Für die Kategorie Giant bleibt der Index undefiniert, weil kein trainingsseitiges Gegenstück existiert.

Die Aussagekraft dieser Generalisierungswerte hängt unmittelbar davon ab, dass der Evaluationssatz sauber vom Training getrennt ist. Er umfasst 155 zurückgehaltene Karten, die sich auf 50 einfache, 50 mittlere, 50 schwere und 5 Giant-Karten verteilen und im Training nicht vorkommen. Diese Trennung beruht nicht auf dem Zeitpunkt der Kartenerzeugung, sondern auf disjunkten Zufallsseeds. Maßgeblich ist, dass die Evaluationskarten ab dem Seed-Basiswert 900000 erzeugt werden und damit außerhalb der im Training vergebenen Curriculum-Seeds ab 42000 liegen, während der Kartengenerator auf einem Seed-Raum von 0 bis 999999 arbeitet.

=== Primärmetriken
Die maßgebliche Erfolgsrate stammt aus der separaten Held-out-Evaluation im Inferenzmodus, während ihr zeitlicher Verlauf über die Größen SuccessRate und RollingSuccessRate aus TensorBoard abgelesen wird. Aus derselben rollierenden Trajektorie ergibt sich die Konvergenzgeschwindigkeit. Der finale Leistungsscore bleibt eine trainingsseitige Größe und wird über den kumulativen Reward in TensorBoard bestimmt, da die Ausgabedaten der Evaluationsläufe keinen Reward enthalten.

Alle Primärmetriken werden je Lauf ausgewiesen. Besonders der finale Leistungsscore ist zu beachten, denn der mittlere kumulative Reward fällt zwischen final_v2 und final_v3 deutlich unterschiedlich aus und wird deshalb nicht als lauf-übergreifende Einzelzahl dargestellt.

Eine Kollisionsrate lässt sich nicht ausweisen, weil dafür keine Instrumentierung vorliegt und weder ein Kollisionsereignis noch ein Zähler erfasst wird. Sie entfällt deshalb als Metrik. Zur inhaltlichen Deutung des Agentenverhaltens steht demgegenüber eine Reihe aus TensorBoard ableitbarer Diagnosegrößen bereit. Zu ihnen zählen die mittlere Episodenlänge (trainingsseitige Größe EpisodeLength, für erfolgreiche Episoden um StepsToGoal ergänzt), die Todesursachen nach Lava, Loch und Timeout, die verbleibende Distanz zum Ziel und der Distanzfortschritt. Das Verhalten an riskantem Terrain wird über Lava-Überquerungen und -Versuche, Loch-Überflüge, Wandkletterkontakte und die Zahl der Sprünge je Episode erfasst und um den Trainingsschritt der ersten Lava-Überquerung ergänzt. Die Belohnungsstruktur bilden die aufsummierten Reward-Anteile aus Sichtlinie und potentialbasiertem Reward-Shaping ab, und der Fortschritt im Curriculum zeigt sich in der jeweiligen Curriculum-Phase samt den Erfolgsraten je Phase und Gate.

Die beiden zentralen Fragestellungen beantwortet allein der zurückgehaltene Kartensatz, der für alle drei Architekturen identisch ist und paarweise faire Seeds vorgibt. Die Trainings-Erfolgsrate dient dagegen nur als Verlaufs- und Sekundärgröße und darf nicht als Leistung auf ungesehenen Karten gedeutet werden. Der Grund liegt im Aufbau des Trainings, denn der schwere Kartenpool umfasst lediglich 192 Layouts, die im Round-Robin-Verfahren wiederholt durchlaufen werden. Bei einem Schwellenwert von 20000 ergeben sich rund 104 Wiederholungen je Layout, und über die Phasenschleife kehrt das Curriculum vom schweren zurück in den einfachen Bereich. Ein Modell begegnet den Trainingskarten somit vielfach, weshalb sich die Generalisierungsleistung einzig über den zurückgehaltenen Satz nachweisen lässt.

=== Konvergenzmetrik (F2)

Als Konvergenzindikator wird die in TensorBoard protokollierte RollingSuccessRate verwendet. Diese Größe wird trainingsseitig über ein Fenster von 50 Episoden gebildet. Das Curriculum-Gate verwendet davon unabhängig ein successWindow von 200 Episoden; dieser Wert wird nicht als TensorBoard-Konvergenzfenster interpretiert.

Für jede Architektur werden die höchste erreichte rollierende Erfolgsrate und der zugehörige Trainingsschritt berichtet. Eine Architektur gilt im Rahmen dieser Arbeit nur dann als konvergiert, wenn die RollingSuccessRate die Schwelle von 80 % erreicht. Bleibt der höchste beobachtete Wert unterhalb dieser Schwelle, wird der Lauf am Ende seines tatsächlich ausgeführten Trainingsbudgets rechtszensiert. Eine zusätzliche Nachhaltigkeitsbedingung über mehrere nachfolgende 200-Episoden-Fenster wird nicht ausgewertet, da sie aus den vorliegenden TensorBoard-Daten nicht konsistent rekonstruierbar ist.

=== Generalisierungs- / Overfitting-Metrik
// - Held-out-Maps: nie im Training, Nachweis über Seed-Disjunktheit (SEED_BASE 900000
//   disjunkt zu Curriculum 42000+ / MapGen Random 0-999999) [§13.2]
// - zusätzliche OOD-Stufe Giant (DifficultyLevel=9, Grid 40-50x48-60 vs. Hard-max 37x45)
//   [§13.2] -> testet über die max. Trainingsschwierigkeit hinaus
// - Overfitting-Index := Trainings-Erfolgsrate - Held-out-Erfolgsrate, je Kategorie
//   UND je Lauf (v2 und v3 getrennt) [§13.3/§13.4]:
//   * Minuend = ENDSTAND-Trainingserfolg je passender Phase (Easy=P5/Med=P6/Hard=P7),
//     NICHT Beste-Success (Peak) [§13.5]
//   * bevorzugt: identische Harness auf Stichprobe TRAININGS-Maps -> exakt gleiches
//     Protokoll, nur Map-Set unterscheidet sich  // FIXIEREN: gleiche Harness vs. TB-Log
//   * v2-LSTM-Lücke ~0 [§13.3], v3-LSTM-Lücke extrem: Training-Rolling ~57,5%
//     vs. Held-out 4-8% [§13.4 Z.571]
//   * Deutung späte Instabilität vs. Überanpassung = HYPOTHESE
//     (SSOT: "konsistent mit", nicht bewiesen, nur 1 Seed)
//   * Giant: kein Trainings-Pendant -> Overfitting-Index undefiniert, nur absolute
//     OOD-Erfolgsrate

Die Generalisierungsmessung stützt sich auf die bereits eingeführten Held-out-Maps, die über disjunkte Seeds vom Training getrennt sind und deshalb das Modellverhalten auf zuvor nicht gesehenen Karten prüfen.

Aus dem Vergleich beider Kartenmengen entsteht die eigentliche Overfitting-Metrik. Sie wird je Lauf und je Schwierigkeitskategorie gebildet. Pro Kategorie ergibt sich der Overfitting-Index als Trainings-Erfolgsrate minus Held-out-Erfolgsrate und beschreibt damit den Abstand zwischen der Leistung auf Trainings- und Evaluationskarten. Als Trainings-Erfolgsrate dient der Endstand der geloggten Trainingskurve der passenden Phase, also P5 für Easy, P6 für Medium und P7 für Hard, und nicht der beste zwischenzeitlich erreichte Wert. Die Held-out-Erfolgsrate stammt aus der Auswertung auf den Evaluationskarten.

Beim LSTM bleibt die Lücke in v2 nahezu bei null, während sie in v3 sehr groß ausfällt, denn dort steht eine rollierende Trainings-Erfolgsrate von rund 57,5 Prozent einer Held-out-Erfolgsrate von nur 4 bis 8 Prozent gegenüber. Ob dieser Abstand auf eine späte Instabilität oder auf eine Überanpassung zurückgeht, bleibt eine Hypothese, denn die Quelllage beschreibt den Befund als mit beiden Deutungen konsistent, ohne eine davon zu belegen, und es liegt nur ein einziger Seed vor.

Über die im Training abgedeckte Schwierigkeit hinaus kommt eine zusätzliche OOD-Stufe namens Giant zum Einsatz. Sie entspricht dem DifficultyLevel 9 und verwendet Grids von 40 bis 50 auf 48 bis 60, die das Hard-Maximum von 37 auf 45 überschreiten und das Modell so über die maximale Trainingsschwierigkeit hinaus fordern. Da für diese Stufe kein Trainings-Pendant existiert, lässt sich der Overfitting-Index nicht bilden, weshalb ausschließlich die absolute OOD-Erfolgsrate berichtet wird.

=== Statistische Auswertung
// Design ist GEPAART (identische Seeds/Maps über alle 3 Architekturen, §13.2)
// -> gepaarte/geblockte Tests, NICHT Mann-Whitney U (unabhängige Gruppen).
// - je LAUF getrennt rechnen: v2 und v3 NICHT poolen (untersch. Config/Budget/venv)
// - Einheit: Held-out-Map (nicht Einzel-Episode -> Pseudoreplikation vermeiden),
//   n=50 Easy/Med/Hard, n=5 Giant (nur deskriptiv)
// - Test: Friedman (3 Architekturen/Kategorie) -> Post-hoc Wilcoxon signed-rank
//   (paarweise, gepaart), Bonferroni
// - Effektstärke: matched-pairs rank-biserial r (Cliff's Delta nur ungepaart)
// - 95%-KI: gepaarter/Cluster-Bootstrap durch Map-Resampling, auf Erfolgsrate je
//   Kategorie UND auf Architektur-Differenz
// - Bonferroni: Vergleichsfamilie explizit deklarieren (alpha'=0.005 setzt 10 Tests
//   voraus, In-Distribution 3x3=9 -> alpha'~0.0056)                              // FIXIEREN Familie + alpha'
// - v2/v3-Divergenz NICHT durch Seeds (beide 42) [§9.2], sondern Budget/venv/Stochastik
//   + beim Transformer Konfigurationsänderung [§13.5]
// - beide Läufe vollständig für alle 3 Architekturen berichten [§13.3/§13.4],
//   NICHT "LSTM aus v2 + Transformer aus v3" mischen (Rosinenpickerei, verdeckt Rang-Umkehr)
// - VORBEHALT: 1 Trainings-Seed (42) [§9.2, §12-#4] -> Aussage gilt für DIESE
//   Modellinstanzen (Map-Ebenen-Generalisierung), nicht "Architektur im Erwartungswert
//   über Seeds", v2/v3-Divergenz = Reproduzierbarkeits-Signal, kein Seed-Sweep [§13.6-#4]

Als Analyseeinheit dient die einzelne Held-out-Karte und nicht die einzelne Episode. Behandelte man Episoden als unabhängige Datenpunkte, käme es zu einer Pseudoreplikation, weil mehrere Episoden auf derselben Karte denselben strukturellen Kontext teilen und deshalb keine voneinander unabhängigen Beobachtungen darstellen. Für die Kategorien Easy, Medium und Hard liegen jeweils 50 Karten vor, während die fünf Giant-Karten wegen ihrer geringen Zahl ausschließlich deskriptiv betrachtet werden. Die gesamte Auswertung erfolgt je Lauf getrennt. Die Begründung, warum v2 und v3 nicht zusammengefasst werden, ist in Abschnitt 5.3 dargelegt.

Das Auswertungsdesign ist gepaart, da alle drei Architekturen auf identischen Karten und mit identischen Seeds evaluiert werden. Jede Karte liefert dadurch drei direkt vergleichbare Messwerte, deren Differenzen unmittelbar interpretierbar sind. Diese Blockstruktur schließt Verfahren für unabhängige Stichproben aus, insbesondere den Mann-Whitney-U-Test, dessen Annahme unabhängiger Gruppen hier verletzt wäre. Pro Schwierigkeitskategorie vergleicht stattdessen der Friedman-Test die drei Architekturen simultan. Weist er einen Unterschied nach, folgen paarweise Wilcoxon-Vorzeichen-Rang-Tests als Post-hoc-Verfahren, die die gepaarte Struktur der Daten berücksichtigen und über eine Bonferroni-Korrektur gegen die Kumulierung des Alphafehlers bei multiplen Vergleichen abgesichert werden.

Die Effektstärke wird über die matched-pairs-Variante der rangbiserialen Korrelation r bestimmt, die zur gepaarten Logik der Wilcoxon-Tests passt. Cliff's Delta bleibt ungenutzt, da es für den Vergleich unabhängiger Gruppen konzipiert ist und die paarweise Zuordnung der Messwerte nicht abbilden kann. Die zugehörigen 95-Prozent-Konfidenzintervalle stammen aus einem gepaarten Cluster-Bootstrap, bei dem auf Kartenebene resampelt wird. Dieses Vorgehen erhält die Blockstruktur, weil jede gezogene Karte ihre drei Architekturmesswerte gemeinsam beibehält. Berechnet werden die Intervalle sowohl für die Erfolgsrate je Kategorie als auch für die Differenzen zwischen den Architekturen.

Die Bonferroni-Korrektur verlangt, dass die Vergleichsfamilie explizit festgelegt wird, weil das korrigierte Signifikanzniveau direkt von der Anzahl der Tests innerhalb dieser Familie abhängt. Für die In-Distribution-Vergleiche umfasst die Familie neun Tests, die aus den drei paarweisen Architekturvergleichen in jeder der drei inferenzstatistisch ausgewerteten Kategorien hervorgehen. Bei einem Ausgangsniveau von 0,05 ergibt sich daraus ein korrigiertes Niveau von α' = 0,05 / 9 ≈ 0,0056. Ein Niveau von 0,005 würde demgegenüber eine Familie von zehn Tests voraussetzen und entspräche damit nicht der tatsächlichen Anzahl der In-Distribution-Vergleiche.

Einschränkend bleibt festzuhalten, dass alle Modelle auf einem einzigen Trainings-Seed 42 beruhen, der für v2 und v3 identisch ist. Die statistischen Aussagen gelten deshalb für die konkret trainierten Modellinstanzen und beschreiben deren Generalisierung auf der Ebene neuer Karten. Eine Aussage über die jeweilige Architektur im Erwartungswert über verschiedene Seeds lassen sie nicht zu, da hierfür ein systematischer Seed-Sweep nötig wäre. Die beobachtete Divergenz zwischen final_v2 und final_v3 geht folglich nicht auf verschiedene Seeds zurück, denn beide verwenden Seed 42, sondern auf Unterschiede in Budget, virtueller Umgebung und Stochastik sowie beim Transformer auf eine Konfigurationsänderung. Sie ist als Signal für die Reproduzierbarkeit zu verstehen und ersetzt keinen Seed-Sweep.

Methodisch ist sicherzustellen, dass beide Läufe vollständig und für alle drei Architekturen berichtet werden. Ergebnisse verschiedener Läufe dürfen nicht zu einem künstlichen Best-of-Vergleich zusammengesetzt werden, da sich die Läufe hinsichtlich Trainingsbudget, Ausführungsumgebung und teilweise der Trainerkonfiguration unterscheiden.



// ============================================================================
// 6. MODELLARCHITEKTUREN  — die konkrete Antwort auf die Frage aus 2.4
//katya, Finn, Alex ============================================================================
= Modellarchitekturen


== MLP-Baseline <sec:mlp-baseline>

Die Aufgabenstellung der vorliegenden Arbeit fordert neben dem Transformer-basierten Entscheidungsmodell explizit den Vergleich mit einer einfachen Basisvariante. Diese Rolle übernimmt die in diesem Abschnitt beschriebene MLP-Baseline: ein Agent, dessen Entscheidungsmodell aus einem einfachen Multilayer-Perzeptron ohne jede Form von Gedächtnis besteht. Das MLP besitzt kein lernbares internes Sequenzgedächtnis. Durch das zweifache Stacking der Ray-Beobachtungen erhält es jedoch einen festen, auf zwei Sensorframes begrenzten zeitlichen Kontext. Der Begriff „gedächtnislos“ bezeichnet in dieser Arbeit daher ausschließlich das Fehlen eines lernbaren rekurrenten oder aufmerksamkeitsbasierten Gedächtnismoduls. Im Folgenden werden zunächst die Rolle der Baseline im Untersuchungsdesign und der Aufbau des Netzes erläutert. Anschließend werden Beobachtungsraum, Aktionsraum, Belohnungsstruktur und Episodenlogik spezifiziert und abschließend die Erwartung an die Baseline formuliert. Der Trainingsverlauf und die Ergebniszahlen werden gemäß der Kapitelstruktur dieser Arbeit erst in der Evaluation dargestellt (@sec:eval-mlp-baseline).

=== Rolle der Baseline im Untersuchungsdesign 

Die MLP-Baseline erfüllt im Untersuchungsdesign dieser Arbeit zwei Funktionen. Erstens dient sie als unterer Vergleichsanker: Sie beantwortet die Frage, welche Leistung in der entwickelten Labyrinthumgebung bereits ohne Gedächtnis erreichbar ist. Nur vor diesem Hintergrund lässt sich der Mehrwert gedächtnisbehafteter Architekturen: LSTM und Transformer überhaupt quantifizieren. Zweitens diente die Baseline als technischer Nachweis, dass die gesamte Trainingspipeline aus Unity-Umgebung, ML-Agents-Anbindung, Belohnungslogik und Protokollierung funktionsfähig ist, bevor komplexere Modellvarianten untersucht wurden.

Damit der spätere Architekturvergleich wissenschaftlich belastbar ist, wurde vor dem Training ein Grundprinzip festgelegt: Zwischen den zu vergleichenden Agentenvarianten soll sich möglichst nur eine Variable unterscheiden die Modellarchitektur beziehungsweise der Gedächtnistyp, während alle übrigen Randbedingungen identisch bleiben. Die konkrete Ausgestaltung dieses Prinzips, also welche Parameter über alle Architekturen und beide finale Läufe (v2 und v3) eingefroren sind und welche architekturspezifischen Abweichungen begründet zugelassen werden, dokumentiert die Methodik in Abschnitt 5.3. Für die Baseline ist entscheidend, dass die im Folgenden beschriebene MLP-Konfiguration zugleich die eingefrorene Referenzkonfiguration bildet, von der MLP und LSTM in beiden Läufen nicht abweichen. Die ergebnisbezogene Diskussion des daraus folgenden Vorbehalts, dass der Transformer in v2 nicht unter bestmöglicher Konfiguration verglichen wird, erfolgt in @sec:evaluation.

=== Aufbau des Multilayer-Perzeptrons

Das Multilayer-Perzeptron (MLP) ist die Grundform des vorwärtsgerichteten neuronalen Netzes. Es besteht aus einer Eingabeschicht, einer oder mehreren versteckten Schichten und einer Ausgabeschicht, wobei jede Schicht eine affine Transformation ihrer Eingabe mit anschließender nichtlinearer Aktivierungsfunktion berechnet. @goodfellow_deep_2016

Entscheidend für die Rolle als Baseline ist eine strukturelle Eigenschaft des MLP: Es verarbeitet ausschließlich die Beobachtung des aktuellen Zeitschritts. Es existiert kein interner Zustand, der Informationen über vergangene Beobachtungen speichert: die Policy ist rein reaktiv. Beobachtet der Agent in zwei unterschiedlichen Situationen denselben Beobachtungsvektor, wählt er zwangsläufig dieselbe Aktionsverteilung, unabhängig davon, wie er in diese Situationen gelangt ist. @goodfellow_deep_2016

In der vorliegenden Arbeit wird das MLP in der Standardkonfiguration des ML-Agents-Frameworks verwendet: Der Beobachtungsvektor wird durch zwei versteckte Schichten mit jeweils 256 Neuronen verarbeitet. Auf diesen gemeinsamen Netzrumpf setzen im PPO-Training zwei Ausgabeköpfe auf: die Policy, welche die Wahrscheinlichkeitsverteilungen über die diskreten Aktionen ausgibt, und der Wertschätzer (Critic), der den erwarteten Gesamtertrag des aktuellen Zustands schätzt. @juliani_unity_2020


=== Erwartung an die Baseline <sec:mlp-erwartungen>

Aus der Spezifikation lässt sich die Erwartung an die Baseline unmittelbar ableiten. Dank der Zielrichtungs-Observation und der Ray-Sensorik sollte das MLP in der Lage sein, eine reaktive Zielansteuerung mit lokaler Gefahrenvermeidung zu erlernen und die Navigationsaufgabe in der Mehrzahl der Episoden zu lösen. Zugleich markiert die Gedächtnislosigkeit eine strukturelle Obergrenze: In Situationen, deren korrekte Behandlung Wissen über die eigene Vorgeschichte erfordert, insbesondere das Erkennen bereits erkundeter Bereiche und das systematische Verlassen von Sackgassen, kann eine rein reaktive Policy prinzipbedingt keine optimale Entscheidung treffen @hausknecht_deep_2015. Die Baseline wird daher erwartungsgemäß unterhalb der theoretisch möglichen Leistung sättigen. 



== Transformer-Memory (Custom Policy) <sec:transformer-memory>
// Dieses Kapitel beschreibt den statischen Aufbau der Transformer-basierten Custom Policy: das Speicher-Modul, das den rekurrenten Block in mlagents ersetzt, sowie dessen Einbettung zwischen Obs-Encoder und Actor-Critic-Köpfen.
// - Custom-Speicher-Modul `TransformerMemory` (`training/transformer_policy.py`), das den rekurrenten Speicher-Block (LSTM) im mlagents-`NetworkBody` ersetzt, kein eigener Trainer (§10.2).
// - Nur der Speicher-Block ist getauscht, Obs-Encoder, Policy-/Value-Kopf und PPO-Trainer bleiben mlagents-Standard → MLP-, LSTM- und Transformer-Behavior teilen Encoder, Köpfe und Trainer und unterscheiden sich allein im Speicher-Block (§9.2/§10.2, Info-Sammlung).
// - Aktivierung im Vergleichs-Behavior `Transformer_Navigator` (Lauf final_v3 & final_v2) über `memory_type: transformer`, architekturrelevante Config: sequence_length 16, memory_size 128, hidden_units 256 (§9.2).
// - Integration/Einhängung in mlagents (venv-Patch) und ONNX-Export sind nicht Teil dieses Kapitels → Kap. 7.2.

Der Transformer-Agent ist einer der beiden gedächtnisbehafteten Vergleichskandidaten. Sein Kern ist das Custom-Speicher-Modul TransformerMemory (`training/transformer_policy.py`), das im NetworkBody von ML-Agents den rekurrenten Speicher-Block ersetzt. Ein eigener Trainer existiert nicht: Beobachtungs-Encoder, Policy- und Value-Köpfe sowie der PPO-Trainer bleiben unveränderter ML-Agents-Standard. MLP-, LSTM- und Transformer-Behavior teilen sich damit Encoder, Ausgabeköpfe und Trainingsverfahren und unterscheiden sich ausschließlich im Speicher-Block. Aktiviert wird das Modul im Vergleichs-Behavior Transformer_Navigator über den Konfigurationsschlüssel `memory_type: transformer`. Die architekturrelevanten Werte der Vergleichsläufe sind eine Sequenzlänge von 16, eine memory_size von 128 und eine Encoder-Breite (hidden_units) von 256 (@tab:identische-parameter, @tab:yaml-abweichungen). Die Einhängung in die Trainingsumgebung über den venv-Patch sowie die Grenzen des ONNX-Exports sind nicht Gegenstand dieses Abschnitts. Sie werden in @sec:transformer-integration behandelt. 

=== Motivation: Gedächtnis unter partieller Beobachtbarkeit
// Dieser Abschnitt motiviert, warum überhaupt eine zeitliche Sequenz verarbeitet wird, statt eine Einzelbeobachtung an ein gedächtnisloses Netz zu geben.
// - Beobachtung ist lokal und kurzreichweitig: RayPerceptionSensor mit RayLength 12, RaysPerDirection 5, MaxRayDegrees 60 (§2.4), Boden-Sensor mit 9 Abwärts-Rays, Reichweite groundSensorRange 2.0 (§2.2), 4 Wand-Raycasts, Reichweite wallRaycastRange 3.0 (§2.3).
// - Kein zeitliches Stacking der Vektor-Beobachtung: NumStackedVectorObservations = 1, das einzige Stacking (Faktor 2) liegt im Ray-Sensor (§2.5) → eine Einzelbeobachtung ohne expliziten zeitlichen Verlauf.
// - Zeitlicher Kontext entsteht stattdessen im Speicher-Modul über eine Sequenz der letzten Encodings (sequence_length = 16, final_v3, §9.2/§10.2).
// - Entscheidungstakt DecisionPeriod = 5 (neue Entscheidung alle 5 Academy-Steps, §3) bestimmt den zeitlichen Abstand aufeinanderfolgender Sequenzelemente.
// - Hinweis: Die begriffliche Motivation (partielle Beobachtbarkeit / POMDP, "warum kein reines MLP genügt") ist NICHT Teil der SSOT (rein deskriptive Ist-Extraktion) → konzeptuelle Herleitung via Kap. 3.2.2 / 2.4.2.

Die Wahrnehmung des Agenten ist lokal und kurzreichweitig: Ray-Sensor, Boden-Sensor und Wand-Raycasts erfassen jeweils nur die unmittelbare Umgebung (vollständige Spezifikation in @tab:sensorspez), eine globale Karte steht zu keinem Zeitpunkt zur Verfügung. Hinzu kommt, dass eine Einzelbeobachtung kaum zeitliche Tiefe besitzt: Die Vektor-Beobachtungen werden nicht gestapelt (`NumStackedVectorObservations = 1`, @sec:obsspace), das einzige Stacking liegt mit dem Faktor 2 im Ray-Sensor. Ein einzelner Beobachtungsvektor beschreibt damit im Wesentlichen den aktuellen Moment.

Der zeitliche Kontext entsteht deshalb erst im Speicher-Modul, das eine Sequenz der jeweils letzten 16 Encoder-Ausgaben verarbeitet. Da der Decision Requester nur alle fünf Simulationsschritte eine neue Entscheidung anfordert (@tab:behaviors), liegen aufeinanderfolgende Sequenzelemente fünf Simulationsschritte auseinander. Das Attention-Fenster überspannt somit die letzten 16 Entscheidungspunkte des Agenten. Die konzeptionelle Begründung, warum partielle Beobachtbarkeit ein solches Gedächtnis erfordert, liefern @sec:sequenzmodellierung und @sec:partielle-beobachtbarkeit. Dieser Abschnitt beschreibt die konkrete Umsetzung.

=== Eingabeverarbeitung: Beobachtungssequenz und Embedding

// Dieser Abschnitt definiert, was das Modell konkret zu sehen bekommt: wie aus den Einzel-Encodings eine Sequenz fester Länge wird und welche Dimension diese Tokens haben.
// - Zwei Observation-Quellen, die mlagents vor dem Encoder konkateniert: VectorSensor 31 (CollectObservations) + RayPerceptionSensor 176 → Encoder-Eingang 207 (§2.5, Info-Sammlung).
// - Merksatz: Encoder-Eingang (207) ≠ VectorObservationSize (31), der Ray-Sensor ist eine eigenständige Observation und wird stillschweigend an den 31er-Vektor angehängt (Info-Sammlung, deckungsgleich mit §2.5).
// - Obs-Encoder (mlagents-Standard, LinearEncoder, 2 Schichten): 207 → Linear(207→256) → ReLU → Linear(256→256) → ReLU → Encoding 256 
// - d_model = h_size = hidden_units = 256 (networks.py:184 `self.h_size = network_settings.hidden_units`) → keine eigene Eingangsprojektion im Speicher-Modul, der Input liegt bereits als [B, 16, 256] vor.
// - Sequenzlänge/Fenster S = sequence_length = 16 (final_v3, §9.2/§10.2). Inhalt jeder Einzel-Beobachtung → Detail siehe Kap. 4.3.2.
ML-Agents führt vor dem Encoder zwei Beobachtungsquellen zusammen: die 31 Vektor-Beobachtungen aus CollectObservations und die 176 Ray-Beobachtungen des RayPerceptionSensor3D. Der Encoder-Eingang beträgt damit 207 Werte je Zeitschritt und ist nicht mit der VectorObservationSize von 31 zu verwechseln, denn der Ray-Sensor wird als eigenständige Observation stillschweigend an den Vektor angehängt.

Der Beobachtungs-Encoder ist der unveränderte zweischichtige LinearEncoder von ML-Agents: Der 207-dimensionale Eingang wird über zwei lineare Schichten mit ReLU-Aktivierung auf ein Encoding der Breite 256 abgebildet. Diese Breite folgt aus dem Konfigurationsschlüssel hidden_units, wird als h_size an das Speicher-Modul durchgereicht und dient dort zugleich als Modelldimension d_model. Eine eigene Eingangsprojektion besitzt das Modul deshalb nicht: Sein Eingang liegt im Training bereits als Tensor der Form [B, 16, 256] vor, also als Sequenz von 16 Encodings je Batch-Element.

=== Kern der Architektur: kausaler Self-Attention-Block
// Dieser Abschnitt beschreibt das Herzstück — Schichten, Köpfe, Modell-Dimension, Positionskodierung und die kausale Maskierung, die den Blick in die Zukunft verhindert.
// - Stapel aus num_layers = 2 identischen Transformer-Layern (hartkodiert im Modul, transformer_policy.py:30) — zu unterscheiden von network_settings.num_layers = 2, das die mlagents-Standard-Blöcke betrifft (§9.2).
// - Multi-Head Self-Attention: nhead = 4 Köpfe à 64 Dim (256 / 4 = 64, §10.2, Info-Sammlung).
// - Modell-Dimension d_model = h_size = 256 (§10.2, Info-Sammlung).
// - Feed-Forward je Layer: Linear(256→512) → ReLU → Linear(512→256) (= 2·h, §10.2, Info-Sammlung), Residuals als Post-LayerNorm, Dropout = 0.0 (§10.2).
// - Positionskodierung: gelerntes (nicht sinusförmiges) Positional Embedding, nn.Embedding(16, 256) der Länge seq_len (§10.2, Info-Sammlung).
// - Kausale Maskierung (obere Dreiecksmatrix mit −inf): jede Position attendiert nur auf aktuelle und vergangene Positionen — kein Zugriff auf zukünftige Sequenzelemente (§10.2, Info-Sammlung).
// - Parameterzahl NUR des Speicher-Moduls (Formel §10.2): P = S·h + 2·(8h²+11h) + (h+1)·(m/2), eingesetzt final_v3 (h 256, m 128, S 16) = 1 074 752, zusätzlich 272 nicht-trainierbare Buffer (pos_indices 16 + causal_mask 256) (§10.2, Info-Sammlung, deckungsgleich).
Das Speicher-Modul besteht aus einem Stapel von zwei identischen Transformer-Schichten. Diese Schichtenzahl ist im Modul fest hinterlegt und von `network_settings.num_layers` zu unterscheiden, das die Standard-Encoder-Blöcke von ML-Agents parametrisiert. Jede Schicht kombiniert Multi-Head-Self-Attention mit vier Köpfen zu je 64 Dimensionen (256/4) mit einem Feed-Forward-Netz, das die Modelldimension auf 512 aufweitet und wieder auf 256 reduziert. Die Residualverbindungen folgen dem Post-LayerNorm-Schema, Dropout ist mit 0.0 deaktiviert. Dass die Schichten manuell aus Einzelbausteinen komponiert sind, statt den vorgefertigten PyTorch-Encoder-Layer zu verwenden, ist Framework-Einschränkungen geschuldet, die in @sec:transformer-integration dokumentiert sind.

Da Self-Attention keine inhärente Ordnungsinformation trägt, wird die Position jedes Sequenzelements über ein gelerntes Positional Embedding der Länge 16 in der Modelldimension 256 kodiert. Auf eine sinusförmige Kodierung wurde zugunsten der ONNX-Exportierbarkeit verzichtet (@sec:transformer-integration). Eine kausale Maske in Form einer oberen Dreiecksmatrix mit $-infinity$ stellt sicher, dass jede Position ausschließlich auf die aktuelle und auf vergangene Positionen attendiert. Ein Zugriff auf zukünftige Sequenzelemente ist ausgeschlossen. Das Speicher-Modul umfasst insgesamt 1.074.752 trainierbare Parameter, hinzu kommen 272 nicht-trainierbare Buffer für Positionsindizes und Maske.

=== Sequenzaggregation und Actor-Critic-Anbindung
// Dieser Abschnitt zeigt, wie die Sequenz zu einer einzelnen Zustandsrepräsentation verdichtet und an die PPO-Policy- und -Value-Köpfe angebunden wird.
// - Sequenzaggregation: bei Inferenz Ausgabe der letzten Position (letztes Token), im Training Ausgabe aller Positionen (reproduziert die LSTM-Output-Shape, damit GAE/Pipeline unverändert bleiben) (§10.2, Info-Sammlung). Eine Pooling-Operation ist nicht belegt.
// - Modul-Ausgang: `output_proj: Linear(256→64)` → Zustandsrepräsentation [B, 64] = memory_size/2 (final_v3: 128/2 = 64, §10.2, Info-Sammlung).
// - Getrennte Actor-/Critic-Netze (kein Shared-Critic, §9): Obs-Encoder und Transformer-Speicher existieren doppelt — je einmal in Actor und Critic (Info-Sammlung).
// - Policy-Kopf: 3 diskrete Branches, je Linear(64→3), zusammen 585 Parameter → passt zu ActionSpec BranchSizes [3, 3, 3], 0 Continuous (§3, Info-Sammlung). Detail Aktionsraum → Kap. 4.3.1. Trainer PPO (trainer_type: ppo, §9) → Actor-Critic siehe Kap. 2.3.1.
// - Value-Köpfe: 2× Linear(64→1) = 130 Parameter (zwei Ströme: extrinsic + curiosity) (Info-Sammlung).
// - Parameterübersicht : Encoder 119 040 + Speicher 1 074 752 + Policy-Kopf 585 = Actor 1 194 377 (= Inferenznetz), Critic analog = 1 193 922, Actor+Critic = 2 388 299, Curiosity/ICM 179 465 (nur Training, nicht im Exportmodell), Gesamtsystem = 2 567 764.
// - Speicher-Haltung Rollout vs. Training (Detail → Kap. 7.2): Training verarbeitet die volle Sequenz [B, 16, 256], Inferenz rekonstruiert das 16er-Fenster über einen Rolling-Buffer der letzten 15 Encodings im mlagents-`memories`-Tensor → effektive Puffergröße (sequence_length−1)·h_size = 15·256 = 3840 (nicht der YAML-Wert 128) (§10.1/§10.2, Info-Sammlung).
Aus der verarbeiteten Sequenz muss eine einzelne Zustandsrepräsentation gewonnen werden. Das Modul verwendet dafür keine Pooling-Operation, sondern die Positionsausgaben selbst: Bei der Inferenz wird die Ausgabe der letzten Sequenzposition verwendet, im Training dagegen die Ausgaben aller Positionen. Letzteres reproduziert die Ausgabeform des LSTM, sodass die Advantage-Schätzung (GAE) und die übrige Trainingspipeline unverändert bleiben. Den Abschluss bildet eine Ausgangsprojektion von 256 auf 64 Dimensionen, deren Breite der Konvention memory_size/2 folgt (128/2 = 64).

Auf dieser Zustandsrepräsentation setzen die Standard-Köpfe von ML-Agents auf. Der Policy-Kopf besteht aus drei diskreten Branches mit je einer linearen Schicht von 64 auf 3 Ausgänge, passend zum Aktionsraum aus @tab:aktionsraum (585 Parameter). Zwei Value-Köpfe mit je einer linearen Schicht von 64 auf 1 schätzen die beiden Reward-Ströme extrinsisch und Curiosity (zusammen 130 Parameter). Actor und Critic sind als vollständig getrennte Netze ohne gemeinsame Gewichte implementiert. Sowohl der Beobachtungs-Encoder als auch der Transformer-Speicher sind daher jeweils einmal im Actor und einmal im Critic vorhanden. Der Actor, der gleichzeitig als Inferenznetz dient, umfasst 1.194.377 Parameter. Davon entfallen 119.040 auf den Encoder, 1.074.752 auf das Speicher-Modul und 585 auf den Policy-Kopf. Der Critic besitzt mit 1.193.922 Parametern eine nahezu identische Größe. Beide Netze zusammen umfassen somit 2.388.299 Parameter. Das ausschließlich während des Trainings verwendete Curiosity-Modul ergänzt weitere 179.465 Parameter, sodass das Gesamtsystem insgesamt 2.567.764 Parameter umfasst.

Die Konsistenz zwischen Datensammlung und Optimierung stellt schließlich ein Rolling-Buffer her: Während das Training die volle Sequenz [B, 16, 256] verarbeitet, rekonstruiert die Inferenz das 16er-Fenster aus den letzten 15 mitgeführten Encodings und dem aktuellen Encoding. Warum diese Konstruktion notwendig ist und wie sie den PPO-Ratio-Fehler behebt, dokumentiert @sec:transformer-integration.


== LSTM-Memory //ALEX

// - Vergleichs-Config (model_comparison_final_v3.yaml): memory_size 256 ->
//   hidden_size 128 (LSTMMemory: hidden = memory_size/2), num_layers 1,
//   ~198k Parameter. (hidden 64 / ~82k galt nur für die alte
//   labyrinth_lstm.yaml mit memory_size 128)
// - Patch-Strategie: additive elif-Bloecke in mlagents NetworkBody
// - Output-Shape GAE-kompatibel

 Der LSTM-Agent ist der zweite der beiden gedächtnisbehafteten Vergleichskandidaten. Er erweitert die in Abschnitt 6.1 beschriebene Referenzkonfiguration um genau eine Komponente, nämlich um ein  Gedächtnismodul zwischen Beobachtungs-Encoder und Ausgabeköpfen. Beobachtungsraum, Aktionsraum, Belohnungsstruktur und Episodenlogik sind mit der Baseline identisch. Eine Ausnahme stellt die Vorverarbeitungs-Flag "normalize" dar, die beim LSTM im Gegensatz zum MLP auf "true" steht. Die theoretischen Grundlagen der LSTM-Zelle wurden in Abschnitt 2.4.1 eingeführt. Im Folgenden werden die Rolle des Agenten im Untersuchungsdesign, der Aufbau und die Integrationsentscheidung einer eigenen LSTM-Implementierung sowie die Erwartung an die Architektur beschrieben. 

=== Rolle im Untersuchungsdesign

Das LSTM bedient im Vergleich gleich zwei Fragen. Bei F1 zählt es zusammen mit dem Transformer zur Seite der gedächtnisbehafteten Modelle, die gegen die reaktive MLP-Baseline antreten. Bei F2 ist es der Gegenpol zum aufmerksamkeitsbasierten Transformer. 

=== Aufbau des rekurrenten Netzes

ML-Agents bringt zwar eine native LSTM-Unterstützung mit, für den Vergleich wurde das Gedächtnismodul jedoch bewusst als eigene Implementierung (LSTMMemory) über denselben venv-Patch eingebunden wie die Transformer-Policy (Abschnitt 7.3). Somit nutzen beide Gedächtnisvarianten die identische Ein-/Ausgabeverträge und denselben Integrationspfad. Damit ist das LSTM ein sauberer Vergleichspunkt für den deutlich aufwendigeren Transformer.
Der Ablauf besteht aus drei Stufen. Ein vorgeschalteter Encoder (ein MLP mit zwei Schichten, jeweils bestehend aus 256 Neuronen) verdichtet die kombinierten Vektor- und Ray-Beobachtungen zu Merkmalen. Das LSTM führt daraus einen Hidden State von 128 Einheiten fort, und darauf sitzen, wie bei allen PPO-Agenten dieser Arbeit der Policy- und Wertkopf. Die in @tab:yaml-abweichungen ausgewiesene memory_size von 256 bezeichnet dabei nicht die Hidden-State-Breite selbst: Nach der ML-Agents-Konvention fasst memory_size den Hidden- und den Cell-State zusammen, woraus sich eine Hidden-State-Breite von memory_size/2 = 128 ergibt. Derselben Konvention folgt die Ausgangsprojektion des Transformers (@sec:transformer-memory). Allein die rückgekoppelte Schicht bringt 197.632 Parameter mit und stellt damit den maßgeblichen Kapazitätszuwachs gegenüber der Baseline. Es gibt zwei Konfigurationseinstellungen, die das Zeitverhalten bestimmen. Dazu gehört zum einen die sequence_length von 16 Schritten. Diese legt fest, wie weit die Gradienten im Training zurückverfolgt werden.  Zusätzlich ist für das LSTM, im Gegensatz zur Baseline, die Beobachtungsnormalisierung aktiv (normalize: true), weil sich ein normalisierter Encoder-Eingang im Curriculum als stabiler erwiesen hat.

=== Erwartung an das LSTM

 Die Erwartung an das LSTM ist dementsprechend ziemlich eindeutig. Das LSTM sollte die strukturelle Obergrenze der reaktiven Baseline durchbrechen, weil es die eigene Vorgeschichte im Hidden State mitführt und dadurch Situationen auseinanderhalten kann, die in der Einzelbeobachtung gleich aussehen . Hierzu gehört zum Beispiel das wiederholte Anlaufen derselben Sackgasse. Für Forschungsfrage 1 heißt das, dass das LSTM die MLP-Baseline bei der Erfolgsrate ziemlich sicher schlagen sollte. Bei F2 bleibt der Ausgang bewusst offen und wird im späteren Verlauf der Arbeit in Kapitel 8 beantwortet.

// ============================================================================
// 7. UMSETZUNG NACH MEILENSTEINEN  (mit Kernabschnitt 7.6)
//Hauptteil ALEX, kleine teile katya und finn ============================================================================
= Umsetzung
// wie das System ENTSTANDEN ist — Kapitel 4 liefert ZUSTAND, Kapitel 7 GENESE.
// PRÜFREGEL je Satz: "Steht das schon in Kapitel 4? -> Verweis statt Wiederholung."
// FILTER je Inhalt: Welche Entscheidung wurde REVIDIERT, welches PROBLEM trat
// auf, was wurde GELERNT? Nur das bleibt — alles andere ist Füllstoff.
// STRUKTURENTSCHEIDUNG (Review): früher 7.1-7.5 zu EINEM verdichteten Abschnitt
// "Aufbauphase (M1-M6)" von 2-4 Seiten zusammengefasst, die Problemklassen-
// Darstellung (Transformer-Integration) ist der HAUPTTEIL des Kapitels.

== Aufbauphase (M1--M6)
// VERDICHTET aus früher 7.1-7.5 — nur Entstehung, kein Endzustand:
//
// - Umgebung (früher 7.1): NICHT das Datenmodell/die Generierung erklären
//   (steht in 4.2) — den ÜBERGANG erzählen: warum von 5 manuellen Layouts auf
//   prozedural (Messbarkeits-/Skalierungsgrund, Rückgriff §1.4), welches
//   konkrete Problem der Custom Editor (Preview) löste.
// - Hindernis-/Terminierungslogik (früher 7.2): nur die Entscheidungsebene —
//   warum tag-basiert, welche Alternative wurde verworfen, welches Problem
//   die KillZone-Mechanik löste.
// - Agent und Wahrnehmung (früher 7.3): Sensor-BESCHREIBUNG GESTRICHEN
//   (steht in @sec:sensorik) — es bleiben Sprungkalibrierung und gescheiterte
//   Zwischenstände.
// - Belohnungsdesign (früher 7.4): Herleitung und WIRKUNG der Reward-Terme
//   (Abgrenzung zu 4.5: dort nur die fixe, gemeinsame Funktion), warum
//   zentrale Reward-Vergabe statt verteilt in den Hindernis-Skripten
//   (Kopplung an die Todeslogik). YAML-Bullet GESTRICHEN (-> 5.3.2/Anhang).
// - Training und Curriculum (früher 7.5): welches Übergangskriterium zwischen
//   den Phasen, was daran revidiert wurde, Multi-Area nur als Entstehungs-
//   entscheidung (Begründung/Zahlen stehen in 4.2.2).
//
Die Aufbauphase errichtet das grundlegende Fundament, auf dem im späteren Verlauf der Architekturvergleich aufsetzt. Ziel dieses Fundaments ist es eine kontrollierbare, prozedural generierte Labyrinth Umgebung zu schaffen. Weiter besteht das Fundament aus einem physikbasierten Agenten mit Sensorik und einem Belohnungssystem. Um das Fundament für spätere Vergleiche einsatzbereit zu machen, ist eine erste funktionsfähige Trainingspipeline ebenfalls wesentlicher Bestandteil.
Die Aufbauphase lässt sich in 6 Bereiche gliedern, die in GitHub in Form von Milestones strukturiert und realisiert werden. Im folgende Abschnitt werden diese 6 Meilensteine näher betrachtet.

=== Meilenstein 1: Map-System
Den ersten Schritt macht die Umgebung. Sie bildet die Grundlage für alle weiteren Schritte. Dieser initiale Meilenstein etabliert eine erste Version und damit die Basis des Kartensystems. Beim Start der Szene erzeugt der MapGenerator eine Karte aus einem deklarativen Datenmodell (MapData), in dem durch ein zweidimensionales Zellraster für jede Zelle ein entsprechender Typ beschrieben wird. Zu den möglichen Typen gehören Wände, begehbarer Boden und vorläufige Platzhalter für die in Meilenstein 4 implementierten Gefahrenelemente. Aus dieser Beschreibung wird zur Laufzeit die eigentliche 3D-Geometrie aufgebaut. Die Trennung von Kartenbeschreibung und Karteninstanziierung ist eine zentrale Designentscheidung, welche aus mehreren Gründen getroffen wurde: Karten werden durch diese Trennung versionierbar, austauschbar und prozedural erzeugbar gemacht.  Weiterhin gehören zum Grundsystem der Umgebung die Platzierung von Spawn- und Zielelementen, ein Laufzeit-Reset mit Testtrigger als Vorgriff die Episodenlogik des Trainings, sowie erste Objekt-Tags (unter anderem für das Objekt Wand, Boden und Ziel). Diese sind elementarwichtig für die spätere Tag-basierte Sensorik des Agenten.

=== Meilenstein 2: Mehrere Layouts
Der zweite Meilenstein erweitert das Kartensystem vom Einzellayout zur Layout-Bibliothek. Diese Bibliothek bildet ein erstes Fundament für die angestrebten Generalisierungstests.  Der MapGenerator verwaltet also seit dieser Implementierung einen Satz von Layout-Definitionen und wählt daraus nach dem konfigurierbaren Modus. Hierbei lässt sich zwischen einem festen Layout, einem sequentiellen Modus und dem zufälligen Modus, welcher ohne Reihenfolge verschiedenen Layouts mit Wiederholungsvermeidung verwendet unterscheiden.



=== Meilenstein 3: Das Agent-Grundsystem
Der dritte Meilenstein bringt den Agenten in die Umgebung. Hierbei erweitert die zentrale Klasse LabyrinthAgent die Agent-Basisklasse des Unity-ML-Agents-Frameworks und definiert den diskreten Aktionsraum der Arbeit. Dieser besteht aus den drei Aktionszweigen für Vorwärts-/Rückwärtsbewegung, Links-/Rechtsdrehung und Sprung. Die Bewegung ist Rigidbody-basiert und damit physikkonsistent. Das ist eine Voraussetzung dafür, dass Sprünge über Lava eine echte motorische Teilaufgabe darstellen. Ein Ground-Check unterscheidet Boden – und Flugphasen und verhindert so Doppelspringen. Mit der Episodenlogik (Spawn-Platzierung und Reset über den MapGenerator) ist die Interaktionsschleife zwischen Agent und Umgebung geschlossen und vollständig.

=== Meilenstein 4: Hindernisse, Todeslogik und Sensorik
Der vierte Meilenstein verwandelt die bisher problemlos begehbare Karte in eine Aufgabe mit Risiko. Das in Meilenstein 1 beschriebene Zellmodell wird um die Hindernisse Lava und Loch erweitert. Getaggte Trigger dieser Hindernisse melden Kontakte über OnTriggerEnter an die Todeslogik des Agenten, welche daraufhin die Episode beendet. Für die Wahrnehmung des Agenten wird der RayPerceptionSensor des Frameworks konfiguriert. Dazu tasten Strahlenbündel die Umgebung ab und klassifizieren Treffer über die in Meilenstein 1 beschriebenen Objekt-Tags. Eine dedizierte Sensor-Testszene sichert die isolierte Erkennung der Objekte ab.

=== Meilenstein 5: Reward-System und erstes Training
Innerhalb des fünften Meilensteins werden die letzten, für ein erstes Training nötigen Schritte umgesetzt. Die Belohnungsfunktion kombiniert eine Zielprämie mit Todesstrafen für die Hindernisse Lava und Loch, sowie einer Timeout-Strafe, einer kleinen Zeitstrafe je Schritt und einem potentialbasierten Distanz-Shaping, welches Annäherungen an das Ziel kontinuierlich belohnt. Vergeben wird diese Prämie zentral im LabyrinthAgent. Mit der LabyrinthAgent.yaml entsteht die erste PPO-Trainerkonfiguration. Unmittelbar darauf folgen die ersten Trainingsläufe der MLP-Baseline, welche parallel zu Meilenstein 5 implementiert wurde.

=== Meilenstein 6: Prozedurale Generierung und Curriculum
Der sechste Meilenstein professionalisiert die Kartenerzeugung und legt somit das Fundament des Curriculum-Lernens. Ein Raum-Korridor-Graph erzeugt die Topologie (Räume, Korridore und Verzweigungen). Ein semantischer Pathfinder validiert jede erzeugte Karte auf deren Lösbarkeit. Unlösbare Kandidatenkarten werden sofort verworfen und anschließend neu generiert. Ein in diesem Meilenstein eingeführtes Schwierigkeits-Enum systematisiert die Karten in Klassen von Trivial über Easy, Medium und Hard bis zu spezialisierten Lernstufen. Ein Objekt-Pool (TilePool) hält die Kosten häufiger Kartenwechsel möglichst gering. Da die Generierung seed-basiert und somit deterministisch reproduzierbar ist, lassen sich Kartensätze sauber trennen. Diese Trennung ist die Voraussetzung für die spätere Generalisierungsmessung. Des Weiteren entsteht innerhalb dieses Meilensteins das Curriculum-System. Die CurriculumConfig beschreibt hierbei die Phasen mit Kartenklassen und Aufstiegsschwellen. Der CurriculumTracker steuert den Phasenfortschritt zur Laufzeit. Phasenspezifische Episodenlängen begrenzen Timeout-Episoden je Schwierigkeitsgrad.

Damit ist die Aufbauphase abgeschlossen und bildet somit die Basis für die Integration und Optimierung der Gedächtnisarchitekturen, deren jeweilige Umsetzung in den nachfolgenden Abschnitten näher erläutert wird.





== Transformer-Integration: von V1 bis zum lauffähigen Modell <sec:transformer-integration> //FINN

// - KERNLEISTUNG, prominent: der messgetriebene Integrationsprozess über 22
//   Arbeits-Iterationen (V1–V22) — alle 22 als Trainings-Runs im results-Inventar
//   belegt (SSOT §11), die meisten mit eigener Mess-/Analyse-Doku
//   (Trainingsanalyse_Transformer_Milestone7.md, V15–V22 auf Branch milestone-7).
//   Nach PROBLEMKLASSEN geordnet (nicht rein chronologisch), die Chronologie lebt
//   in der verdichteten Tabelle (@sec:iterationen).
// - Definition „lauffähig" für dieses Kapitel: der Transformer trainiert stabil im
//   PPO-Loop (konsistente Ratios, kein Absturz) und absolviert später das volle
//   30-M-Budget des final_v3-Vergleichs (SSOT §13.1). Inferenz/Evaluation laufen
//   über den Python-Trainer (--inference --resume), NICHT als ONNX in Unity —
//   Barracuda-Grenze, s. Problemklasse A, fehlende .onnx ist Absicht (SSOT §13.2).
// - Zählungs-Hinweis fürs Ausformulieren: V1–V22 sind Arbeits-Iterationen, das
//   results-Inventar läuft bis v24 (+ transformer_specialist). Die Zuordnung
//   Iteration ↔ Run-ID ist im Anhang aufzuschlüsseln (SSOT §11 als Beleg).

=== Warum kein Fork: der venv-Patch-Ansatz

mlagents 0.30.0 bietet keine öffentliche Schnittstelle, um eine eigene Policy einzubinden. Das memory-Feld in der YAML-Konfiguration verweist intern immer auf das LSTM, sodass sich eine andere Memory-Architektur nicht über die Konfiguration auswählen lässt. Die Integration eines Transformers muss deshalb unterhalb dieser Konfigurationsebene ansetzen.

Für die Umsetzung gab es drei Wege. Ein Fork von mlagents hätte das gesamte Framework in die eigene Verantwortung überführt und mit jeder Upstream-Änderung eine wachsende Divergenz und entsprechenden Pflegeaufwand bedeutet. Ein Wechsel zu CleanRL zusammen mit mlagents_envs hätte einen kompletten Frameworkwechsel erfordert. Beide Optionen wurden verworfen. Gewählt wurde stattdessen ein direkter Patch der virtuellen Umgebung (venv). Er verursacht nur mittleren Aufwand, bleibt vollständig lokal und lässt das Repository unberührt.

Auch eine Lösung auf der Unity-Seite über eine BufferSensorComponent wurde verworfen. mlagents behandelt den BufferSensor als eigene Observation-Modalität und nicht als Sequenz, sodass sich das gewünschte Verhalten darüber nicht abbilden lässt. Das nötige Chunking des Replay-Buffers entlang der sequence_length ist im Framework bereits vorhanden, deshalb ist kein zusätzlicher Unity-Code nötig. Der Transformer erhält so dieselbe Eingabe der Form [batch·seq_len, h_size] wie das LSTM, und der Eingriff bleibt vollständig auf der Python-Seite.

Der Patch greift an vier Stellen. In settings.py kommt der Konfigurationsschlüssel network_settings.memory.memory_type hinzu, der standardmäßig auf "lstm" steht. In networks.py erweitern zusätzliche elif-Blöcke den Konstruktor `NetworkBody.__init__`: Der Wert "transformer" führt zur TransformerMemory, "lstm" zur LSTMMemory und jeder andere Wert zum ursprünglichen mlagents-LSTM. Zusätzlich liefert die memory_size-Property jetzt (seq−1)·h_size, und die forward-Methode arbeitet mit einem Rolling-Buffer. In torch_policy.py nutzt der ONNX-Export die tatsächliche Buffer-Größe statt des memory_size-Werts aus der YAML. Schließlich werden transformer_memory.py und lstm_memory.py in die virtuelle Umgebung kopiert.

Damit diese Eingriffe zuverlässig bleiben, ersetzt der Patch Zeichenketten jeweils genau einmal und prüft über ein assert, dass die Zielstelle nur ein Mal vorkommt (assert old in text, count == 1). Ein Versions-Marker macht den Vorgang idempotent und erlaubt Upgrades über mehrere Versionsstände hinweg (v1 bis v4), während --undo den vollständigen Rückbau ermöglicht. Über start_training.py läuft der Patch automatisch vor jedem Trainingsstart und lässt sich bei Bedarf mit --no-patch abschalten.

So bleibt das Repository frei von Änderungen, und die eigenen Module liegen versioniert unter training/. Derselbe Mechanismus trägt später auch das Vergleichs-LSTM, das über die LSTMMemory statt über das native mlagents-LSTM eingebunden wird. Beide Memory-Architekturen nutzen damit einen einzigen Integrationspfad mit identischem I/O-Vertrag. Das schafft die Grundlage für einen fairen Vergleich.

=== Warum kein vortrainiertes Modell (GPT-2, Decision Transformer)

Um den Beitrag des Transformers nachweisbar zu machen, muss klar sein, welche Modellklasse überhaupt zur Aufgabe passt. Dabei lassen sich drei Klassen unterscheiden. Vortrainierte Sprachmodelle wie GPT-2 sind für die Aufgabe ungeeignet. Sie sind auf Texttokens trainiert und bringen vor allem Sprachwissen mit, während die Observationen hier aus kontinuierlichen Sensordaten wie Raycasts, Position und Orientierung bestehen. Dieses Sprachwissen lässt sich nicht sinnvoll auf die Labyrinthnavigation übertragen. Der Decision Transformer #cite(<chen_decision_2021>, supplement: [S.~3--4]) ist dagegen die für Reinforcement Learning passendere Modellklasse, arbeitet jedoch als Offline-Verfahren. Die für die Aufgabenstellung sinnvolle Variante ist deshalb eine eigene Online-RL-Implementierung aus PPO und einem Transformer-Memory-Modul.

Gegen den Decision Transformer als tatsächlich umgesetzte Erweiterung sprechen drei Gründe. Der erste betrifft die Datengrundlage: Es stehen keine fertigen Demonstrationsdaten zur Verfügung. Die Offline-Trainingsdaten müssten aus Rollouts des eigenen, bereits trainierten PPO-Transformer-Agenten gewonnen werden. Der Decision Transformer würde dadurch im Wesentlichen die PPO-Strategie nachbilden. Chen et al. zeigen selbst, dass sich das Verfahren auf den meisten Umgebungen ähnlich wie Behavior Cloning auf einer return-gefilterten Teilmenge der Daten verhält und die erzielten Returns eng der Return-Verteilung der Trainingsdaten folgen #cite(<chen_decision_2021>, supplement: [S.~8--9]), und der Vergleich würde seine Aussagekraft verlieren. Die im Originalpaper gezeigten Stärken beruhen gerade auf Datensätzen mit Trajektorien sehr unterschiedlicher Qualität, etwa den D4RL-Varianten Medium, Medium-Replay und Medium-Expert oder einem Ausschnitt des DQN-Replay-Buffers #cite(<chen_decision_2021>, supplement: [S.~6--7]). Eine vergleichbare Datengrundlage ließ sich in der verfügbaren Zeit nicht aufbauen. Der zweite Grund liegt im Zusammenspiel von Aufgabenprofil und Datengrundlage: Chen et al. berichten zwar gerade bei spärlichen und verzögerten Rewards eine Robustheit ihres Verfahrens gegenüber TD-Learning #cite(<chen_decision_2021>, supplement: [S.~9--10]), diese Ergebnisse setzen jedoch Offline-Datensätze voraus, deren Trajektorien eine breite Verteilung an Returns abdecken, im Key-to-Door-Experiment etwa Tausende Zufallstrajektorien, von denen ein Teil zufällig erfolgreich ist #cite(<chen_decision_2021>, supplement: [S.~9--10]). Bei der hier betrachteten Labyrinthnavigation mit seltenen Rewards und langen Episoden ist genau diese Voraussetzung nicht erfüllt, da sich eine solche Return-Varianz ohne bereits trainierten Agenten nicht erzeugen ließe. Der dritte Grund ist der praktische Mehraufwand: Ein eigenständiges Offline-Setup außerhalb von ML-Agents wäre nötig, mit eigener Trajektorien-Pipeline, separatem PyTorch-Trainingsloop und einem Inference-Wrapper für die Unity-Evaluation. Das entspräche faktisch einem zweiten kleinen Projekt neben dem laufenden PPO-Training. Der Decision Transformer wird deshalb als naheliegende, aber bewusst nicht umgesetzte Erweiterung eingeordnet.

Für dieselbe Entscheidung sprechen drei weitere Punkte, die sich unmittelbar aus dem Projektaufbau ergeben. Das Vergleichsdesign verlangt identische Startbedingungen, weshalb alle drei Architekturen von Null trainieren. Entsprechend arbeitet der Scene-Builder ohne vortrainiertes Modell, und m_Model ist in allen Trainingsszenen None. Hinzu kommt der projektspezifische Beobachtungs- und Aktionsraum mit einem Policy-Input von 207, für den kein vortrainiertes Modell mit passender Schnittstelle existiert. Schließlich sitzt das Memory-Modul zwischen dem mlagents-Encoder und den Policy- und Value-Köpfen, sodass fremde Gewichte ohne die umgebenden, mittrainierten Komponenten wertlos wären.

=== Problemklasse A: Framework-/Engine-Workarounds <sec:framework-workarounds>

Die letztlich umgesetzte Transformer-Architektur ist in weiten Teilen das Ergebnis konkreter Einschränkungen der eingesetzten Frameworks und der Ziel-Engine. Bereits der naheliegende Einstieg über `nn.TransformerEncoderLayer` erwies sich unter CUDA als nicht tragfähig, da dieser Baustein intern optimierte C-Kernel aktiviert, die im Betrieb reproduzierbar Segmentation Faults auslösten. Das Deaktivieren der Nested-Tensor-Optimierung über `enable_nested_tensor=False` genügte nicht, um den Fehler zu beheben. Der vorgefertigte Layer wurde daher vollständig durch eine manuelle Komposition aus `nn.MultiheadAttention`, Layer-Normalisierung und einem Feed-Forward-Netz ersetzt, deren Residualverbindungen dem Post-LayerNorm-Schema folgen. Diese Zusammensetzung bildet die tatsächlich verwendete Encoder-Architektur.

Die manuelle Umsetzung musste zugleich ONNX-exportierbar bleiben, was zwei weitere Eingriffe nach sich zog. Ein bekannter Fehler in PyTorch 2.0 lässt `nn.MultiheadAttention` mit `batch_first=True` beim Export abstürzen. Die Konfiguration wurde deshalb auf `batch_first=False` umgestellt und die erforderliche Achsenreihenfolge über explizite `.transpose(0,1)`-Aufrufe hergestellt. Vor einer vergleichbaren Hürde stand die Positionscodierung, denn ein `torch.arange` im Vorwärtspfad ist nicht ONNX-traceable und lässt sich nicht in den Graphen überführen. Die Positionsindizes werden daher schon im Konstruktor über `register_buffer("pos_indices")` bereitgestellt, während die Codierung selbst als gelerntes `nn.Embedding` realisiert ist, das sich zuverlässig exportieren lässt.

Auch die Anbindung an die Vorteilsschätzung (GAE) von ML-Agents erzwang eine Anpassung der Ausgabeform. Die erste Fassung des Netzes gab ausschließlich die letzte Sequenzposition zurück, woraus ein Shape-Mismatch zwischen `(64,)` und `(8,)` resultierte. Die GAE-Implementierung erwartet, analog zum LSTM, eine Ausgabe der Form `[batch·seq_len, out]`, also je Sequenzposition einen Wert. Der Encoder liefert im Training deshalb die Ausgaben über alle Positionen. Erst zur Inferenz wird auf die letzte Position reduziert.

Neben diesen modellinternen Änderungen traten zwei Fallstricke in der Integrationsumgebung auf. Da die Architekturanpassungen über textbasierte Patches in den Quellcode von ML-Agents eingebracht wurden, griff ein Ersetzungsanker zunächst an zwei Stellen zugleich und traf sowohl `NetworkBody` als auch `MultiAgentNetworkBody`. Erst die Erweiterung der Marker um eindeutige Kontextzeilen stellte eine eindeutige Ersetzung sicher. Auf Unity-Seite verhinderte die Konfiguration des Agent-Prefabs jedes Training, weil der `BehaviorType` auf `InferenceOnly` stand, ohne dass ein Modell hinterlegt war. Behoben wurde dies durch einen Scene-Override auf den Standardwert `Default`.

Eine grundlegende Grenze besteht bis heute fort und prägt das Fazit zum lauffähigen Modell. Der Transformer-Graph lässt sich mit Barracuda 2.0.0 nicht ausführen: Zwar wäre der problematische If-Operator durch gezielte Eingriffe am Graphen (Graph-Chirurgie) entfernbar, doch das für die Attention notwendige Reshape überschreitet Barracudas auf vier Dimensionen begrenztes Tensormodell. Der Betrieb erfolgt daher über eine Python-Inferenz. Während die MLP- und LSTM-Varianten als ONNX-Modelle vorliegen, wird der Transformer bewusst nicht in dieses Format überführt.

=== Problemklasse B: Inference/Training-Konsistenz

Die zweite Problemklasse unterscheidet sich grundlegend von reinen Implementierungsfehlern. Die betroffenen Komponenten arbeiteten für sich genommen rechnerisch korrekt, der Fehler entstand erst im Zusammenspiel mit dem ML-Agents-Framework. Aufgedeckt wurde er, nachdem ein Trainingslauf über 1,69 Millionen Schritte keinerlei Lernfortschritt gezeigt hatte.

Die Diagnose führte auf einen Unterschied in der Sequenzverarbeitung zwischen den beiden Phasen des Trainingszyklus. Bei der Inferenz ruft ML-Agents die Policy ohne das Argument sequence_length auf, wodurch der Standardwert 1 greift und jeder Zeitschritt isoliert verarbeitet wird. Der PPO-Optimizer trainiert hingegen mit der in der YAML-Konfiguration festgelegten Sequenzlänge, die zum damaligen Zeitpunkt acht Schritte betrug. Die während der Datensammlung aufgezeichneten Log-Wahrscheinlichkeiten der alten Policy (π_old) stammen folglich aus einem Vorwärtsdurchlauf über einen einzelnen Schritt, während die im Training neu berechneten Werte (π_new) auf einem Durchlauf über acht Schritte beruhen. Das Wahrscheinlichkeitsverhältnis, das den Kern des PPO-Updates bildet, setzt jedoch voraus, dass Zähler und Nenner unter denselben Rechenbedingungen entstehen. Da die Kontexte strukturell voneinander abwichen, verließ das Verhältnis den zulässigen Clipping-Bereich bereits ohne jede tatsächliche Änderung der Policy. Nahezu jeder Gradient wurde abgeschnitten und das Training kam faktisch zum Stillstand.

Warum dieser Mechanismus das rekurrente Referenzmodell nicht betrifft, erklärt zugleich, weshalb der Fehler so lange unbemerkt blieb. Ein LSTM führt einen persistenten Hidden State mit, den das Framework zwischen den Zeitschritten speichert und dem Trainingsdurchlauf als Startzustand übergibt. Das Training setzt somit exakt an dem Zustand an, der auch bei der Inferenz vorlag, und reproduziert dieselben Log-Wahrscheinlichkeiten. Ein Transformer besitzt keinen solchen Zustand. Er benötigt alle Schritte einer Sequenz gleichzeitig als Eingabe, erhielt sie bei der Inferenz jedoch nie.

Die Lösung besteht in einem Rolling-Memory-Buffer, der die fehlende Zustandsinformation explizit nachbildet. Die jeweils letzten Encodings des MLP-Encoders, eines weniger als die Sequenzlänge, werden im Memories-Tensor von ML-Agents mitgeführt. Bei der Inferenz lässt sich aus ihnen zusammen mit dem aktuellen Encoding die vollständige Sequenz rekonstruieren, die auch der Optimizer im Training verarbeitet. Nativ hätte ML-Agents für diesen Tensor lediglich so viele Gleitkommawerte allokiert, wie der Konfigurationsschlüssel memory_size vorgibt, also 128. Die Anpassung zweckentfremdet und vergrößert ihn zum Encoding-Puffer, was bei der damaligen Sequenzlänge von acht sieben gespeicherte Encodings mit insgesamt 1792 Gleitkommawerten bedeutete. Inferenzkontext und Trainingskontext sind seither identisch, die Log-Wahrscheinlichkeiten beider Phasen stimmen überein und das PPO-Verhältnis ist wieder gültig.

Für die Dimensionierung sind drei Größen zu unterscheiden. Der Konfigurationsschlüssel hidden_units legt mit 256 die Ausgabebreite des MLP-Encoders pro Zeitschritt fest. Er wird als h_size an das Speichermodul durchgereicht und dient dort zugleich als Modelldimension d_model des Transformers. Der Schlüssel memory_size mit dem Wert 128 bestimmt bei den eigenen Modulen dagegen nur noch die Ausgabebreite des Speichermoduls, die der Hälfte dieses Wertes entspricht, also 64. Die Halbierung übernimmt die Konvention des ML-Agents-LSTM, bei dem memory_size Hidden State und Cell State zu jeweils gleichen Teilen abdeckt. Der Schnittstellenvertrag zum Framework bleibt so unverändert, und das Vergleichs-LSTM verhält sich analog mit memory_size 256 und einer Ausgabebreite von 128. Die dritte Größe ist der Umfang des Memories-Tensors selbst. Die Implementierung überschreibt die memory_size-Eigenschaft des NetworkBody für die eigenen Module mit dem Produkt aus der um eins verringerten Sequenzlänge und h_size, damit das Framework genügend Platz für die mitgeführten Encodings bereitstellt. Der Vorwärtsdurchlauf hängt das aktuelle Encoding an den Puffer an, schneidet diesen auf die Fenstergröße zu und gibt die Ausgabe der letzten Sequenzposition zurück. Die aktuell verwendeten Konfigurationen labyrinth_transformer und final_v3 kombinieren eine Sequenzlänge von 16, memory_size 128 und den Speichertyp Transformer, woraus sich 15 mitgeführte Encodings zu je 256 Werten und ein exportierter Tensor von 3840 Gleitkommawerten ergeben.

Derselben Problemklasse ist ein zweiter Fall zuzuordnen, der mit dem Übergang von Version 5 auf Version 6 behoben wurde. Ohne kausale Maske arbeitet die Attention bidirektional und bezieht im Training Informationen aus zukünftigen Zeitschritten ein. Das Netz lernt auf diese Weise eine Funktion, die bei der kausalen Inferenz, in der zukünftige Beobachtungen grundsätzlich nicht verfügbar sind, gar nicht existiert. Der Verlust sinkt während des Trainings zwar dem Anschein nach, ein tatsächlicher Lernfortschritt bleibt jedoch aus. Seit Version 6 ist die Causal Mask aktiv, sodass Training und Inferenz auf derselben Informationsgrundlage operieren.

=== Problemklasse C: Reward-/Curriculum-Pathologien <ProblemklasseC>

Die gravierendste Pathologie der frühen Trainingsläufe war ein vollständig ausbleibendes Erfolgssignal. Über rund eine Million Trainingsschritte, verteilt auf etwa 416 Episoden in acht parallelen Trainingsarealen, erreichte der Agent das Ziel kein einziges Mal. Der Episodenreward verharrte konstant auf dem Timeout-Niveau, also dem Produkt aus maximaler Schrittzahl und Schrittstrafe. Ohne ein einziges positives Signal existiert kein Gradient in Richtung des Ziels, das Training konnte unter diesen Bedingungen prinzipiell nicht konvergieren. Die Konsequenzen reichten über das Reward-Design hinaus. Solange kein Lernfortschritt möglich war, ließ sich keine belastbare Aussage über die Netzarchitektur treffen, denn der sparse Reward maskierte zugleich den Ratio-Bug. Erst nach Auflösung dieser Abhängigkeit wurden Architekturvergleiche überhaupt aussagekräftig.

Der Befund wurde mit drei ineinandergreifenden Maßnahmen behoben. Zunächst erhielt das Curriculum eine vorgelagerte Trivialphase aus offenen Räumen der Größe 7×7, in denen bereits ein Random Walk das Ziel mit hinreichender Wahrscheinlichkeit erreicht und so die ersten positiven Lernsignale erzeugt. Diese Phase 0 umfasst im finalen Stand 100 Layouts, ein Aufstiegskriterium von 40 Prozent Erfolgsquote über 500 Episoden und eine maximale Episodenlänge von 600 Schritten. Als zweite Maßnahme kam ein dichtes Distanzsignal in Form von Potential Based Reward Shaping nach Ng et al. (1999) @ng_policy_1999 hinzu. Die potentialbasierte Form ist nachweislich policy-invariant und verändert die optimale Strategie nicht. Naheliegende Alternativen erwiesen sich hingegen als ausnutzbar. Eine einfache Delta-Distanz ohne Gamma-Korrektur begünstigt oszillierendes Verhalten, und ein Line-of-Sight-Reward belohnt das Anschauen des Ziels statt der Annäherung. Das Shaping arbeitet mit einem Skalierungsfaktor von 0.01 und einem pbrsGamma von 1.0, sodass exakt die Potentialdifferenz vergütet wird. Drittens wurde die Zieldistanz als 23. Dimension in den Beobachtungsvektor aufgenommen. Der bereits vorhandene normierte Richtungsvektor trägt keinerlei Fortschrittsinformation, auf einem diagonalen Pfad bleibt er beispielsweise konstant bei (0.707, 0, 0.707). Erst die Distanz macht für den Agenten beobachtbar, ob eine Aktion ihn dem Ziel tatsächlich näherbringt.

Die Trivialphase legte kurz nach ihrer Einführung eine physikbedingte Fehlstrategie offen. Der Agent kletterte scheinbar Wände hoch, allerdings nicht durch Sprungkraft, sondern weil die Depenetration der PhysX-Engine den Körper beim Anlaufen gegen Wände nach oben schleudert. Der Schutzmechanismus gegen dieses Verhalten entstand in drei Schritten. Die erste Version kombinierte eine Höhenschwelle von 1.5 mit einem sofortigen Episodenabbruch in FixedUpdate und beendete Episoden dadurch bereits nach zwei bis drei Schritten, weil die Depenetration den Agenten kurzzeitig über die Schwelle katapultiert. Der Abbruch wurde deshalb entfernt, die Prüfung in den Decision-Takt verlegt und die Schwelle auf 3.0 angehoben. Ergänzend kappt seither ein maxUpwardVelocity-Limit in FixedUpdate physikinduzierte Aufwärtsbeschleunigungen, während reguläre Sprünge unberührt bleiben. Diese Kombination steigerte den Trainingsdurchsatz von 97 auf 315 Schritte pro Sekunde und normalisierte den Reward. In Version 12 musste die Schwelle nochmals von 3.0 auf 5.0 angehoben werden, weil der Guard bei legitimen Sprüngen über Lava auslöste und das Lernsignal invertierte, da die Strafe von −1 zeitgleich mit dem Sprungreward eintraf. Im Endzustand fällt eine Strafe von −1 pro Schritt an, solange die Höhe des Agenten den Spawnwert um mehr als den Parameter wallClimbMaxY von 5 überschreitet, ohne Edge-Trigger. Das Geschwindigkeitslimit liegt durch den im Prefab hinterlegten Wert effektiv bei 8.

Eine zweite Schwäche der Trivialphase betraf die Generalisierung. Die ursprüngliche Implementierung erzeugte über seed modulo 4 lediglich vier Konfigurationen mit Spawn und Ziel in festen Ecken. Der Agent memorierte daraufhin die Strategie, stets zur Zelle (5,5) zu laufen, statt die Richtungsbeobachtung zu nutzen, was in 25 Prozent der Fälle zufällig zum Erfolg führte und in den übrigen 75 Prozent im Timeout endete. Die Korrektur setzte auf der Generierungsebene an und nicht zur Laufzeit. Zunächst wurde das Ziel auf einem zufälligen Bodenfeld platziert, mit einem eigenen Zufallsgenerator je Seed. Ein anschließendes Refactoring der Methode BuildTrivialBase parametrisierte zusätzlich Raumgrößen, Korridorlängen und Raumformen über den Seed. Jede Curriculumstufe verfügt seither über 100 bis 200 vorab generierte Layouts, konkret 100, 100, 150, 200, 150, 196, 199 und 192. Zur Laufzeit wird lediglich im Round-Robin-Verfahren aus den vorab bestimmten Spawn- und Zielzellen des Pools gewählt. Die zusätzlich vorhandene Meide- und Fallback-Logik, etwa die Bevorzugung von Bodenfeldern ohne Lava- oder Lochnachbarn, dient ausschließlich als Degradationskaskade für Ausnahmefälle und ist kein gestalterischer Mechanismus.

Auch das Shaping selbst erwies sich in zwei voneinander unabhängigen Konstellationen als ausnutzbar, jeweils vermittelt über den Discount-Faktor. In Version 9 war pbrsGamma auf 0.99 gesetzt. Ein Wert kleiner als eins erzeugt in der Potentialdifferenz einen Restterm der Form (1 − γ) · d und damit einen kleinen positiven Reward für das bloße Verweilen. Über 1199 Schritte aufsummiert führte dieser Term zu einem Plateau bei einem durchschnittlichen Episodenreward von 8.9 bei gleichzeitig permanentem Timeout. Der Agent lernte zu überleben statt anzukommen. Version 10 setzte pbrsGamma deshalb auf 1.0, sodass ausschließlich echte Annäherung belohnt wird. Die zweite Konstellation zeigte sich in der Auswertung eines Übernachtlaufs der Version 12. Der in der Trainingskonfiguration gesetzte Discount-Faktor von 0.99 ließ den Zielreward aus Sicht des Episodenbeginns praktisch verschwinden, denn 10 · 0.99^1200 ist nahezu null. Nur die letzten rund 200 Schritte einer Episode nahmen das Ziel über die Wertfunktion überhaupt wahr, alle früheren Entscheidungen lernten ausschließlich aus dem Shaping-Signal. Version 13 hob den Discount-Faktor auf 0.997 an, was einem Planungshorizont von etwa 330 Schritten entspricht, und erhöhte den Zielreward auf 30, damit das Ziel über die Wertfunktion bis an den Episodenanfang zurückwirkt. Unabhängig von der Parametrisierung bleibt eine prinzipielle Grenze des Verfahrens bestehen. Das Potential misst die Luftlinie und nicht den begehbaren Pfad, sodass auch Annäherung durch Wände hindurch oder über Lava hinweg vergütet wird. Das Stehenbleiben unmittelbar vor einem Lavafeld wird folglich bezahlt.

Wie schwer dichte Konzeptsignale zu kalibrieren sind, zeigt der Reward für Lavaüberquerungen. Version 12 führte ihn als degressiven Anreiz ein, dessen Betrag zur Vermeidung von Farming über eine Viertel- und Achtelstaffelung abfällt. Version 13 entfernte das Signal wieder, weil es Springen lehrte statt Zielfindung, bevor eine spätere Iteration es reaktivierte. Im aktuellen Stand beträgt der Basiswert 1.5 mit degressiver Staffelung, pro Episode werden höchstens drei Versuche belohnt, und eine vollständige Überquerung wird mit einem Bonus von 8 vergütet. Dieser Bonuszweig ist im vorliegenden Code allerdings praktisch nie auslösbar und muss in Auswertungen als Messartefakt behandelt werden.

Über alle Iterationen hinweg zeichnet sich ein konsistentes Muster ab. Jedes dichte Zusatzsignal wurde früher oder später gefarmt, der Restterm des Shapings ebenso wie der Lava-Anreiz und das Curiosity-Modul im fehlgeschlagenen Lauf der Version 13. Die im Endzustand wirksamen Gegenmittel folgen unmittelbar aus dieser Erfahrung. Es sind die strikte Potentialform mit γ = 1, die degressive Staffelung wiederholbarer Belohnungen und ein festes Budget pro Episode.

Auf den Kern reduziert lässt sich die Problemklasse einfach zusammenfassen. Ein Agent lernt ausschließlich aus dem Reward, den er tatsächlich erhält. Bleibt das Zielsignal aus, lernt er nichts. Jedes Hilfssignal, das diese Lücke füllen soll, nimmt er wörtlich und nutzt es aus, statt es im gemeinten Sinn zu verstehen. Belohnt das Signal Nähe, bleibt er in der Nähe stehen. Belohnt es Überleben, überlebt er. Belohnt es Sprünge, springt er. Ein tragfähiges Reward-Design entsteht deshalb nicht aus einem einzelnen guten Signal, sondern aus der Kombination von anfangs lösbaren Aufgaben, einem mathematisch sauberen Distanzsignal und harten Obergrenzen für alles, was sich wiederholen lässt.

=== Problemklasse D: Konfigurations-Drift Unity und Python 

Eine eigene Problemklasse bildet die Konfigurationsdrift zwischen der Unity-Umgebung und der Python-Trainingsseite. Ihre Ursache liegt im Serialisierungsverhalten von Unity. Werte, die im Inspector gesetzt werden, speichert die Engine im Prefab, und diese serialisierten Werte überschreiben die im C#"-"Code hinterlegten Standardwerte. Änderungen an den Defaults im Quellcode bleiben deshalb wirkungslos, solange das Prefab nicht angepasst und ein neuer Build erzeugt wird. Weil die Trainingskonfiguration auf zwei getrennte Systeme verteilt ist, können beide Seiten unbemerkt auseinanderlaufen. Im Projektverlauf trat dieses Muster dreimal in dokumentierter Form auf.

Am folgenreichsten zeigte sich der Effekt in Version 13. Die Python-Seite war korrekt konfiguriert, mit einem Diskontfaktor γ von 0,997, aktiviertem Curiosity-Modul und einer Batchgröße von 1024. Der Unity-Build trug jedoch veraltete Prefab-Werte. Die Zielbelohnung lag bei 1 statt 30, MaxStep bei 6000 statt der phasenweise vorgesehenen 600, und das Reward-Shaping wirkte viermal so stark wie beabsichtigt. Unter diesen Bedingungen überlagerte die intrinsische Curiosity-Belohnung das ohnehin schwache Zielsignal vollständig, sodass der Agent 17,5 Millionen Schritte in einer faktisch falschen Umgebung trainierte. Der Lauf wurde als Negativbeispiel unter der Bezeichnung Mock-v13 dokumentiert. Als unmittelbare Konsequenz wurde eine Pre-Flight-Verifikation über das Player-Log eingeführt. Bevor ein Lauf weiterläuft, wird geprüft, ob die erwarteten Reward- und MaxStep-Zeilen im Log erscheinen und der Build somit tatsächlich die beabsichtigten Werte trägt.

In Version 20 wiederholte sich dieselbe Falle bei den Sprungparametern. Erneut überschrieb ein Prefab-Override die im Code gesetzten Werte. Die bereits in Version 19 implementierte Sprungmechanik funktionierte deshalb erst, nachdem die Prefab-Werte korrigiert worden waren.

Die subtilste Ausprägung der Problemklasse trat in Version 22 auf. Im Prefab war eine VectorObservationSize von 14 hinterlegt, während der Code 21 Beobachtungen erzeugte. Das Framework schnitt die überzähligen sieben Beobachtungen stillschweigend ab und gab weder einen Fehler noch eine Warnung aus. Ein Teil der Wahrnehmung des Agenten ging so unbemerkt verloren. Die Korrektur der Observationsgröße erzwang anschließend ein vollständiges Neutraining, weil die bestehenden ONNX-Modelle mit der geänderten Eingabedimension inkompatibel waren.

Allen drei Fällen ist gemeinsam, dass die Abweichung ohne jede Fehlermeldung wirksam wurde und weder in der Python-Konfiguration noch im Quellcode sichtbar war. Erkennbar wird eine solche Drift nur durch die explizite Verifikation der zur Laufzeit tatsächlich aktiven Werte.

=== Iterationsübersicht V1–V22 <sec:iterationen>

Die Entwicklung des Trainingssystems durchlief 22 dokumentierte Iterationen. Eine verdichtete Gegenüberstellung von Hypothese, belegter Kennzahl-Wirkung und Erkenntnis je Iteration gibt @tab:iterationen, die vollständigen Einzelkennzahlen der Läufe sind einschließlich der zugehörigen TensorBoard-Belege im Anhang aufgeführt.

Den Ausgangspunkt bildete V1 als Proof of Concept. Der Run transformer_test_v1 absolvierte 50 917 Steps ohne Absturz, und der Reward verbesserte sich von -2,6 auf -1,5. Belegt war damit die technische Stabilität der Pipeline, nicht jedoch ihre Lernfähigkeit. Genau diese Lücke offenbarte V2. Der Lauf erreichte einen Endstand von 1,79 Millionen Steps, zeigte jedoch über 1,69 Millionen Steps keinerlei Lernfortschritt. Die Analyse ergab eine Doppeldiagnose aus einem PPO-Ratio-Bug und einem zu spärlichen Belohnungssignal (Sparse Reward), den Problemklassen B und C. Auf die Diagnose folgten ein Rolling-Buffer-Fix sowie mehrere triviale Korrekturen, die zwei kurze Läufe (V3 mit 304 000 und V4 mit 379 000 Steps) verifizierten, ohne dass diese eine eigenständige Analyse erforderten.

Als nächstes trat ein Architekturfehler auf. In V5 fehlte die Causal Mask, wodurch kein Lernen stattfand: Die Entropie verharrte nach 680 000 Steps bei Werten von 2,27 beziehungsweise 2,30, während der Policy Loss stieg, statt zu fallen. V6 ergänzte die Causal Mask, setzte das Dropout von 0,1 auf 0,0 und die Lernrate auf 1e-4. Der nächste Engpass lag im Entropie-Koeffizienten: Ein Beta von 5e-3 erwies sich als zu hoch, denn die Entropie fiel nicht nachhaltig und kehrte nach einem Minimum von 1,94 sofort auf höhere Werte zurück. Mit der Absenkung auf 1e-3 griff die Regulierung in V7, erkennbar an einem Entropie-Minimum von 1,60 und einem Reward-Maximum von +1,14. Zugleich kollabierte jedoch der Value Loss auf etwa 0,001, weil der Buffer von 10 240 für eine stabile Advantage-Schätzung zu klein war. V8 vergrößerte den Buffer auf 40 960 und den Time Horizon von 64 auf 256, womit der Value-Kollaps verschwand. Die Entropie sank fortan pro Step langsamer, pro Update aber stabiler.

Eine grundsätzliche Fehleinschätzung der Erfolgsmessung deckte V9 auf. Nach 8,77 Millionen Steps erreichte der Lauf ein Plateau bei einem durchschnittlichen Reward von 8,9, allerdings bei einer Episodenlänge von 1199 und damit in dauerhafter Timeout-Stagnation. Der hohe Reward war folglich kein Erfolgsindikator, sondern ein Artefakt des Reward Shapings. V10 zog die Konsequenz und stellte das Belohnungsdesign um (goalReward 10, stepPenalty -0,005, pbrsGamma 1,0). Mit dem neu eingeführten SuccessRate-Logging löste die Erfolgsquote den Reward als Leitmetrik ab.

V11 veränderte den Handlungsraum grundlegend. Der Agent bewegte sich fortan agent-relativ und erhielt eine Dreh-Action (Action-Space 3,3,2), zudem wurde die Sequenzlänge von 8 auf 16 verdoppelt. In den Easy-Phasen erreichte das Training Erfolgsquoten von 72 bis 82 Prozent, beim Übergang in die Lava-Umgebungen brach es jedoch vollständig ein (Erfolgsquote 0,000). V12 reagierte über das Belohnungsdesign: Eine Timeout-Strafe von -2 machte das Aussitzen einer Episode zur schlechtesten Option, ergänzt um einen degressiv ausgestalteten Lava-Adrenalin-Reward und eine Anhebung von wallClimbMaxY von 3 auf 5. Ein Overnight-Run mit 96 parallelen Agents über 29,5 Millionen Steps machte anschließend die TrivialHazard-Wand sichtbar.

V13 kombinierte ein Gamma von 0,997, einen goalReward von 30, ein Curiosity-Modul und ein curriculum-abhängiges MaxStep. Real trainierte der Lauf jedoch als Mock-v13 eine andere als die beabsichtigte Konfiguration, weil ein Prefab-Drift (Problemklasse D) die Einstellungen überschrieb. 17,5 Millionen Steps mussten verworfen werden, und als Lektion blieb die verpflichtende Verifikation der Konfiguration vor jedem Laufstart. V14 wiederholte denselben Stack in sauberer Form über 31 Millionen Steps und meisterte die Navigation: Die Phasen 0 bis 3 erreichten 62 bis 79 Prozent, Phase 0 zuletzt 100 Prozent. Phase 4 verharrte dagegen nach 30 000 Episoden bei 0,2 Prozent, ein klares Curriculum-Cliff. Die Todesrate beim Lava-Sprung lag bei 99 Prozent, und die 21 Prozent Erfolgsquote in der Hard-Phase entstanden durch Umgehung der Hindernisse statt durch Sprünge. Drei Crash-Recovery-Zyklen im Laufverlauf begründeten zusätzlich einen Forgetting-Verdacht.

Zur gezielten Analyse dieses Cliffs entstanden die Iterationen V15 bis V22 auf einem separaten Experimentierzweig. V15 zerlegte den kritischen Übergang in Sub-Phasen (JumpWarmup, LavaSurround, LavaCrossable) mit einem SuccessRate-Gate und lokalisierte das Cliff sauber. Zwei strukturelle Defekte traten zutage. Erstens war das pfadbasierte PBRS wirkungslos: Lieferte die BFS für ein unerreichbares Ziel den Wert -1, ergab die Normalisierung 1,0, sodass kein Gradient entstand. Zweitens lernte der Agent die Sprung-Action nie, in 8,5 Millionen Steps fand kein einziger Sprungversuch statt. Verschärfend ließ ein MaxStep von 15 000 die Step-Penalty das Belohnungssignal dominieren.

V16 ersetzte die Distanzberechnung durch eine Jump-aware-BFS, führte eine JumpWarmup-Phase ein, senkte MaxStep auf 1500 und setzte die Timeout-Strafe auf -10. Das neue Gate offenbarte ein Explorationsproblem: Ein Beta von 5e-3 hielt die Policy bei 82 Prozent Zufallsverhalten, sodass das Training in Phase 1 bei einer Erfolgsquote von etwa 0,50 hängen blieb. V17 senkte Beta auf 1e-3, erhöhte max_steps auf 10 Millionen und setzte den SR-Threshold auf 0,55. Die Phasen 0 und 1 wurden gelöst, doch in Phase 2 entstand ein neues Plateau bei etwa 0,48, die Wahl des richtigen Branches glich einem Münzwurf. Ursächlich war der Beta-Decay, der den Koeffizienten gegen null laufen und die Exploration kollabieren ließ. Positiv fiel auf, dass kein Forgetting auftrat: Die EMA-Erfolgsquoten der Phasen 0 und 1 blieben über 4 Millionen Steps oberhalb von 0,70.

Aus dieser Beobachtung folgte V18 mit einem konstant gehaltenen Beta von 5e-4, max_steps von 20 Millionen, einem Threshold von 0,5 und neuen Pfad- und Branch-Diagnosemetriken. Erstmals durchlief das Training alle Phasen, allerdings erfolgten die Aufstiege jeweils am Coinflip-Grenzwert mit einer EMA von etwa 0,5. Das Curriculum wurde also durchgereicht statt gemeistert, und der Bruch beim Übergang von Phase 5 zu Phase 6 benannte den Kern des Problems: Hindernisse umgehen zu können ist nicht dasselbe wie springen zu können.

Die letzten vier Iterationen galten dem Sprung selbst. V19 führte den Macro-Jump ein, der den Sprung-Branch dreiwertig machte, und erhöhte maxUpwardVelocity auf 4,5, doch der Lava-Sprung scheiterte weiterhin. Die Ursache fand erst V20: Ein Prefab-Override überschrieb die konfigurierten Sprungwerte, erneut ein Fall der Problemklasse D. Nach der Korrektur funktionierte der Sprung, die Wegfindung blieb jedoch schwach. V21 erhöhte deshalb die Wegfindungs-Belohnung, woraufhin das Training bis zur Hard-Phase vorankam und die Sprünge sehr gut funktionierten. Tatsächlich funktionierten sie zu gut, denn der Agent übersprang 2×2-Lücken und suchte Sprünge aktiv, was einen Über-Anreiz offenlegte. V22 beseitigte schließlich zwei fundamentale Verzerrungen: Ein ObservationSize-Mismatch im Prefab (14 statt 21) hatte sieben Beobachtungswerte stillschweigend abgeschnitten, und die Reduktion von airControl von 1 auf 0,5 begrenzte die Sprungweite physikalisch, sodass Lücken von einem Feld überwindbar blieben, Lücken von zwei Feldern jedoch nicht. Beide Eingriffe erforderten ein Neutraining und markieren den Endpunkt der dokumentierten Iterationskette.

Für die Einordnung des abschließenden Vergleichs ist die Trennung der Entwicklungsstände wesentlich. Sub-Phasen-Curriculum, Macro-Jump und pfadbasiertes PBRS blieben Werkzeuge der Ursachenanalyse auf dem Experimentierzweig, während das verglichene System mit acht Curriculum-Phasen, dem ursprünglichen Sprung-Branch ohne Macro-Jump-Erweiterung und einem luftlinienbasierten PBRS arbeitet. In die finale Transformer-Konfiguration flossen die Explorationserkenntnisse aus V17 und V18 dagegen direkt ein: Ein Beta von 5e-4, eine konstante Beta-Schedule, eine konstante Lernraten-Schedule und eine Curiosity-Stärke von 0,02. Rolling Buffer und die Sequenzlänge 16 laufen unverändert im Vergleichslauf über 30 Millionen Steps, dessen Aufbau und Ergebnisse das Evaluationskapitel behandelt (siehe @sec:evalprotokoll).


== LSTM-Integration <sec:lstm-integration> //ALEX

Die LSTM-Integration ist das Gegenstück zur Transformer-Integration aus Abschnitt 7.2 und zeigt den Unterschied im Aufwand sehr deutlich. Der Transformer benötigte eine lange Iterationsserie, bis er lief. Das LSTM lief nach einer einzigen Korrektur-Runde. In diesem Abschnitt wird beschrieben, wie das LSTM eingebaut wurde, welche Probleme beim Start auftraten und was aus den Trainingsläufen lstm_v1 bis lstm_v7b gelernt wurde. 
ML-Agents bringt zwar eine eigene LSTM-Unterstützung mit, aber  das Gedächtnismodul wurde dennoch selbst implementiert. Es wird über denselben venv-Patch eingebaut wie die Transformer-Policy. Der Grund dafür ist die Vergleichbarkeit, da das Modul als exaktes Spiegelbild des TransformerMemory gebaut ist. Es hat die gleichen Ein- und Ausgabeformen, verarbeitet die Trainingssequenzen auf die gleiche Weise und sitzt an derselben Stelle im Netz.
 Beide Gedächtnisvarianten unterscheiden sich also nur in ihrer inneren Logik, nicht in der Verdrahtung. Interessant ist der Größenunterschied. Das LSTM-Modul hat 197.632 Parameter, das Transformer-Modul ca. 1,07 Millionen. Der Vergleich stellt bewusst zwei Gedächtnis-Mechanismen gegenüber und keine gleich großen Netze.

Der erste Versuch (lstm_v1) hat gezeigt, dass eine einfache Integration nicht sofort fehlerfrei läuft. lstm_v1 brach direkt nach dem Start ab, ohne einen einzigen Trainingsschritt. Die Analyse fand vier Fehler in der Verdrahtung. Der Patch hatte das Modul zwar angelegt, aber im Netz nie aufgerufen. Stattdessen griff der alte Codepfad auf die leere native LSTM-Referenz zu und stürzte ab. Dazu meldete das Modul dem Trainer die Gedächtnisgröße null, sodass gar kein Speicher angelegt wurde. Außerdem wurde die Sequenzlänge nicht gespeichert und der ONNX-Export nutzte die falsche Gedächtnisgröße, was beim Speichern der Checkpoints crashte. Alle vier Fehler gehören zur Problemklasse A aus Abschnitt 7.2.3 (Framework-/Engine-Workarounds) und wurden in einer Runde behoben. Das ist der zentrale Unterschied zum Transformer, da beim LSTM die Probleme auf der Integrationsebene blieben und keine weiteren Iterationen bezüglich Rewards und Parametern nötig waren.

Der erste vollständige Lauf lstm_v2 legte dann die Konfigurationsbasis. Fünf Parameter wurden gegenüber der vom Transformer übernommenen Startkonfiguration geändert. Die Normalisierung der Beobachtungen stabilisiert den Encoder, wenn die Kartengrößen im Curriculum wechseln. Der ca. 650.000 Steps große Lauf lieferte mehrere interessante Beobachtungen. Bei jedem Phasenwechsel bricht die Erfolgsrate ein und erholt sich danach wieder. Des weiteren wurden Modellgewichte aus dem Checkpoint geladen. Bei dem Curriculum-Fortschritt war dies aber nicht der Fall. Die Messwerte direkt nach dem Resume waren dadurch verzerrt.  Die dritte Beobachtung ist die Geschwindigkeitsgrenze. Im Unity-Editor lief das Training mit rund 280 Steps pro Sekunde, was zur Entscheidung geführt hat auf Headless-Builds umzustellen.

Die weiteren Läufe lstm_v3 bis lstm_v7b bauten darauf auf. Deren Hauptaufgabe war es unter anderem die Balance zwischen Todesstrafen und Zielprämie sicherzustellen. Das Ergebnis dieser Serie ist die Konfiguration labyrinth_lstm_v7.yaml. Sie wurde mit ihrer Gedächtnisdimensionierung unverändert in die finale Vergleichskonfiguration übernommen. 

== MLP-Integration <sec:mlp-integration>

Nachdem in @sec:mlp-baseline die MLP-Baseline auf konzeptioneller Ebene spezifiziert wurde, beschreibt dieser Abschnitt ihre technische Integration: die Anbindung der Unity-Umgebung an die ML-Agents-Trainingspipeline, die Umsetzung des Agenten im Code und im Unity-Inspector, den Aufbau der Trainingsszene sowie die Durchführung und Überwachung des Trainings. Der Trainingsverlauf ist in @sec:tuning-abweichungen dokumentiert. Die abschließende Einordnung der Ergebnisse erfolgt in @sec:eval-mlp-baseline.

Vorab ist der Integrationsaufwand einzuordnen, der sich zwischen den drei Architekturen deutlich unterscheidet: Die MLP-Integration ist mit Abstand die einfachste. Das MLP ist die Standardarchitektur des ML-Agents-Frameworks und nativ in dessen Trainingspipeline enthalten, weder die Netzarchitektur noch der Python-Trainer mussten angepasst werden. Der hier beschriebene Aufwand beschränkt sich daher auf die Anbindung von Umgebung und Agent, die ohnehin die gemeinsame Grundlage aller drei Architekturen bildet. Diese Asymmetrie ist gewollt und dokumentiert (@sec:tuning-abweichungen): Während ML-Agents grundsätzlich eine native LSTM-Konfiguration bereitstellt, wurde für den finalen Vergleich ein eigenes LSTMMemory-Modul über den gemeinsamen venv-Patch eingebunden. Die MLP-Integration diente damit zugleich als Fundament, auf dem die aufwendigeren Integrationen aufsetzen konnten.

=== Systemarchitektur der ML-Agents-Anbindung

Der grundlegende Aufbau des Trainingssystems wurde in vorherigen Kapiteln beschrieben und gilt für alle drei Architekturen gleichermaßen. Für die Integration der MLP-Baseline ist nur relevant, dass Unity-Umgebung und Python-Trainingsprozess (mlagents-learn) während des Trainings gleichzeitig laufen und der Agent zu jedem Entscheidungszeitpunkt Beobachtungen an den Trainer sendet und dessen Aktionen zurückerhält. Die folgenden Abschnitte konzentrieren sich daher auf die architekturunabhängige Anbindung von Umgebung und Agent, die den eigentlichen Integrationsaufwand der Baseline ausmacht.

=== Integration des Agenten in Unity

Für die Integration wurde ein durchgängiges Strukturierungsprinzip angewandt: Die Funktionslogik des Agenten liegt vollständig im Code, während der Unity-Inspector ausschließlich der Konfiguration und Verdrahtung von Komponenten dient. Diese Trennung hält die Logik nachvollziehbar und versionierbar, während Parameter wie Sensorreichweiten oder Belohnungswerte ohne Codeänderung angepasst werden können.

Kern der Integration ist die Agentenklasse LabyrinthAgent, die von der Agent-Basisklasse des ML-Agents-Frameworks erbt und deren Lebenszyklus-Methoden überschreibt. @juliani_unity_2020 Beim Episodenstart (OnEpisodeBegin) stößt der Agent das Laden eines neuen Layouts an und wird auf die Spawn-Position versetzt. Zu jedem Entscheidungszeitpunkt sammelt CollectObservations die Beobachtungen. Die vom Modell gewählten Aktionen werden in OnActionReceived entgegengenommen, in physikbasierte Bewegung, Drehung und Sprung übersetzt und mit der Schrittstrafe belegt. Die Terminalereignisse: Zielerreichung sowie Tod durch Lava oder Loch, werden über Trigger-Collider erkannt. Die Umgebungsobjekte lösen lediglich das Trigger-Ereignis aus, während die gesamte Belohnungsvergabe und Episodensteuerung zentral in der Agentenklasse erfolgt. Diese Zentralisierung stellt sicher, dass alle Belohnungswerte an einer einzigen, im Inspector konfigurierbaren Stelle liegen und für den Architekturvergleich eingefroren werden können.

Auf dem Agenten-Prefab sind drei Framework-Komponenten konfiguriert. Die Behavior Parameters definieren die Schnittstelle zwischen Agent und Trainer: den Verhaltensnamen MLP_Navigator, die Größe des manuellen Beobachtungsvektors (vgl. @tab:sensorspez) sowie den diskreten Aktionsraum mit drei Zweigen (Bewegung, Drehung, Sprung). Der RayPerceptionSensor3D ist als eigene Sensorkomponente direkt am Agenten angebracht und im Inspector konfiguriert.Seine Beobachtungen werden vom Framework automatisch an das Netz übergeben. Der Decision Requester steuert die Entscheidungsfrequenz: Eine Entscheidung wird alle fünf Simulationsschritte angefordert, zwischen zwei Entscheidungen wird die zuletzt gewählte Aktion wiederholt. Diese Entscheidungsfrequenz reduziert den Trainingsaufwand, ohne die Steuerbarkeit in der grid-basierten Umgebung merklich einzuschränken, da sich der Agent zwischen zwei Entscheidungen nur einen Bruchteil einer Zelle weit bewegt.

Zur Validierung der Umgebung wurde der in ML-Agents integrierte Heuristik-Modus genutzt, in dem sich der Agent manuell über die Tastatur steuern lässt, indem die Heuristic-Methode der Agent-Basisklasse mit einer Tastaturbelegung überschrieben wird. @juliani_unity_2020 Dieser Modus diente der Prüfung der gesamten Wirkkette vor dem ersten Training: Bewegung, Sprungmechanik, Sensorwerte, Trigger-Erkennung und Belohnungsvergabe konnten so unabhängig vom Lernverfahren geprüft werden. Zusätzlich wurde eine separate Sensor-Testszene aufgebaut, die alle Hindernistypen enthält und in der die Sensorparameter visuell kalibriert und validiert wurden. Diese Prüfschritte sind methodisch relevant: Fehler in Sensorik oder Belohnungslogik würden sich andernfalls erst indirekt über ausbleibenden Lernfortschritt zeigen und wären dann nur schwer von Konfigurationsproblemen des Lernverfahrens zu unterscheiden.


=== Trainingskonfiguration, Trainingsworkflow, Beobachtbarkeit und Inferenz

Die Trainingskonfiguration ist vollständig in einer versionierten YAML-Datei hinterlegt, die dem Trainer beim Start übergeben wird. Ein Trainingslauf wird über den Kommandozeilenaufruf des Trainers gestartet, wobei die Konfigurationsdatei und eine eindeutige Laufkennung (run-id) übergeben werden. Die Laufkennung bestimmt das Ergebnisverzeichnis, in dem sämtliche Artefakte des Laufs abgelegt werden: die verwendete Konfiguration, die TensorBoard-Ereignisprotokolle, die Laufstatistiken sowie die Modell-Checkpoints. Unterbrochene Läufe können über die Laufkennung fortgesetzt werden. Ein Neustart unter derselben Kennung erfordert eine explizite Bestätigung, wodurch ein versehentliches Überschreiben von Ergebnissen verhindert wird. Diese Systematik stellt sicher, dass jeder Trainingslauf eindeutig identifizierbar und mitsamt seiner Konfiguration archiviert ist, eine Voraussetzung für die in der Aufgabenstellung geforderte Reproduzierbarkeit.

Während des Trainings wurden alle 10.000 Schritte TensorBoard-Zusammenfassungen der protokollierten Metriken geschrieben, was bei vollem Budget eine Lernkurve mit 200 Datenpunkten ergibt. Alle 200.000 Schritte wurde ein Modell-Checkpoint gespeichert, wobei die jeweils letzten fünf Checkpoints vorgehalten wurden. Bei instabilem Trainingsverlauf ist damit ein Rückgriff auf frühere Modellstände möglich.

Nach Abschluss des Trainings exportiert der Trainer das finale Modell im ONNX-Format (abgesehen vom Transformer). Für die Inferenz wird das exportierte Modell im Unity-Inspector den Behavior Parameters des Agenten zugewiesen und der Verhaltensmodus auf Inferenz gestellt, der Agent handelt dann ohne laufenden Python-Prozess allein auf Basis der trainierten Policy, ausgeführt über die in Unity integrierte Inferenz-Laufzeitumgebung. Dieser Mechanismus wird für die Videodemonstrationen der finalen Läufe genutzt. Die Generalisierungs-Evaluation der drei Vergleichsmodelle erfolgt dagegen einheitlich über Python-Inferenz (@sec:evalprotokoll).


// ============================================================================
// 8. EVALUATION UND ERGEBNISSE  — nur FINALE Vergleiche (keine Doppelung mit 7.6)
//DAVID ============================================================================
= Evaluation <sec:evaluation>

// HINWEIS: finale vollständige Läufe 
// ggf. noch nicht abgeschlossen -> Zwischenergebnisse kennzeichnen.

== MLP-Baseline <sec:eval-mlp-baseline>
Als Funktionsnachweis der Trainings- und Evaluationspipeline wird zunächst die MLP-Baseline betrachtet. Im finalen Vergleichslauf (final_v3, 30 Mio. Trainingsschritte) erreicht die MLP-Baseline über den Trainingsverlauf eine maximale Erfolgsrate von 88,6 %; dieser Spitzenwert tritt bei rund 11,7 Mio. Schritten auf. Am Ende des Trainings liegt die Erfolgsrate bei 66,2 % bei einem mittleren kumulativen Reward von 16,4. Die verbleibenden Episoden entfallen auf Lava-Kollisionen (15,4 %), Timeouts (12,3 %) und Loch-Stürze (6,2 %); Erfolge und Fehlschläge summieren sich damit erwartungsgemäß zu 100 %.

Damit bestätigt die MLP-Baseline den Kern der in @sec:mlp-erwartungen formulierten Erwartung. Dank Zielrichtungsvektor und Ray-Sensorik erlernt das MLP eine effektive reaktive Zielansteuerung mit lokaler Hindernisvermeidung und löst die Mehrzahl der Episoden erfolgreich. Die Trainingsumgebung, die Belohnungsfunktion sowie die PPO-Trainingspipeline erweisen sich damit als grundsätzlich geeignet, erfolgreiches Navigationsverhalten hervorzubringen.

Ob und in welchem Umfang temporales Gedächtnis über dieses Leistungsniveau hinaus zusätzliche Vorteile bietet, untersucht der folgende Architekturvergleich in @sec:architekturvergleiche.


//   — aus §6.1 hierher verschoben, gegen TensorBoard belegen (aus dem Code allein
//   nicht verifizierbar, nur der results-Ordner existiert)

== Architektur-Vergleiche <sec:architekturvergleiche>
Im Folgenden werden die trainingsseitigen Ergebnisse der drei Architekturen verglichen. Die Generalisierung auf zuvor ungesehenen Kartenlayouts wird anschließend gesondert in @sec:generalisierung betrachtet.

  #figure(
    image("assets/v3_traj.png", width: 90%),
    caption: [Trainingsverlauf des finalen Vergleichslaufs (final_v3): beste je erreichte Erfolgsrate pro Architektur über 30 Mio.
  Trainingsschritte.]
  ) <fig:traingsverlauf_v3_final>
// nach metriken vergleichen (keine ahnung trainingsgeschwindigkeit erfolgsrate und so kp)
=== Mehrwert temporalen Gedächtnisses (F1)
Wie @fig:traingsverlauf_v3_final zeigt, erreicht die MLP-Baseline auf der Trainingsseite die höchste Erfolgsrate (88,6 %), gefolgt vom Transformer (79,0 %) und dem LSTM (74,3 %). Auf Basis der Trainingsdaten ergibt sich damit zunächst keine Unterstützung für Hypothese H1. Die gedächtnisbehafteten Architekturen übertreffen die gedächtnislose Baseline innerhalb des betrachteten Trainingsbudgets nicht. Eine abschließende Bewertung von H1 lässt sich daraus jedoch noch nicht ableiten. Gemäß Evaluationsprotokoll (@sec:evalprotokoll) dient die Trainings-Erfolgsrate ausschließlich als Verlaufsgröße. Die Beantwortung der Forschungsfrage erfolgt erst anhand der Generalisierung auf die zurückgehaltenen Held-out-Maps in @sec:generalisierung .
Ein differenzierteres Bild ergibt der Vergleich der Todesursachen (jeweils Endwerte bei 30 Mio. Schritten). Während bei der MLP-Baseline Lava-Kollisionen (15,4 %) und Timeouts (12,3 %) in ähnlicher Größenordnung auftreten, treten bei LSTM und Transformer die Lava-Tode stärker in den Vordergrund (24,7 % beziehungsweise 18,7 %), während Timeouts nur noch einen geringen Anteil ausmachen (2,4 % beziehungsweise 3,3 %). Beim Transformer erreichen Loch-Stürze mit 18,7 % denselben Anteil wie die Lava-Tode, beim LSTM liegen sie bei 14,1 %.
Die Gedächtnisarchitekturen erreichen damit häufiger terminale Zustände durch direkte Interaktion mit Gefahrenfeldern, verbleiben jedoch deutlich seltener bis zum Ablauf des Zeitlimits in einer Episode. Unabhängig von der genauen Ursache deutet dieses Muster darauf hin, dass sich ihr Verhalten systematisch von der MLP-Baseline unterscheidet. Ob dies auf Unterschiede in der Exploration, der Bewegungsstrategie oder der Hindernisinteraktion zurückzuführen ist, lässt sich anhand der vorliegenden Kennzahlen jedoch nicht eindeutig beantworten.

=== LSTM vs. Transformer (F2)
Der finale kumulative Reward unterscheidet sich zwischen den Architekturen nur geringfügig (LSTM 16,5, MLP 16,4, Transformer 16,2). Die Belohnungsfunktion erlaubt damit keine klare Rangfolge der Modelle. Für die Beantwortung der Forschungsfragen besitzt die Erfolgsrate daher die höhere Aussagekraft.
Bei der Einordnung der Konvergenzgeschwindigkeit ist zu beachten, dass @fig:traingsverlauf_v3_final die jeweils beste erreichte Erfolgsrate darstellt, nicht jedoch den vollständigen Verlauf der rollierenden Erfolgsrate, auf dem die in @sec:evalprotokoll definierte Konvergenzmetrik basiert. Diese Eigenschaft lässt sich aus den verfügbaren Daten nicht belastbar rekonstruieren.
Von den drei Läufen kommt die MLP-Baseline der Konvergenzbedingung mit einem Bestwert von 88,6 % am nächsten.
Die formale Konvergenzmetrik liefert für den Vergleich von LSTM und Transformer keinen Unterschied: Beide Gedächtnisarchitekturen bleiben mit ihren Bestwerten unter der 80-%-Schwelle und sind rechtszensiert. Ihre rollierenden Erfolgsratenkurven verlaufen zudem nahezu deckungsgleich (Pearson-Korrelation r ≈ 0,91) und überschreiten das 0,7-Band beide erst spät bei etwa 21 Mio. Schritten, wo auch ein gemeinsamer Peak liegt; ein Konvergenzvorsprung einer der beiden Architekturen lässt sich daraus nicht ableiten. Deskriptiv erreicht der Transformer mit 79,0 % gegenüber 74,3 % die höhere Bestleistung. H2 wird damit in der Richtung der höheren Bestleistung gestützt, ist aber nicht formal quantifizierbar.
== Generalisierung auf held-out Maps <sec:generalisierung>

Auf den 155 zurückgehaltenen Karten (50 Easy, 50 Medium, 50 Hard und 5 Giant/OOD), die während des gesamten Trainings zu keinem Zeitpunkt präsentiert wurden, zeigt sich ein deutlich anderes Bild als auf der Trainingsseite. Insbesondere das LSTM verliert nahezu seine gesamte zuvor beobachtete Leistung, während MLP und Transformer einen Großteil ihres Leistungsniveaus auch auf ungesehenen Karten aufrechterhalten können.

#figure(
  image("assets/gen_v3.png", width: 90%),
  caption: [Held-out-Erfolgsrate je Schwierigkeitskategorie und Architektur (final_v3, 155 Karten, gepaarte Seeds).]
) <fig:final_v3>

Wie @fig:final_v3 zeigt, kollabiert die Erfolgsrate des LSTM auf allen Schwierigkeitsstufen nahezu vollständig (Easy 8 %, Medium 4 %, Hard 1 %, Giant 0 %) – trotz eines Trainings-Bestwerts von 74,3 %, der im Easy- und Medium-Bereich des Curriculums (Phase 5 und 6) und nicht auf der Hard-Stufe erreicht wurde, wo das Training höchstens 65,4 % erzielte (Abschnitt 8.2). MLP und Transformer generalisieren dagegen deutlich robuster und erreichen durchweg ähnliche Erfolgsraten (Easy 78 % beziehungsweise 84 %, Medium 84 % beziehungsweise 80 %, Hard 64 % beziehungsweise 56 %, Giant 40 % beziehungsweise 52 %).

Der Overfitting-Index (@sec:evalprotokoll) ist in @tab:overfitting je Kategorie und Architektur aufgeführt. Die zugrunde liegenden Trainings- und Held-out-Erfolgsraten sind in @tab:overfitting_detail im Anhang zusammengestellt. Beim LSTM ist der Index über alle Kategorien mit +57 bis +66 Prozentpunkten stark positiv – einem Trainingserfolg von 57 bis 74 % steht eine Held-out-Erfolgsrate von höchstens 8 % gegenüber –, was eine ausgeprägte Überanpassung an die Trainingskarten belegt. Bei MLP und Transformer bleibt der Index dagegen betragsmäßig unter zwölf Prozentpunkten und wechselt das Vorzeichen; Trainings- und Held-out-Erfolg liegen je Kategorie eng beieinander, sodass kein systematisches Overfitting erkennbar ist.

#figure(
  table(
    columns: 4,
    [*Kategorie*], [*MLP*], [*LSTM*], [*Transformer*],

    [Easy (Phase 5)], [+6,3 pp], [+66,3 pp], [−5,8 pp],
    [Medium (Phase 6)], [−11,7 pp], [+61,9 pp], [−9,8 pp],
    [Hard (Phase 7)], [−1,8 pp], [+56,7 pp], [+2,0 pp],
  ),
  caption: [Overfitting-Index je Kategorie (final_v3, 30 Mio. Steps): rollierende Trainings-Erfolgsrate am Phasenende minus Held-out-Erfolgsrate. Positive Werte bedeuten Überanpassung, negative eine bessere Held-out- als Trainingsleistung. Detailwerte in @tab:overfitting_detail.],
) <tab:overfitting>

Für die Kategorie Giant, die keine trainingsseitige Entsprechung besitzt, bleibt der Overfitting-Index gemäß Definition unbestimmt. Berichtet werden kann daher ausschließlich die absolute Erfolgsrate. Mit 40 % (MLP) beziehungsweise 52 % (Transformer) bewältigen beide Architekturen auch Karten, die die maximale Trainingsschwierigkeit überschreiten, in einem relevanten Anteil der Fälle. Das LSTM erreicht dagegen keinen einzigen Erfolg.

Damit lassen sich die zuvor offengehaltenen Hypothesen nun abschließend einordnen. H1 findet auch auf den Held-out-Daten keine konsistente Unterstützung: Der Transformer übertrifft die MLP-Baseline zwar auf Easy und Giant, fällt jedoch auf Medium und Hard dahinter zurück. Das LSTM fällt unabhängig davon in allen Kategorien deutlich hinter die Baseline zurück.

Für H3 ergibt sich ebenfalls ein differenziertes Bild. Das LSTM widerspricht der Hypothese klar, da es ein deutlich stärkeres Overfitting zeigt als die MLP-Baseline. Der Transformer erreicht dagegen eine Generalisierungsleistung, die insgesamt in derselben Größenordnung wie die der MLP-Baseline liegt. Eine Überlegenheit gegenüber dem gedächtnislosen Referenzmodell lässt sich aus den vorliegenden Ergebnissen jedoch nicht ableiten. H3 wird nicht gestützt; für das LSTM ist sie klar widerlegt (stärkstes Overfitting aller drei Architekturen), für den Transformer zeigt sich keine Überlegenheit gegenüber der Baseline.

Auf den fünf Giant-Karten erzielt der Transformer mit 52 % die höchste Erfolgsrate, vor MLP (40 %) und LSTM (0 %). Angesichts der geringen Fallzahl (n=5) ist dieser Unterschied jedoch rein deskriptiv zu lesen und lässt keine belastbare Aussage über die tatsächliche Robustheit einer Architektur außerhalb der trainierten Schwierigkeitsstufen zu. Für F3 bleibt damit festzuhalten, dass sich MLP und Transformer auf den regulären, statistisch tragfähigeren Kategorien (Easy, Medium, Hard) nicht eindeutig unterscheiden, während das LSTM in allen Kategorien deutlich abfällt.

// - 3 unabhängige Eval-Maps, Erfolgs-/Kollisionsrate, Overfitting-Index

== Statistische Auswertung

// - Mann-Whitney U + Bonferroni, Cliff's Delta, Bootstrap-CI, Lernkurven mit CI-Band
Die statistische Prüfung erfolgt gemäß dem in @sec:evalprotokoll festgelegten Verfahren auf Ebene der einzelnen Held-out-Karte (n = 50 für Easy, Medium und Hard; Giant mit n = 5 rein deskriptiv). Da alle drei Architekturen auf identischen Karten mit identischen Seeds evaluiert wurden, liegt ein gepaartes Design vor. Entsprechend kommt pro Kategorie zunächst ein Friedman-Test über alle drei Architekturen zum Einsatz, gefolgt von paarweisen Wilcoxon-Vorzeichen-Rang-Tests als Post-hoc-Verfahren mit Bonferroni-Korrektur (Familie: 3 Architekturpaare × 3 Kategorien = 9 Tests, α' ≈ 0,0056).

Der Friedman-Test weist in allen drei Kategorien einen statistisch signifikanten Unterschied zwischen den Architekturen nach (Easy: χ² = 68,1; Medium: χ² = 66,9; Hard: χ² = 54,3; jeweils df = 2, p < 10⁻¹¹). Die Nullhypothese gleicher Erfolgsraten über alle drei Architekturen wird damit in jeder Kategorie verworfen. Zur Identifikation der verantwortlichen Architekturpaare folgen die in @sec:evalprotokoll definierten Wilcoxon-Vorzeichen-Rang-Tests als Post-hoc-Analyse.

#figure(
  table(
    columns: 5,
    [Kategorie], [Vergleich], [p (Bonferroni)], [Effektstärke r], [Differenz, 95%-Bootstrap-CI],
    [Easy], [MLP – LSTM], [2,2·10⁻⁸], [1,00], [+61,6 bis +78,8 pp],
    [Easy], [LSTM – Transformer], [6,6·10⁻⁹], [−1,00], [−83,6 bis −69,2 pp],
    [Easy], [MLP – Transformer], [1,000], [−0,27], [−14,4 bis +2,0 pp],
    [Medium], [MLP – LSTM], [7,2·10⁻⁹], [1,00], [+70,8 bis +87,6 pp],
    [Medium], [LSTM – Transformer], [1,3·10⁻⁸], [−1,00], [−83,6 bis −67,2 pp],
    [Medium], [MLP – Transformer], [1,000], [0,24], [−3,2 bis +11,2 pp],
    [Hard], [MLP – LSTM], [1,0·10⁻⁷], [1,00], [+52,0 bis +72,8 pp],
    [Hard], [LSTM – Transformer], [8,2·10⁻⁸], [−1,00], [−64,4 bis −46,4 pp],
    [Hard], [MLP – Transformer], [1,000], [0,25], [−3,6 bis +18,0 pp],
  ),
  caption: [Paarweise Wilcoxon-Vorzeichen-Rang-Tests je Kategorie, Bonferroni-korrigiert (final_v3).]
) <tab:wilcoxon>

Wie @tab:wilcoxon zeigt, unterscheidet sich das LSTM in allen drei Kategorien signifikant von sowohl MLP als auch Transformer. Die Effektstärken liegen dabei durchgehend bei |r| = 1,00, was auf einen außergewöhnlich konsistenten Unterschied zwischen den Architekturen hinweist. Nahezu jedes Kartenpaar fällt zugunsten von MLP beziehungsweise Transformer aus.

Zwischen MLP und Transformer kann dagegen in keiner Kategorie ein signifikanter Unterschied nachgewiesen werden. Die zugehörigen Bootstrap-Konfidenzintervalle der Differenz schließen die Null jeweils mit ein, und die Effektstärken bleiben klein. Die statistische Auswertung bestätigt damit die qualitative Beobachtung aus @sec:generalisierung , dass sich beide Architekturen hinsichtlich ihrer Generalisierungsleistung nicht eindeutig unterscheiden.

Für die Kategorie Giant (n = 5) wird gemäß Definition kein Test durchgeführt; die deskriptiven Erfolgsraten (MLP 40 %, Transformer 52 %, LSTM 0 %) sind @sec:generalisierung zu entnehmen.

Diese Ergebnisse gelten für die konkret trainierten Modellinstanzen dieses einen Laufs mit festem Seed (42) und beschreiben deren Generalisierung auf Kartenebene. Eine Aussage über die jeweilige Architektur im Erwartungswert über verschiedene Trainings-Seeds hinweg lässt sich daraus nicht ableiten. Die in @sec:diskussion diskutierte Divergenz zwischen final_v2 und final_v3 unterstreicht diesen Vorbehalt zusätzlich.

== Diskussion <sec:diskussion>
Die Ergebnisse des finalen Vergleichslaufs (final_v3) liefern insgesamt keine Unterstützung für die Annahme, dass ein expliziter Gedächtnismechanismus unter den Randbedingungen dieser Arbeit zwangsläufig zu besserer Navigationsleistung oder Generalisierung führt. Weder LSTM noch Transformer übertreffen die MLP-Baseline konsistent auf den Held-out-Karten, und das LSTM fällt hinsichtlich seiner Generalisierungsleistung sogar deutlich hinter die Baseline zurück. Die in H1 formulierte Erwartung, dass Gedächtnisarchitekturen die gedächtnislose Baseline übertreffen, findet in den vorliegenden Daten keine Unterstützung.

#figure(
  image("assets/reversal.png", width: 90%),
  caption: [Rangfolge-Umkehr: mittlerer Held-out-Erfolg je Architektur zwischen final_v2 (16,6 Mio. Schritte) und final_v3 (30 Mio. Schritten).]
) <fig:reversal>

Gleichzeitig zeigen die Ergebnisse, dass die Wahl der Architektur nicht isoliert von den Trainingsbedingungen betrachtet werden kann. Wie @fig:reversal verdeutlicht, reagierten die drei Architekturen unterschiedlich auf ein erhöhtes Trainingsbudget. Die beobachteten Rangfolgewechsel zwischen beiden Läufen stellen damit selbst einen wichtigen Befund dar. Architekturvergleiche können nicht losgelöst von Trainingsdauer und Hyperparameterwahl interpretiert werden, da dieselbe Architektur bei verändertem Trainingsbudget zu einer anderen Bewertung gelangen kann.

Für MLP und LSTM lässt sich diese Budget-Abhängigkeit vergleichsweise klar interpretieren, da zwischen final_v2 und final_v3 keine Änderungen an der Konfiguration vorgenommen wurden. Die MLP-Baseline zeigt ein stabiles Verhalten und profitiert moderat von zusätzlichem Training. Das LSTM erreicht dagegen zunächst hohe Erfolgsraten, verliert diese bei längerem Training jedoch nahezu vollständig. Gemeinsam mit dem stark erhöhten Overfitting-Index ist dieses Verhalten mit zwei Deutungen konsistent — einer ausgeprägten Überanpassung an die Trainingskarten oder einer späten Trainingsinstabilität; die Datenlage erlaubt keine Entscheidung zwischen beiden (@sec:evalprotokoll).

Die Interpretation des Transformers ist schwieriger. Zwischen final_v2 und final_v3 wurden mehrere Hyperparameter angepasst, sodass längeres Training und verbessertes Tuning nicht voneinander getrennt betrachtet werden können. Der Leistungszuwachs des Transformers kann daher nicht eindeutig einer einzelnen Ursache zugeordnet werden. Festhalten lässt sich jedoch, dass der Transformer in seiner finalen Konfiguration auf den Giant-Karten die höchste deskriptive Erfolgsrate erzielt (52 % gegenüber 40 % bei MLP). Bei einer Fallzahl von n = 5 lässt sich daraus jedoch, wie in @sec:generalisierung begründet, keine belastbare Aussage über tatsächliche Robustheit außerhalb des Trainingsbereichs ableiten.

Trotz der statistisch abgesicherten Unterschiede zwischen LSTM und den beiden anderen Architekturen bleiben die Ergebnisse vorsichtig zu interpretieren. Jede Architektur wurde pro Budget-Stufe nur mit einem einzigen Trainings-Seed trainiert. Die vorliegende Arbeit erlaubt daher Aussagen über die beobachteten Modellinstanzen, nicht jedoch über die jeweilige Architektur im Erwartungswert über viele unabhängige Trainingsläufe hinweg. Die Unterschiede zwischen final_v2 und final_v3 sind deshalb nicht nur Ergebnisdaten, sondern zugleich ein Hinweis auf die Bedeutung der Trainingsvarianz für die Bewertung von Reinforcement-Learning-Systemen.

Auf der Verhaltensebene zeigt sich darüber hinaus ein gemeinsames Muster aller drei Architekturen. Keine der Varianten integrierte die Sprung-Teilaufgabe erkennbar in ihre Navigationsstrategie. Erfolgreiche Episoden beruhen überwiegend auf dem Umgehen von Gefahrenfeldern und nicht auf deren aktivem Überqueren. Getragen wird dieser Befund in erster Linie von der Erfolgsrate selbst, denn die Kartengenerierung lässt nur nachweislich lösbare Layouts zu, bei denen Lava lediglich in Tiefe 1 und damit ausschließlich per Sprung passierbar ist. Karten, deren einziger Lösungsweg über eine solche Überquerung führt, wären ohne erlernte Sprungfähigkeit unlösbar. Dass die Agenten dennoch einen Großteil der Karten bewältigen, während terminale Lava-Kontakte häufig bleiben, deutet darauf hin, dass sie umgehbare Karten lösen und an sprungpflichtigen scheitern. Der ohnehin als Messartefakt einzustufende Überquerungszähler dient dabei nur als schwächere Zweitbestätigung. Dieser Befund tritt architekturübergreifend auf und kann daher nicht als Folge fehlenden Gedächtnisses interpretiert werden. Stattdessen deutet er darauf hin, dass die Sprungaufgabe innerhalb der vorliegenden Belohnungs- und Umgebungsstruktur nicht zuverlässig in das erlernte Verhalten integriert wurde.

Zusätzliche Plausibilität erhält diese Interpretation durch die Iterationshistorie des Reward-Designs. Mehrere Trainingsläufe zeigten, dass zusätzliche Belohnungssignale zwar notwendig waren, um überhaupt Lernfortschritte zu ermöglichen, zugleich jedoch wiederholt zu unerwünschten Nebeneffekten führten. Auch im finalen System kann deshalb nicht ausgeschlossen werden, dass einzelne Verhaltensmuster teilweise durch Eigenschaften des Reward-Designs beeinflusst werden. Zur abschließenden Bewertung dieses Zusammenhangs wäre eine detaillierte Analyse einzelner Episodenverläufe erforderlich, die außerhalb des Umfangs dieser Arbeit liegt. Als weiterer Einflussfaktor kommt hinzu, dass die Ray-Kanäle für Obstacle und Bridge mangels Laufzeit-Träger keinen informativen Beitrag liefern, was jedoch alle drei Architekturen gleichermaßen betrifft. Ein weiterer möglicher Einflussfaktor liegt im Beobachtungsraum. Die Ray-Sensorik sieht zwar Kanäle für die Tags Obstacle und Bridge vor, die zugehörigen Objekttypen besitzen im finalen Lauf jedoch keine beziehungsweise keine konsistenten Laufzeit-Träger. Diese Dimensionen liefern somit keinen informativen Beitrag zur Wahrnehmung. Da dies alle drei Architekturen gleichermaßen betrifft, entsteht daraus kein unmittelbarer Gruppenunterschied. Die zusätzlichen, inhaltlich leeren Eingabedimensionen können jedoch die effektive Repräsentation des Zustands und die Lernstabilität beeinflusst haben.

// - Bewertung H1-H3, welche Architektur lernt schneller / generalisiert besser
// - Beobachtetes Verhalten (Wall-Hugging, Lava-Avoidance, PBRS-Artefakte)


// ============================================================================
// 9. ÜBERTRAGBARKEIT UND PRAKTISCHE ANWENDBARKEIT  (verweist zurück auf 1.1/1.2)
// ============================================================================


= Übertragbarkeit und praktische Anwendbarkeit

// Datenbasis: final_v3 (einziger Lauf mit vollem 30-M-Budget).
// Setup-Vergleichbarkeit: identische Konfiguration ALLER drei Behaviors
// (inkl. Transformer V22) in v2 und v3, Unterschied ausschließlich das
// Trainingsbudget (16,6 M vs. 30 M Steps) -> Leistungsdifferenzen zwischen
// den Läufen sind als Budget-Effekte interpretierbar.
//
// Interpretation der Budget-Effekte (als Deutung kennzeichnen, n=1 je Budget):
// - Transformer: bei 16,6 M schwach (v2: 57,2 % Easy), bei 30 M stark
//   (v3: 84,4 % Easy, 52 % Giant). Bewusst NICHT "konvergiert": die Trainings-
//   Beste-Success liegt bei 79,0 % und damit UNTER der 80%-Schwelle der
//   F2-Konvergenzdefinition [§13.5]. Deutung: höhere ENDLEISTUNG bei höherem
//   Trainingsbudget -> stützt H2 aus Kap. 1.5 qualitativ (die "bis Konvergenz"-
//   Formulierung nur eingeschränkt, da 80%-Schwelle im Training nicht erreicht)
// - LSTM: bei 16,6 M Spitze (90,4 % Easy), bei 30 M Kollaps (0–8 %) —
//   mutmaßlich Overfitting, gestützt durch extreme Trainings-/Held-out-Lücke
//   (Training-Rolling ~57,5 % vs. Held-out 4–8 %, SSOT §13.4)
// - MLP: einzige Architektur mit konsistentem Verhalten über beide Budgets
//   (steigt von 64,0 % auf 78,4 % Easy)
//
// Gewichts-Begründungen (je Zeile ausformulieren):
// - Generalisierung 0,30: zentrales Qualitätskriterium der Arbeit (Kap. 1.3)
// - Budget-Robustheit 0,20: Praxis: Trainingsbudget ist begrenzt und der
//   optimale Stopp-Zeitpunkt a priori unbekannt — eine Architektur, die bei
//   "falschem" Budget kollabiert oder unterperformt, ist riskant
// - Deployability 0,15: Kapitelzweck "praktische Anwendbarkeit"
// - OOD-Robustheit 0,15: Umgebungen außerhalb der Trainingsverteilung sind
//   in der Praxis der Normalfall
// - Inferenz-/Modellkosten 0,10: viele Instanzen (NPCs) / schwache Hardware
// - Trainingsaufwand 0,10: einmalige Kosten -> geringstes Gewicht
/*
#figure(
  table(
    columns: 5,
    [*Kriterium*], [*Gewicht*], [*MLP*], [*LSTM*], [*Transformer*],

    [Generalisierung Held-out (Easy–Hard, v3)], [0,30],
      [78,4 / 83,6 / 63,6 %], [8,0 / 4,0 / 0,8 %], [84,4 / 79,6 / 56,4 %],
    [Budget-Robustheit (16,6 M #sym.arrow.l.r 30 M)], [0,20],
      [konsistent, steigend], [Kollaps bei 30 M (mutmaßl. Overfitting)], [erst bei 30 M leistungsstark],
    [Deployability (ONNX/Barracuda)], [0,15],
      [ja], [ja], [nein (nur Python)],
    [OOD-Robustheit (Giant, v3)], [0,15],
      [40,0 %], [0,0 %], [52,0 %],
    [Inferenz-/Modellkosten (Memory-Modul)], [0,10],
      [0 Param., zustandslos], [197 632 Param.], [1 074 752 Param.],
    [Trainingsaufwand], [0,10],
      [gering], [mittel], [hoch (volle 30 M, größte Batch/Buffer)],
  ),
  caption: [Bewertungsmatrix der drei Architekturen (Datenbasis: final_v3, 30 M Steps, Budget-Robustheit unter Einbezug von final_v2, 16,6 M Steps)],
) <tab_bewertungsmatrix>

#figure(
  table(
    columns: 4,
    [*Kategorie*], [*MLP*], [*LSTM*], [*Transformer*],

    [Easy (50 Karten)], [78,4 % (64,0 %)], [8,0 % (90,4 %)], [84,4 % (57,2 %)],
    [Medium (50)], [83,6 % (61,6 %)], [4,0 % (88,4 %)], [79,6 % (56,0 %)],
    [Hard (50)], [63,6 % (36,4 %)], [0,8 % (69,6 %)], [56,4 % (29,6 %)],
    [Giant (5, OOD)], [40,0 % (16,0 %)], [0,0 % (48,0 %)], [52,0 % (8,0 %)],
  ),
  caption: [Erfolgsraten im Generalisierungstest: final_v3 mit 30 M Steps (in Klammern: final_v2 mit 16,6 M Steps), identische Konfigurationen, 155 Held-out-Karten, 5 Episoden, paarweise faire Seeds],
) <tab_generalisierung_ergebnisse>
*/
// Empfehlung je Einsatzszenario (aus Matrix ableiten):
// - Spiele-NPCs (Unity-Inferenz): MLP — deploybar, budget-robust, günstigste
//   Inferenz pro Instanz, Transformer technisch ausgeschlossen (Barracuda),
//   LSTM wegen Overfitting-Risiko bei langem Training nur mit Vorbehalt
// - Serviceroboter (Embedded/CPU): MLP — beste Kombination Deployability +
//   Robustheit + Generalisierung, explizit qualitativ (kein Sim-to-Real)
// - Hohe Layout-Varianz / OOD-lastig (Logistik): Transformer — beste
//   Giant-Leistung (52 %) und beste Easy-Generalisierung bei ausreichendem
//   Budget, nur falls Python-Inferenz-Stack akzeptabel
// - Übergreifender Vorbehalt IN die Matrix-Diskussion: ein Seed (42),
//   ein Lauf je Budget-Stufe -> die kausale Deutung (Budget-Effekt beim
//   Transformer, Overfitting beim LSTM) ist plausibel und durch die
//   Trainings-/Held-out-Lücke gestützt, aber ohne Wiederholungsläufe nicht
//   statistisch abgesichert (SSOT §12-#4)

== Bewertungsmatrix <sec:bewertungsmatrix>

Die abschließende Bewertung stützt sich in erster Linie auf den Lauf final_v3, der als einziger über das volle Trainingsbudget von 30 Millionen Steps verfügt. Warum sich die beiden Läufe für MLP und LSTM innerhalb der Trainer-Konfiguration ausschließlich im Budget unterscheiden, beim Transformer dagegen Budget und Hyperparameter konfundiert sind, wurde in den Abschnitten 5.3 und 5.5 hergeleitet und wird hier nicht wiederholt. Da je Budgetstufe nur ein Lauf mit einem einzigen Seed vorliegt und die Läufe zudem auf unterschiedlichen Rechnern und venv-Ständen liefen, sind die folgenden Ergebnisse als Deutung und nicht als statistisch gesicherter Befund zu verstehen.

Wie die Architekturen auf ein größeres Trainingsbudget reagieren, fällt sehr unterschiedlich aus und prägt die gesamte Bewertung. Der Transformer zeigt bei 16,6 Millionen Steps mit 57,2 % auf den Easy-Karten eine schwache Generalisierung, erreicht bei 30 Millionen Steps jedoch 84,4 % auf Easy und 52,0 % auf den Giant-Karten, wobei dieser Sprung mit den vier geänderten Hyperparametern konfundiert ist und nicht allein dem Budget zugeschrieben werden kann. Von einer Konvergenz kann dennoch nicht gesprochen werden, denn der beste im Training erzielte Erfolgswert bleibt mit 79,0 % unter der methodisch gesetzten 80-Prozent-Schwelle der Konvergenzdefinition F2. Die höhere Endleistung bei höherem Budget stützt die methodisch formulierte Hypothese H2 damit qualitativ, während der auf die Konvergenzgeschwindigkeit bezogene Teil unbeantwortet bleibt (nicht formal quantifizierbar), weil die 80-%-Schwelle im Training nicht erreicht wurde. Das LSTM verhält sich genau gegenläufig. Seine Spitzenleistung von 90,4 % auf den Easy-Karten erreicht es bereits bei 16,6 Millionen Steps, während seine Erfolgsraten bei 30 Millionen Steps über alle Kategorien hinweg auf Werte zwischen 0 und 8 % einbrechen. Dieser Einbruch deutet auf Overfitting hin und wird durch die große Lücke zwischen Trainings- und Held-out-Leistung gestützt, denn einem gleitenden Trainingserfolg von rund 57,5 % steht eine Held-out-Leistung von nur 4 bis 8 % auf Easy und Medium und noch darunter auf Hard und Giant gegenüber. Das MLP ist die einzige Architektur, die über beide Budgets hinweg konsistent bleibt und ihre Easy-Erfolgsrate von 64,0 % auf 78,4 % steigert. Es reagiert als einzige Variante vorhersehbar auf zusätzliches Training, ohne von einem bestimmten Stopp-Zeitpunkt abzuhängen. Die vollständigen Erfolgsraten über die Kategorien Easy bis Hard sowie die zum Vergleich herangezogenen Werte aus final_v2 sind in @tab_generalisierung_ergebnisse aufgeführt.

#figure(
  table(
    columns: 4,
    [*Kategorie*], [*MLP*], [*LSTM*], [*Transformer*],

    [Easy (50 Karten)], [78,4 % (64,0 %)], [8,0 % (90,4 %)], [84,4 % (57,2 %)],
    [Medium (50)], [83,6 % (61,6 %)], [4,0 % (88,4 %)], [79,6 % (56,0 %)],
    [Hard (50)], [63,6 % (36,4 %)], [0,8 % (69,6 %)], [56,4 % (29,6 %)],
    [Giant (5, OOD)], [40,0 % (16,0 %)], [0,0 % (48,0 %)], [52,0 % (8,0 %)],
  ),
  caption: [Erfolgsraten im Generalisierungstest: final_v3 mit 30 M Steps (in Klammern: final_v2 mit 16,6 M Steps), identische MLP- und LSTM-Konfiguration, Transformer-Config in vier Hyperparametern verändert, 155 Held-out-Karten, 5 Episoden, paarweise faire Seeds],
) <tab_generalisierung_ergebnisse>

Um diese Beobachtungen mit den praktisch relevanten Eigenschaften der Modelle zu verbinden, fasst @tab_bewertungsmatrix sechs Kriterien mit unterschiedlicher Gewichtung zusammen. Das höchste Gewicht von 0,30 erhält die Generalisierung auf den Held-out-Karten, weil sie das zentrale Qualitätskriterium dieser Arbeit darstellt. Mit 0,20 folgt die Budget-Robustheit, die abbildet, wie verlässlich eine Architektur über verschiedene Trainingsbudgets hinweg bleibt. Ihr hohes Gewicht ergibt sich aus der Praxis, in der das Budget begrenzt und der optimale Stopp-Zeitpunkt im Voraus nicht bekannt ist. Eine Architektur, die beim falsch gewählten Budget einbricht oder unterperformt, stellt damit ein reales Risiko dar. Deployability und OOD-Robustheit gehen mit jeweils 0,15 ein. Die Deployability trägt dem Zweck des Kapitels Rechnung, die praktische Anwendbarkeit der Modelle zu beurteilen, und unterscheidet nach der Frage, ob sich ein Modell über ONNX exportieren und in der Unity-Laufzeitumgebung Barracuda ausführen lässt. MLP und LSTM erfüllen diese Bedingung, der Transformer läuft ausschließlich unter Python. Die OOD-Robustheit erhält dasselbe Gewicht, weil Umgebungen außerhalb der Trainingsverteilung in der Praxis den Normalfall bilden. Gemessen wird sie an der Giant-Kategorie, in der der Transformer mit 52,0 % vorn liegt, das MLP 40,0 % erreicht und das LSTM vollständig versagt. Die beiden verbleibenden Kriterien wiegen mit je 0,10 am geringsten. Die Inferenz- und Modellkosten bemessen sich am Umfang des Memory-Moduls, das beim zustandslosen MLP keine zusätzlichen Parameter benötigt, beim LSTM 197 632 und beim Transformer 1 074 752 Parameter umfasst. Dieser Unterschied wird relevant, sobald viele Instanzen gleichzeitig laufen, etwa als NPCs, oder die Hardware schwach ist. Der Trainingsaufwand erhält das gleiche Gewicht, fällt als einmalige Kosten aber am wenigsten ins Gewicht. Er ist beim MLP gering, beim LSTM mittel und beim Transformer hoch, der die größten Batch- und Buffergrößen beansprucht.

#figure(
  table(
    columns: 5,
    [*Kriterium*], [*Gewicht*], [*MLP*], [*LSTM*], [*Transformer*],

    [Generalisierung Held-out (Easy–Hard, v3)], [0,30],
      [78,4 / 83,6 / 63,6 %], [8,0 / 4,0 / 0,8 %], [84,4 / 79,6 / 56,4 %],
    [Budget-Robustheit (16,6 M #sym.arrow.l.r 30 M)], [0,20],
      [konsistent, steigend], [Kollaps bei 30 M (mutmaßl. Overfitting)], [bei 30 M leistungsstark, Budgetsprung jedoch mit vier geänderten Hyperparametern konfundiert],
    [Deployability (ONNX/Barracuda)], [0,15],
      [ja], [ja], [nein (nur Python)],
    [OOD-Robustheit (Giant, v3)], [0,15],
      [40,0 %], [0,0 %], [52,0 %],
    [Inferenz-/Modellkosten (Memory-Modul)], [0,10],
      [0 Param., zustandslos], [197 632 Param.], [1 074 752 Param.],
    [Trainingsaufwand], [0,10],
      [gering], [mittel], [hoch (größte Batch/Buffer)],
  ),
  caption: [Bewertungsmatrix der drei Architekturen (Datenbasis: final_v3, 30 M Steps, Budget-Robustheit unter Einbezug von final_v2, 16,6 M Steps)],
) <tab_bewertungsmatrix>

In der Zusammenschau ergibt sich ein klares Bild. Das MLP vereint Deployability, Budget-Robustheit und eine solide Generalisierung bei den geringsten Inferenzkosten und ist damit die ausgewogenste Architektur. Der Transformer erreicht die höchste Generalisierung und die beste OOD-Leistung, ist für die Unity-Inferenz jedoch technisch ausgeschlossen und verursacht die höchsten Kosten. Das LSTM disqualifiziert sich durch seinen Einbruch bei langem Training, obwohl es bei knappem Budget die stärksten Einzelwerte liefert.

Aus dieser Gewichtung lassen sich für die betrachteten Einsatzszenarien konkrete Empfehlungen ableiten. Für Spiele-NPCs mit Inferenz in Unity ist das MLP die geeignete Wahl, da es deploybar und budget-robust ist und pro Instanz die günstigste Inferenz bietet. Der Transformer scheidet hier technisch aus, weil Barracuda ihn nicht ausführen kann, und das LSTM kommt wegen seines Overfitting-Risikos bei langem Training nur mit Vorbehalt infrage. Für Serviceroboter mit eingebetteter oder CPU-basierter Ausführung empfiehlt sich ebenfalls das MLP, weil es Deployability, Robustheit und Generalisierung am besten verbindet. Diese Empfehlung bleibt ausdrücklich qualitativ, da kein Sim-to-Real-Transfer durchgeführt wurde. Sobald die Layout-Varianz sehr hoch ist und Umgebungen außerhalb der Trainingsverteilung überwiegen, wie es etwa in der Logistik der Fall ist, ist der Transformer vorzuziehen, denn er liefert mit 52,0 % die beste Giant-Leistung und bei ausreichendem Budget die beste Easy-Generalisierung. Diese Wahl setzt allerdings voraus, dass ein Python-basierter Inferenz-Stack akzeptabel ist.

Alle genannten Deutungen beruhen auf einem einzigen Seed, der Nummer 42, und auf jeweils einem Lauf pro Budgetstufe. Die kausalen Interpretationen, also der Budgeteffekt beim MLP und das Overfitting beim LSTM, sind plausibel und werden durch die deutliche Lücke zwischen Trainings- und Held-out-Leistung gestützt. Der Leistungssprung beim Transformer lässt sich dagegen nicht sauber als Budgeteffekt deuten, weil er mit den vier geänderten Hyperparametern konfundiert ist. Ohne Wiederholungsläufe lassen sie sich jedoch nicht statistisch absichern, was bei der Übertragung der Empfehlungen zu berücksichtigen ist.

== Limitationen der Übertragbarkeit <sec:limitationen-uebertragbarkeit>

// - 2D-Abstraktion: Zellgitter (CellType-Grid, cellSize 1), "3D" nur
//   Wandhöhe, Plattformen (+0,75), Sprungmechanik, diskreter Aktionsraum
//   [3,3,3] (§3, §6) statt kontinuierlicher Kinematik, keine Rampen,
//   Unebenheiten, engen Durchfahrten
// - Statische Hindernisse: keine Laufzeit-Hindernisplatzierung, keine
//   dynamischen Objekte (§6.3 NICHT VORHANDEN, Kap. 1.6 abgegrenzt),
//   "Veränderungen während des Betriebs" (Kap. 1.2) nur als Variation
//   ZWISCHEN Episoden abgebildet, nie INNERHALB einer Episode
// - Sim-to-Real-Gap: explizit ausgeklammert (Kap. 1.6), deterministische,
//   idealisierte Physik (Fixed Timestep 0,02, keine Latenz, kein Schlupf,
//   §4), Episoden-Reset/KillZone ohne reales Gegenstück, time-scale 40
// - Idealisierte Sensorik: Rays liefern rauschfreie semantische
//   Klassifikation über Tags (§2.4), PRIVILEGIERTE INFORMATION in den
//   Beobachtungen: exakte Zieldistanz, lokale Zielrichtung, Line-of-Sight
//   (Obs 23–31, §2.1) + PBRS-Shaping auf Luftlinien-Zieldistanz (§5) —
//   setzt globale Lokalisierung und bekannte Zielkoordinaten voraus,
//   zudem tote Sensorkanäle (Obstacle/Bridge ohne Laufzeit-Träger, §6.2/§12)
// - Statistische/methodische Limitation: ein Seed je Architektur, ein Lauf
//   je Budget-Stufe (16,6 M / 30 M) — die Budget- und Overfitting-Deutungen
//   sind dadurch nicht gegen Stochastik abgesichert (§12-#4). Zusätzlich:
//   kein Konvergenzkriterium und keine validierungsbasierte
//   Checkpoint-Auswahl (§12-#3) — evaluiert wurden Endstand-Checkpoints,
//   der LSTM-Leistungseinbruch blieb daher während des Trainings unentdeckt
//   (mit Held-out-Zwischenevaluation wäre ein früherer Checkpoint wählbar
//   gewesen). Einzelagent-Setting als weitere Grenze (Kap. 1.6)

Die untersuchte Umgebung beruht auf einer zweidimensionalen Abstraktion. Der Raum wird über ein Zellgitter (CellType-Grid) mit einer Zellgröße von 1 beschrieben, und eine dritte Dimension entsteht nur in reduzierter Form aus der Wandhöhe, aus um 0,75 angehobenen Plattformen und aus einer Sprungmechanik. Auch die Steuerung bleibt diskret, da der Aktionsraum mit der Form [3,3,3] festgelegt ist und keine kontinuierliche Kinematik abbildet. Aus dieser Modellierung folgt unmittelbar, dass Rampen, Unebenheiten und enge Durchfahrten nicht vorkommen. Die Ergebnisse besitzen daher nur für Umgebungen Gültigkeit, die sich hinreichend genau durch diese Abstraktion erfassen lassen.

Innerhalb einer Episode bleibt die Umgebung statisch. Hindernisse werden nicht zur Laufzeit platziert, und dynamische Objekte existieren nicht. Diese Beschränkung ergibt sich aus der Abgrenzung des Untersuchungsgegenstands. Veränderungen während des Betriebs werden folglich ausschließlich als Variation zwischen den Episoden abgebildet und niemals innerhalb einer laufenden Episode. Der Agent steht damit zu keinem Zeitpunkt vor der Aufgabe, auf eine Veränderung zu reagieren, die während der Navigation eintritt.

Der Übergang von der Simulation zu einem realen System wurde bewusst ausgeklammert. Die zugrunde liegende Physik ist deterministisch und idealisiert, denn ein fester Zeitschritt von 0,02 erzeugt vollständig reproduzierbare Abläufe, während Latenz und Schlupf nicht auftreten. Der Episoden-Reset und die KillZone besitzen kein reales Gegenstück, und die auf 40 gesetzte time-scale beschleunigt das Training in einer Weise, die sich auf einer physischen Plattform nicht nachbilden lässt. Die Trainingsbedingungen sind somit sauberer, als es ein realer Einsatz sein könnte, wodurch der Abstand zwischen den erzielten Ergebnissen und einer tatsächlichen Anwendung wächst.

Ebenso idealisiert ist die Sensorik. Die eingesetzten Rays liefern eine rauschfreie semantische Klassifikation über Tags, sodass Wahrnehmungsfehler von vornherein ausgeschlossen bleiben. Schwerer wiegt der Umstand, dass die Beobachtungen privilegierte Information enthalten. Exakte Zieldistanz, lokale Zielrichtung und Line-of-Sight stehen dem Agenten direkt zur Verfügung, und das PBRS-Shaping stützt sich zusätzlich auf die Luftlinien-Zieldistanz. Beide Elemente setzen eine globale Lokalisierung und bekannte Zielkoordinaten voraus, also Voraussetzungen, die ein reales System erst herstellen müsste. Hinzu kommt, dass einzelne Sensorkanäle ohne Funktion bleiben, weil die zugehörigen Träger zur Laufzeit fehlen. Dies betrifft die Kanäle für Obstacle und Bridge, deren Anteil am Beobachtungsraum keinen informativen Gehalt trägt.

Neben den Eigenschaften der Umgebung schränkt auch das gewählte Studiendesign die Aussagekraft ein. Ausgewertet wurde je Architektur nur ein einzelner Seed und je Budgetstufe nur ein einzelner Lauf, wobei die beiden Stufen bei 16,6 M und 30 M lagen. Die Deutungen zum Trainingsbudget und zum Overfitting lassen sich deshalb nicht gegen Stochastik absichern, weil ein einzelner Lauf den Einfluss der zufälligen Initialisierung und des zufälligen Trainingsverlaufs nicht von einem systematischen Effekt trennt.

Erschwerend fehlen ein Konvergenzkriterium und eine validierungsbasierte Auswahl der Checkpoints. Bewertet wurde jeweils der am Trainingsende vorliegende Checkpoint, wodurch der Leistungseinbruch des LSTM während des Trainings unentdeckt blieb. Eine ausgelagerte Zwischenevaluation auf einem Held-out-Datensatz hätte diesen Einbruch erkennbar gemacht, sodass ein früherer Checkpoint hätte gewählt werden können. Als weitere Grenze kommt hinzu, dass sich die Untersuchung auf einen einzelnen Agenten beschränkt.

Zusammengenommen ordnen diese Grenzen die Reichweite der Arbeit klar ein. Die gewonnenen Erkenntnisse beschreiben das Verhalten der Architekturen innerhalb einer abstrahierten, statischen und idealisierten Aufgabe und nicht die Leistung eines realen Roboters in einer veränderlichen Umgebung. Weil sich die einzelnen Vereinfachungen von der Raumdarstellung über die Physik bis zur privilegierten Wahrnehmung addieren, lässt sich das Ergebnis nicht unmittelbar auf einen physischen Einsatz übertragen, sondern zunächst nur auf Szenarien, die denselben Annahmen genügen. Auch die Aussagen zum Vergleich der Architekturen sowie zu Budget und Overfitting sind vor diesem Hintergrund als richtungsweisende Befunde innerhalb des gewählten Aufbaus zu verstehen und nicht als statistisch gesicherte Allgemeinaussage, da ihnen jeweils nur ein einzelner Lauf zugrunde liegt. Die Arbeit liefert damit aussagekräftige Hinweise auf das relative Verhalten der untersuchten Architekturen unter kontrollierten Bedingungen, während eine Übertragung auf reale, dynamische Navigation erst nach einer Erweiterung um kontinuierliche Steuerung, realistische Sensorik und eine breitere statistische Absicherung möglich wird.


// ============================================================================
// 10. FAZIT UND AUSBLICK
//KATYA ============================================================================
= Fazit und Ausblick <sec:fazit>

Mit der Evaluation der drei Architekturen ist der empirische Teil dieser Arbeit abgeschlossen. Das vorliegende Kapitel führt die Ergebnisse zusammen: Es fasst zunächst zusammen, welches System entstanden ist und wie der Vergleich durchgeführt wurde, beantwortet anschließend die in der Einleitung formulierten Forschungsfragen F1 bis F3, benennt die Grenzen der Untersuchung samt der daraus gewonnenen methodischen Erkenntnisse und schließt mit einem Ausblick auf weiterführende Arbeiten.

== Zusammenfassung

Ausgangspunkt dieser Arbeit war die Frage, welche neuronale Netzwerkarchitektur (MLP, LSTM oder Transformer) geeignet ist, einem Reinforcement-Learning-Agenten generalisierbares Navigations- und Hindernisvermeidungsverhalten in einer prozedural generierten 3D-Labyrinthwelt zu vermitteln. Zu ihrer Beantwortung wurde ein vollständiger Versuchsapparat entwickelt: eine eigene Simulationsumgebung auf Basis der Unity-Engine, gekoppelt an einen PPO-Trainingsprozess des ML-Agents-Frameworks.

Die entstandene Umgebung umfasst ein typisiertes Zellmodell mit heterogenen Gefahrenfeldern, eine prozedurale, auf garantierte Lösbarkeit geprüfte Kartengenerierung, ein achtphasiges Curriculum mit aufsteigender Schwierigkeit sowie den Multi-Area-Betrieb mit mehreren identischen Trainingsflächen je Szene. Für die Messung der Generalisierung wurde eine vollständige Evaluations-Pipeline aufgebaut, deren zurückgehaltener Kartenbestand offline erzeugt, eingefroren und dem Training zu keinem Zeitpunkt präsentiert wurde. Auf der Modellseite entstanden zwei eigene Gedächtnismodule: ein Custom-LSTM und ein Custom-Transformer, die über denselben Patch der Python-Trainingsumgebung mit identischem Schnittstellenvertrag eingebunden sind (@sec:lstm-integration, @sec:transformer-integration) und zusammen mit der nativ integrierten MLP-Baseline (@sec:mlp-integration) einen fairen Architekturvergleich ermöglichen.

Der Vergleich selbst folgte einem kontrollierten Design: Alle drei Architekturen trainierten als parallele Behaviors im selben Lauf, in identischer Umgebung, mit identischem Beobachtungs- und Aktionsraum und einer vor den Vergleichsläufen eingefrorenen Belohnungsfunktion. Die wenigen begründeten Konfigurationsabweichungen sind dokumentiert (@sec:yaml-abweichungen), ebenso die vollständige Iterationshistorie von Integration und Tuning (@sec:tuning-abweichungen, @sec:iterationen). Der finale Vergleichslauf wurde über das volle Trainingsbudget abgeschlossen und anschließend auf dem zurückgehaltenen Kartenbestand evaluiert. Die Ergebnisse dieser Messungen sind in der Evaluation dargestellt, ihre Einordnung entlang der Forschungsfragen erfolgt im folgenden Abschnitt.



// - Gebaut: 3D-Labyrinth, prozedurale Generierung, Curriculum, natives LSTM,
//   Custom-Transformer, Multi-Area, vollständige Evaluations-Pipeline

== Beantwortung der Forschungsfragen

// - F1 Mehrwert temporalen Gedächtnisses (LSTM/Transformer vs. MLP, Erfolgsrate) — Daten da, aber nicht schreibfertig. Fehlt: die Team-Entscheidung, wie mit dem v2/v3-Widerspruch umgegangen wird (in v3 lernt das MLP am besten, in v2 das LSTM). Ohne festgelegten Primärlauf keine belastbare Antwort.
// - F2 Vergleich LSTM vs. Transformer (Konvergenzgeschwindigkeit, finaler Score) // — jetzt schreibbar. Der neue Report liefert die Konvergenz (aus den Rolling-Success-Kurven) und den finalen Score (Beste Success: MLP 88,6 % > TF 79,0 % > LSTM 74,3 %). Konvergenz kannst du nur qualitativ/kurvenbasiert formulieren — ein sauberer „Steps-bis-Schwelle"-Zahlenwert fehlt, weil die Metrik-Definition in 5.5.2 noch leer ist.
// - F3 Generalisierung auf ungesehene prozedurale Maps (Overfitting-Index) — Daten da, aber nicht schreibfertig. Selber v2/v3-Vorbehalt. Die Substanz (Held-out-Zahlen, Overfitting-Index) lebt in Kapitel 8, das noch leer ist.
// - Zusätzlich, OHNE RQ-Label und OHNE Metrik: praktische Übertragbarkeit als
//   qualitative Diskussion (Rückgriff auf Kap. 9) — noch nicht. Hängt an Kapitel 9, das nur aus Überschriften besteht. Erst Kap. 9 füllen, dann hier verweisen.
Die erste Teilfrage F1 richtet sich auf den Mehrwert temporalen Gedächtnisses gegenüber der gedächtnislosen MLP-Baseline. Der Held-out-Test des Hauptlaufs ergibt hier kein einheitliches Bild. Der Transformer übertrifft das MLP auf den einfachen Karten und auf der Out-of-Distribution-Stufe Giant, bleibt auf den mittleren und schweren Karten jedoch hinter ihm zurück. Das LSTM fällt über alle Kategorien deutlich unter die Baseline. Ein durchgängiger Mehrwert temporalen Gedächtnisses lässt sich daraus nicht ableiten: Hypothese H1 wird in ihrer allgemeinen Form nicht bestätigt, allenfalls zeigt der Transformer an den Rändern des Schwierigkeitsspektrums einen selektiven Vorteil. Dieser Befund gilt zudem nur für den Hauptlauf; im Budget-Kontrast final_v2 war das LSTM die stärkste Architektur, sodass die Antwort auf F1 laufabhängig (Budget/Umgebung/Stochastik; beim Transformer zusätzlich Konfiguration) ausfällt — wobei dieser Budget-Kontrast nur quasi-kontrolliert und für den Transformer zusätzlich mit geänderten Hyperparametern konfundiert ist (@sec:bewertungsmatrix).

Die zweite Teilfrage F2 vergleicht LSTM und Transformer hinsichtlich Trainingsdynamik und Leistungsfähigkeit. Die formale Konvergenzmetrik liefert für den Vergleich von LSTM und Transformer keinen Unterschied: Beide Gedächtnisarchitekturen bleiben mit ihren Bestwerten unter der 80-%-Schwelle und sind rechtszensiert. Ihre rollierenden Erfolgsratenkurven verlaufen zudem nahezu deckungsgleich (Pearson-Korrelation r ≈ 0,91) und überschreiten das 0,7-Band beide erst spät bei etwa 21 Mio. Schritten, wo auch ein gemeinsamer Peak liegt; ein Konvergenzvorsprung einer der beiden Architekturen lässt sich daraus nicht ableiten. Deskriptiv erreicht der Transformer mit 79,0 % gegenüber 74,3 % die höhere Bestleistung. H2 wird damit in der Richtung der höheren Bestleistung gestützt, ist aber nicht formal quantifizierbar. Der finale kumulative Reward liegt mit 16,5 gegenüber 16,2 zwar praktisch gleichauf, misst jedoch eine andere Größe und stellt den Bestleistungsbefund nicht in Frage. Der praktisch entscheidende Unterschied der beiden Architekturen tritt erst auf den zurückgehaltenen Karten zutage, wo sie bei vollem Budget eine Größenordnung trennt (@tab_generalisierung_ergebnisse). In dieser Lesart stützt das Ergebnis den auf die Endleistung bezogenen Teil von H2 qualitativ, während der auf Konvergenz bezogene Teil mangels erreichter Schwelle unbeantwortet bleibt.

Die dritte Teilfrage F3 betrifft die Generalisierung auf unbekannte Kartenlayouts. Im Hauptlauf final_v3 erzielen MLP und Transformer auf den regulären Held-out-Kategorien eine vergleichbare Generalisierungsleistung, während das LSTM deutlich abfällt. H3 wird damit nicht gestützt: Für das LSTM widersprechen die Ergebnisse der Hypothese klar, während der Transformer keine konsistente Überlegenheit gegenüber der MLP-Baseline zeigt. Der Overfitting-Index (@tab:overfitting) bestätigt dieses Bild: betragsmäßig kleine, teils negative Werte für MLP und Transformer stehen stark positiven Werten von +57 bis +66 Prozentpunkten beim LSTM gegenüber.

Über die drei Teilfragen hinaus bleibt die praktische Übertragbarkeit, die gemäß der Abgrenzung (@sec:abgrenzung) bewusst ohne eigene Forschungsfrage und ohne Metrik nur qualitativ behandelt wird. Auf Grundlage der Bewertungsmatrix (@sec:bewertungsmatrix) ergibt sich für die motivierenden Szenarien folgendes Bild: Für Spiele-NPCs und Serviceroboter mit Unity- oder Embedded-Inferenz ist das MLP die ausgewogenste Wahl aus Generalisierung, Budget-Robustheit und Einsetzbarkeit. Der Transformer empfiehlt sich für Szenarien mit hoher Layout-Varianz außerhalb der Trainingsverteilung, sofern ein Python-basierter Inferenz-Stack akzeptabel ist. Das LSTM scheidet wegen seines Leistungseinbruchs bei langem Training aus.

Auf die übergeordnete Forschungsfrage folgt daraus, dass keine der drei Architekturen unter den untersuchten Bedingungen durchgängig überlegen ist. Welche Architektur geeignet ist, hängt vom Einsatzszenario und vom verfügbaren Trainingsbudget ab, unter der in @sec:bewertungsmatrix begründeten Gewichtung erweist sich die MLP-Baseline als ausgewogenste Gesamtlösung. Sämtliche Rangaussagen stehen dabei unter dem Vorbehalt einer schmalen statistischen Basis, der im folgenden Abschnitt zusammengefasst und in @sec:limitationen-uebertragbarkeit ausführlich eingeordnet wird.


== Limitationen und Lessons Learned <sec:limitationen>
// Verweis auf 9.4 (limitation übertragbarkeit) sonst übertragbarkeit nur kurz erwähnen dann verweis. - Kapitel 9 fehlt
Die Aussagekraft der vorgestellten Ergebnisse ist durch mehrere bewusste Entwurfsentscheidungen und praktische Randbedingungen begrenzt. Dieser Abschnitt benennt diese Grenzen und hält fest, welche methodischen Erkenntnisse sich aus ihnen ableiten lassen. Die Grenzen der Übertragbarkeit auf reale Servicerobotik-Szenarien werden hier nicht wiederholt, sie sind Gegenstand von @sec:limitationen-uebertragbarkeit.

Die erste Einschränkung betrifft die Vergleichslogik selbst. Die Trainer-Konfigurationen der drei Architekturen sind nicht vollständig identisch, die Abweichungen und ihre Begründungen sind in @sec:yaml-abweichungen dokumentiert und werden hier nicht wiederholt. Aus dem dort gewählten Best-vs.-Best-Prinzip folgt jedoch eine methodische Konsequenz: Der Vergleich erhebt keinen strengen Kausalanspruch. Beobachtete Leistungsunterschiede lassen sich nicht allein dem temporalen Gedächtnismechanismus zuschreiben, da mit der Architektur zugleich weitere Hyperparameter variieren. Die Ergebnisse sind daher als Vergleich praxisnah optimierter Gesamtkonfigurationen zu lesen und nicht als isolierte Wirkung des Gedächtnistyps.

Eng damit verbunden ist die statistische Basis: Sämtliche Aussagen beruhen auf einem einzigen Zufalls-Startwert und je Budgetstufe genau einem Trainingslauf. Die stochastische Varianz von Reinforcement-Learning-Training lässt sich damit nicht abschätzen, und Rangfolgen zwischen den Architekturen sind entsprechend vorsichtig als richtungsweisende Befunde zu interpretieren. Wie schwer diese Grenze wiegt, zeigt der Rangfolgenwechsel zwischen den beiden Läufen selbst, seine ausführliche Einordnung enthält @sec:limitationen-uebertragbarkeit.

Auf der technischen Ebene erwies sich die Kombination aus PPO und einem nachgerüsteten Transformer als nicht trivial. Da PPO als On-Policy-Verfahren identische Log-Wahrscheinlichkeiten aus Datensammlung und Optimierung voraussetzt, führte bereits ein struktureller Unterschied der Sequenzverarbeitung zwischen Inferenz und Training zum vollständigen Stillstand des Lernens, ohne dass eine Fehlermeldung darauf hinwies (@sec:transformer-integration). Die Lehre daraus ist übertragbar: Wer Sequenzmodelle unterhalb der offiziellen Schnittstellen eines Frameworks integriert, muss die Konsistenz beider Rechenkontexte explizit herstellen und verifizieren, beim zustandslosen Transformer etwa über den beschriebenen Rolling-Buffer und eine kausale Maske.

Beim Belohnungsdesign bestätigte sich potentialbasiertes Reward Shaping als wirksames Mittel gegen ausbleibende Lernsignale, zugleich aber als anfällig für Ausnutzung: Jedes dichte Zusatzsignal wurde früher oder später gefarmt, und der Discount-Faktor erwies sich als entscheidender Stellhebel. Ein Wert unterhalb von eins erzeugte einen Restterm, der bloßes Verweilen belohnte, während ein zu kurzer Planungshorizont den Terminalreward aus Sicht des Episodenbeginns praktisch verschwinden ließ (@sec:transformer-integration). Als tragfähig erwiesen sich die strikte Potentialform, degressiv gestaffelte Wiederholungsbelohnungen und feste Budgets je Episode.

Das Curriculum wirkte über die reine Schwierigkeitssteuerung hinaus als Diagnoseinstrument: Phasenwechsel fungierten als Stress-Test der Policies und machten Einbrüche der Erfolgsrate ebenso sichtbar wie das Risiko, Aufstiegs-Gates am Grenzwert lediglich zu durchlaufen, statt die jeweilige Phase zu beherrschen (@sec:tuning-abweichungen, @sec:iterationen). Zusammen mit den dokumentierten Reward-Pathologien unterstreicht dies, wie sensibel Reward Engineering und Curriculum-Design aufeinander abgestimmt sein müssen: Kleine Änderungen an einem der beiden Systeme verschoben wiederholt das Verhalten des jeweils anderen.

Ein inhaltlicher Befund des finalen Vergleichslaufs gehört ebenfalls zu den Grenzen der Arbeit: Keine der drei Architekturen integrierte die Sprung-Teilaufgabe erkennbar in ihre Navigationsstrategie. Über die gesamte Laufzeit wurde keine einzige Lava-Überquerung als erfolgreich gezählt, obwohl Sprungversuche stattfanden, die Karten wurden primär durch Umgehen der Gefahrenfelder gelöst. Da der Überquerungszähler zugleich als Messartefakt einzustufen ist (@sec:transformer-integration), verbindet dieser Befund zwei Lektionen: Schwer erlernbare motorische Teilfähigkeiten stellen sich auch bei großem Trainingsbudget nicht von selbst ein, und ihre Messbarkeit muss von Beginn an abgesichert sein, wenn sie später bewertet werden soll.

// - Config-Abweichungen zwischen den Architekturen: NUR VERWEIS auf
//   @sec:yaml-abweichungen (Liste lebt dort, hier nicht wiederholen) + die
//   KONSEQUENZ: Vergleich ohne strengen Kausalanspruch — Unterschiede nicht
//   allein der temporalen Architektur zuschreibbar
// - PPO + Transformer: Inference/Training-Konsistenz nicht trivial
// - PBRS nuetzlich aber farmbar, Discount-Faktor entscheidend
// - Curriculum: Phasenwechsel als Stress-Test, Reward Engineering sensibel

== Ausblick <sec:ausblick>

// - Vollständige Trainingsmatrix
// - CNN-/Multi-Sensor-Pfad (M8-M10): AUSDRÜCKLICH als zurückgestellte Erweiterung
//   benennen — ursprünglich geplanter Sensormodalitäts-Vergleich (Kamera,
//   Sensor-Fusion), bewusst verschoben, Rückverweis auf Abgrenzung 1.6
// - Dynamische Hindernisse, Multi-Agent, Sim-to-Real
Aus den Limitationen ergeben sich unmittelbar die nächsten Schritte. An erster Stelle steht eine vollständige Trainingsmatrix: Wiederholungsläufe mit mehreren Zufalls-Startwerten je Architektur würden die statistische Belastbarkeit des Vergleichs herstellen und erlauben, Rangfolgen von stochastischer Varianz zu trennen. In diesem Rahmen ließen sich auch die offenen Messpunkte schließen, etwa die Korrektur des Überquerungszählers und eine gezielte Vermittlung der Sprung-Teilaufgabe über dedizierte Trainingsphasen.

Als ausdrücklich zurückgestellte Erweiterung ist der ursprünglich erwogene Sensormodalitäts-Vergleich zu nennen. Die Beschränkung auf Ray-Wahrnehmung war eine bewusste Entscheidung (@sec:abgrenzung), um die Wirkung der temporalen Architektur von der eines visuellen Encoders zu isolieren, ein CNN-basierter Kamera-Pfad sowie die Fusion mehrerer Sensormodalitäten wurden dafür bewusst verschoben. Auf dem nun vorhandenen Versuchsapparat lässt sich dieser Vergleich unmittelbar aufsetzen, da Umgebung, Curriculum und Evaluations-Pipeline unverändert weiterverwendet werden können.

Darüber hinaus markieren die in der Abgrenzung ausgeschlossenen Themen die natürlichen Ausbaustufen der Umgebung: dynamische Hindernisse, die bewegte Objekte des Restaurantszenarios abbilden, Mehragenten-Szenarien mit Interaktion zwischen mehreren lernenden Agenten sowie der Transfer auf reale Robotersysteme (Sim-to-Real). Insbesondere Letzterer schließt den Bogen zur Ausgangsmotivation dieser Arbeit: Die hier gewonnenen Erkenntnisse darüber, welche Architektur unter kontrollierten Bedingungen generalisierbares Navigationsverhalten erlernt, bilden die Grundlage, auf der ein Einsatz autonomer Serviceroboter in realen, veränderlichen Umgebungen aufbauen kann.


// ============================================================================
// ANHANG (in appendix.typ)
// ============================================================================
// - YAML-Konfigurationen: identische Basis + je Agent MARKIERTE Abweichungen
//   (stützt 5.3.2 "Notwendige YAML-Abweichungen")
// - Vollständige Iterationstabelle V1-V22 mit TensorBoard-Belegen
//   (stützt 7.6.5)
// - Reward-Tabelle (vollständig)
// - Übersicht aller bearbeiteten Issues (#2 - #134)
// - Hardware-/Software-Stack
// - Repository-Struktur


//*TOOOOOOODOOOOOOOOOOOOOOO*:
/*
Inhaltliche Widersprüche:

- Overfitting-Index nutzt Trainings-Erfolgsrate, obwohl 5.5.1 selbst begründet,
  warum die nicht vergleichbar ist — beide Terme stattdessen im Inference-Modus
  messen (gesehene vs. ungesehene Layouts gleicher Schwierigkeit)?
- Konvergenzkriterium (80 % im Trainingsstrom) hat dasselbe Curriculum-Problem:
  misst es Konvergenz oder Curriculum-Progression? Alternative: Checkpoints
  periodisch auf fixem Eval-Set evaluieren?

Methodik / Glaubwürdigkeit:
- Pflichtumfang verspricht "mind. 1 Ablationsstudie" — wo in der Gliederung?
  Kandidat mit größtem Nutzen: MLP+Curiosity oder Transformer ohne Curiosity
  (entschärft die F1-Konfundierung).
- Konfundierung ernster nehmen: Curiosity nur bei Memory-Agenten, max_steps
  60M vs. 6.4M, Parameterbudget 1,07M vs. 82k — ist F1 so überhaupt
  beantwortbar? Reicht "kein strenger Kausalanspruch" als Antw
- Forschungslücke "bislang nicht systematisch untersucht" ist angreifbar:
  POPGym (Morad 2023), Memory Gym (Pleines 2023), Ni et al. 20
  (Cobbe 2020) prüfen und die Lücke enger fassen (Ray-basiert, Unity,
  prozedurale 3D-Labyrinthe mit Lösbarkeitsgarantie).
- Statistik: woher kommt α'=0.005 (impliziert 10 Tests — herleiten)? Was ist
  die Stichprobeneinheit (Episoden einer Policy ≠ Seeds/Läufe)
  VOR den Ergebnissen fixieren, nicht "machen wir nach dem Ergebnis".
- Nur 3 Held-out-Maps — widerspricht dem eigenen Argument aus
  beliebig viele ungesehene Layouts liefern. 30-100 pro Stufe wären fast gratis.
- H1 sagt "insbesondere in Sackgassen" — dafür bräuchte das Ev
  Stratifizierung (mit/ohne Sackgassen). Aufnehmen oder Halbsatz streichen?
- Restaurant-Anker: offene Fläche mit Tischen vs. unser Proble
  (Korridore, Sackgassen). Breiter rahmen (Indoor-Navigation, Restaurant als
  Beispiel) oder Diskrepanz in 1.2 aktiv adressieren?
- [ERLEDIGT 2026-07-10] Terminologie: "gedächtnislos" ist jetzt in 1.2 definiert
  ("ohne explizites temporales Gedächtnis jenseits des Zwei-Frame-Stackings")
  und wird konsistent in diesem Sinn verwendet.

Struktur / Form:

- [TEILWEISE ERLEDIGT 2026-07-10] Hartkodierte Querverweise: Fließtext nutzt
  jetzt Typst-Labels (@sec:sensorik, @sec:evalprotokoll, @sec:yaml-abweichungen,
  @sec:transformer-integration, @sec:iterationen, @sec:limitationen,
  @sec:ausblick, @sec:fazit, @sec:architekturvergleiche, @sec:generalisierung),
  §-Verweise in Gliederungs-KOMMENTAREN beim Ausformulieren ebenfalls auf
  Labels umstellen.
- "Aufbau der Arbeit" ist nicht optional.

- Belege nachziehen: Dijkstra (nackte URL im Text), Kaelbling 1998 (kein Bib-Key).
- Titelei: Titel-Platzhalter, supervisor leer, eine Matrikelnu

  */



