#import "dhbw.typ": *
#import "appendix.typ": appendix
#import "abstract.typ": abstract
#import "acronyms.typ": acronyms

#show: dhbw.with(
  title: "Studienarbeit",
  authors: (
    (name: "Finn Ludwig, Ekaterina Karavaeva, David Pelcz, Alexander Bernecker", student-id: "1437019", course: "TIT23", course-of-studies: "Informationstechnik"),
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
  supervisor: "",
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
= Einleitung
// >>> AUFTEILUNG DIESES KAPITELS (ALT -> NEU):
//     "Motivation und Kontext"           -> SPLIT: 1.1 Restaurant | 1.2 Abstraktion(+Analogie) | 1.3 Generalisierung | 1.5 Forschungsluecke
//     "Problemstellung/Forschungsfrage"  -> 1.5
//     "Zielsetzung und Abgrenzung"       -> 1.6
//     "Aufbau der Arbeit"                -> 1.7
//     (NEU 1.4 Messbarkeit ist NEU zu schreiben — kein alter Text vorhanden)

== Motivation und Kontext

// - Einsatz von KI/RL in Navigationsaufgaben (Serviceroboter, Logistik,
//   autonome Lager- und Indoor-Navigation, Spiele-/Simulations-NPCs)
// - Warum 3D-Labyrinth als kontrollierte Abstraktion realer Navigationsprobleme
//   (Tabelle: Korridore ↔ Gänge, Lava ↔ Stufen/Kabel, prozedural ↔ veränderliches Layout)
// - Forschungslücke: Generalisierung über prozedurale Layouts; Architekturvergleich
//   Transformer vs. LSTM in RL-Navigation
Autonome Navigation gehört zu den zentralen offenen Problemen der Robotik und der Künstlichen Intelligenz. Die Fähigkeit eines Agenten, sich selbstständig in einer unbekannten oder veränderlichen Umgebung von einem Startpunkt zu einem Ziel zu bewegen, ist Grundvoraussetzung für viele reale Anwendungsfälle, wie beispielsweise Serviceroboter in Restaurants, autonome Logistikfahrzeuge in Lagergebäuden oder Suchdrohnen in Katastrophengebieten @thrun_probabilistic_2002. In all diesen Szenarien gilt die gleiche Anforderung, dass der Agent zuverlässig navigieren muss, auch wenn ihm keine vollständige Karte seiner Umgebung vorliegt.

Klassische Pfadfindungsalgorithmen wie $A*$ @hart_formal_1968 oder Dijkstras Algorithmus  (Dijkstra, 1959 https://ir.cwi.nl/pub/9256/9256D.pdf) lösen das Navigationsproblem, indem Sie den kürzesten Pfad zwischen zwei Punkten in einem Graphen finden. Ihre
Grundvoraussetzung ist jedoch, dass der gesamte Umgebungsgraph bekannt und statisch ist. Sobald diese Annahme verletzt wird, weil die Karte nur teilweise bekannt ist oder sich Hindernisse verändern, versagen diese Verfahren und erfordern aufwändige Erweiterungen wie dynamisches Replanning $D*$, @stentz_optimal_1994. Darüber hinaus setzen sie eine exakte Lokalisierung des Agenten innerhalb der Karte voraus, die in realen Systemen ebenfalls mit Unsicherheit behaftet ist.

Reinforcement Learning (RL) bietet einen grundsätzlich anderen Ansatz: Anstatt einen optimalen Pfad auf einer vollständigen Karte zu berechnen, erlernt ein RL-Agent durch wiederholte Interaktion mit seiner Umgebung eine Verhaltensstrategie (Policy), die Beobachtungen auf Aktionen abbildet. Wissen über die Karte ist dabei nicht Voraussetzung, sondern das Resultat des Lernprozesses. Der Agent entwickelt implizit Navigationsstrategien, die auf seine Sensorinformationen zurückgreifen. Mit tiefen neuronalen Netzen als Funktionsapproximatoren (Deep RL) sind in den letzten Jahren bemerkenswerte Ergebnisse in komplexen Navigationsaufgaben erzielt worden @mnih_human-level_nodate. Reinforcement Learning stellt einen vielversprechender Ansatz zur Lösung des autonomen Navigationsproblemes dar.
Die vorliegende Arbeit untersucht, welche neuronale Netzwerkarchitektur einem RL-Agenten besonders geeignet ist, um in einer prozedural generierten 3D-Labyrinthwelt zuverlässig von einem Startpunkt zu einem Ziel zu navigieren. Als Lernverfahren wird Proximal Policy Optimization @schulman_proximal_2017  eingesetzt, das sich als stabiler Standard für diskrete Aktionsräume in simulierten Umgebungen etabliert hat. Die Umgebung wird in Unity 2021.3 mithilfe des ML-Agents-Frameworks realisiert.
== Problemstellung

// - Hauptforschungsfrage:
//   "Kann ein Transformer-basierter RL-Agent in einer selbst gebauten 3D-Labyrinthwelt weiter unten, darunter bitte
//    generalisierbares Navigations- und Hindernisvermeidungsverhalten erlernen,
//    das sich auf unbekannte Map-Layouts übertragen lässt?"
// - Erweiterte Forschungsfragen (aus Forschungsplan_M6_M11):
//   RQ1 Sensortyp · RQ2 Temporal-Architektur · RQ3 Sensor-Fusion · RQ4 Real-World-Transfer
// - Hypothesen H1–H4
Das in dieser Arbeit betrachtete Navigationsproblem weist zwei Eigenschaften auf, die es von den Annahmen klassischer Pfadfindungsalgorithmen grundlegend unterscheiden.
Zum einen die partielle Observierbarkeit. Der Agent nimmt seine Umgebung ausschließlich über einen Ray-Perception-Sensor wahr: elf Lichtstrahlen, die in einem Winkel von 120° ausgesandt werden und beim Auftreffen auf erkannte Objekte (Wände, Lava, Löcher, Ziel) deren Typ und Entfernung zurückliefern. Ergänzt wird diese Information durch einen 13-dimensionalen Handcoded-Vektor (Eigengeschwindigkeit,Bodentyp unter dem Agenten, normalisierte Richtung zum Ziel). Der Agent besitzt zu keinem Zeitpunkt eine globale Karte seiner Umgebung. Das Navigationsproblem ist damit formal ein Partially Observable Markov Decision Process  (POMDP, Kaelbling et al., 1998 ): Der aktuelle Beobachtungsvektor allein identifiziert den Zustand der Welt nicht eindeutig.

Die zweite Eigenschaft sind Sackgassen und das Gedächtnisproblem. Partielle Observierbarkeit wird kritisch, wenn der Agent in eine Sackgasse gerät.
Ohne Erinnerung daran, welche Richtungen er bereits erfolglos versucht hat, verhält sich ein gedächtnisloser Agent in einer Sackgasse reaktiv: Er nimmt in jedem Timestep dieselben Ray-Werte wahr und trifft dieselbe Entscheidung(er dreht sich im Kreis oder wechselt zwischen zwei Positionen). Die Beobachtung „Wand links, Wand rechts, Wand vorne" ist ohne temporalen Kontext nicht von der Situation „Wand links, Wand rechts, Wand vorne, und ich bin gerade von hinten hereingekommen" zu unterscheiden. Ein Multilayer Perceptron (MLP), das jeden Timestep unabhängig verarbeitet, ist strukturell außerstande, diese Unterscheidung zutreffen.
Dieser Sachverhalt wirft die Frage der Arbeit auf: Benötigt der Agent ein explizites temporales Gedächtnis, um in partiell observierbaren Labyrinth erfolgreich zu navigieren? Zwei Architekturklassen bieten unterschiedliche Antworten darauf. Long Short-Term Memory-Netze (LSTM, Hochreiter & Schmidhuber, 1997) komprimieren vergangene Beobachtungen in einen kontinuierlichen Hidden State, der von Timestep zu Timestep weitergegeben wird(ein implizites Gedächtnis). Transformer-Encoder (Vaswani et al.,2017) hingegen verarbeiten eine explizite Sequenz der letzten $N$ Beobachtungen und können über Self-Attention-Mechanismen gezielt auf relevante vergangene Zustände zurückgreifen(ein explizites, aber fensterbegrenztes Gedächtnis).
Ob und in welchem Ausmaß diese Architekturklassen die Navigationsleistung gegenüber einem gedächtnislosen MLP verbessern, und welche der beiden Gedächtnisarchitekturen überlegen ist, ist bislang für Ray-basierte RL-Navigation in prozedural generierten Umgebungen nicht systematisch untersucht worden.


*
Ausgangspunkt: In einem Restaurant sollen KI-gesteuerte Serviceroboter autonom navigieren.
Um zu prüfen, ob das funktioniert, muss die reale Umgebung in eine vergleichbare, abstrahierte Welt übersetzt werden — testbar, ohne physischen Roboter.
Da jedes Restaurant anders aussieht, muss der Agent generalisieren; das ist die zentrale Anforderung, nicht bloß Auswendiglernen eines Grundrisses.
Generalisierung ist aber nur nachweisbar, wenn auf Layouts getestet wird, die im Training nie vorkamen — das setzt systematisch erzeugbare Layouts (prozedurale Map-Generierung) und ein zurückgehaltenes, ungesehenes Test-Set voraus. Map-Generierung ist damit nicht Feature, sondern Bedingung der Messbarkeit.
Offen ist zunächst, wie sich KI-Agenten überhaupt in einer 3D-Welt implementieren lassen und welche Herausforderungen die gewählte Game-Engine dabei mit sich bringt.
Als Eingabe des Agenten muss entschieden werden, welche Sensorik die reale Wahrnehmung angemessen abbildet und wie sie in der Engine während des Trainings umgesetzt wird — hier ist zu begründen, warum Ray-basierte Wahrnehmung gewählt wurde.
Die Kern-Herausforderung ist die Verarbeitung: Wie „funktioniert" der Agent, d. h. wie verarbeitet er diese Informationen zu Entscheidungen?
Konkret zugespitzt an Sackgassen: Ein gedächtnisloser Agent kann nicht wissen, aus welcher Richtung er gekommen ist, und läuft reaktiv gegen die nächste Wand.
Als Antwort kommen zwei Architekturklassen in Frage — LSTM und Transformer —; welche die bessere ist, ist ein eigenes, offenes Problem.
*

- Alle Probleme adressieren
- Problem in 3D übersetzten (Game Engine)
- Erläutern wie Maps umgesetzt werden sollen
- Generalisierbarkeit umsetzten
- Map Generierung als Basis der Generealisierbarkeit
- Evaluierung der Generlarisierbarkeit
- Sicherstellen das es vergleichbar bleibt (maps)
- Sensoren abwägen
- Vergleich von verschiedenen Architekturen (LSTM, MLP, Transformer) welches funktioniert für diesen Anwendungsfall am besten

== Forschungsfrage
Aus der beschriebenen Problemstellung leiten sich drei Forschungsfragen ab, die in dieser Arbeit empirisch beantwortet werden:

F1: Mehrwert temporalen Gedächtnisses:

"Verbessert zeitliches Gedächtnis (LSTM bzw. Transformer) die Erfolgsrate eines RL-Agenten in partiell observierbaren Labyrinthwelten gegenüber einem gedächtnislosen MLP-Basisagenten?"

Diese Frage prüft die grundlegende Hypothese, dass temporale Kontextinformation für die betrachtete Aufgabe notwendig oder zumindest deutlich vorteilhaft ist. Gemessen wird die Erfolgsrate (Anteil erfolgreich abgeschlossener Episoden) über die letzten 100 Trainings-Episoden nach Trainingsabschluss.

F2: Vergleich LSTM und Transformer:
"Unterscheiden sich LSTM und Transformer in ihrer Konvergenzgeschwindigkeit und ihrem finalen Leistungsscore bei Ray-basierter Labyrinth-Navigation?"

Diese Frage zielt auf die praktische Wahl zwischen den beiden Gedächtnisarchitekturen. Konvergenzgeschwindigkeit wird operationalisiert als die Anzahl Trainingsschritte bis zum erstmaligen Erreichen einer Erfolgsrate von 80 %. Der finale Score entspricht dem mittleren kumulativen Episoden-Reward in den letzten 100 Trainings-Episoden.

F3: Generalisierung auf unbekannte Maps:
"Welche der drei Architekturen (MLP, LSTM, Transformer) generalisiert am zuverlässigsten auf prozedural generierte Maps, die während des Trainings nie gesehen wurden?"

Generalisierung wird auf drei fixierten Evaluation-Maps gemessen, die vor Trainingsbeginn eingefroren und während des gesamten Trainings nicht verwendet wurden. Die Differenz zwischen Trainings- und Generalisierungs-Erfolgsrate dient als Overfitting-Index.

Die drei Forschungsfragen sind bewusst aufeinander aufbauend: F1 klärt, ob Gedächtnis prinzipiell nützt; F2 differenziert zwischen den Gedächtnistypen; F3 bewertet die praktische Robustheit der besten Konfiguration.
== Ziel der Arbeit    //Finn
- Alle Probleme adressieren
- Problem in 3D übersetzten (Game Engine)
- Erläutern wie Maps umgesetzt werden sollen
- Generalisierbarkeit umsetzten
- Map Generierung als Basis der Generealisierbarkeit
- Evaluierung der Generlarisierbarkeit
- Sicherstellen das es vergleichbar bleibt (maps)
- Sensoren abwägen
- Vergleich von verschiedenen Architekturen (LSTM, MLP, Transformer) welches funktioniert für diesen Anwendungsfall am besten

== Abgrenzung

// - Pflichtumfang (Scope): 3D-Labyrinth, 5 Maps, Ray-Sensorik, Lava/Hole/Sackgassen,
//   Transformer als Kernmodell, MLP-Baseline, mind. 1 Ablationsstudie,
//   Generalisierungstest, reproduzierbares Repo, Bericht + Video-Demos
// - Optionale Erweiterungen (umgesetzt): prozedurale Map-Generierung, Curriculum Learning,
//   LSTM-Vergleich, Multi-Area-Training
// - Was diese Arbeit NICHT leistet: Sim-to-Real Transfer, Multi-Agent-Setup, dynamische Hindernisse
Um die Vergleichbarkeit der Ergebnisse zu gewährleisten und den experimentellen Aufwand auf die Kernfragen zu fokussieren, werden folgende Einschränkungen bewusst getroffen:
Sensorik: Ausschließlich Ray-basierte Wahrnehmung. Der Agent verwendet den RayPerceptionSensor3D von Unity ML-Agents in Kombination mit einem manuell kodieren VectorSensor. Kamerabasierte Beobachtungen (Pixel-Tensoren) und Multi-Sensor-Konfigurationen werden in dieser Arbeit nicht untersucht. Diese Einschränkung hat zwei Gründe: Erstens erlaubt die niedrigdimensionale Ray-Repräsentation (Float-Vektoren statt Pixel-Arrays) deutlich kürzere Trainingszeiten und damit eine höhere Anzahl vollständiger Experiment-Wiederholungen. Zweitens isoliert sie die Wirkung der temporalen Architektur von der Wirkung des visuellen Encoders, denn bei Kamera-Agenten wäre unklar, ob beobachtete Unterschiede aus dem Temporal-Modul oder aus dem CNN-Modul stammen.

 Als Trainingsalgorithmus wird Proximal Policy Optimization (PPO) verwendet. Alternative Verfahren wie Deep Q-Networks @mnih_human-level_nodate oder Soft Actor-Critic @haarnoja_soft_2018 werden nicht betrachtet. PPO bietet nativen Support für LSTM- und Transformer-Architekturen im Unity ML-Agents Framework und ist als On-Policy-Verfahren mit diskreten Aktionsräumen besonders gut geeignet. DQN ist primär für Value-Based Learning ohne explizite Policy-Parametrisierung ausgelegt. SAC ist für kontinuierliche Aktionsräume optimiert.

Umgebung: Keine dynamischen Hindernisse. Das Labyrinth enthält ausschließlich statische Hindernisse: Wände, Lavafelder und Bodenlöcher, deren Position pro Episode zufällig neu platziert, aber während einer Episode nicht verändert wird. Bewegliche Hindernisse (rotierende Stacheln, patroullierende Gegner) würden die Komplexität der Aufgabe erheblich erhöhen und die Interpretation der Ergebnisse erschweren. Sie bleiben einer möglichen Weiterentwicklung vorbehalten.

Diese Einschränkungen sind keine Schwäche, sondern methodische Stärke des Designs: Durch die Kontrolle von Sensormodalität und Lernverfahren können beobachtete Leistungsunterschiede kausal der temporalen Architektur zugeschrieben werden.
== Aufbau der Arbeit //Optional (Arbeitspakete?)

// - Kurze Übersicht der Kapitel


// ============================================================================
// 2. THEORETISCHE GRUNDLAGEN
// ============================================================================
= Theoretische Grundlagen  //David
// >>> BLEIBT KAPITEL 2 — nur Reihenfolge/Rahmung geaendert (ALT -> NEU):
//     "Maschinelles Lernen und RL"       -> 2.1
//     "Proximal Policy Optimization"     -> 2.2
//     "Wahrnehmung in RL-Agenten"        -> 2.3  (VORGEZOGEN, vor Sequenzmodellierung)
//     "Sequenzmodellierung fuer RL"      -> 2.4  (LSTM -> 2.4.2, Transformer -> 2.4.3)
//     "Unity ML-Agents Toolkit"          -> 2.5
//     (NEU 2.4.1 Gedaechtnisproblem: NEU/kurz; Motivation auch in 1.5)

== Künstliche Intelligenz
Künstliche Intelligenz (KI) bezeichnet den Bereich der Informatik, der sich mit der Entwicklung maschinenbasierter Systeme befasst, die Aufgaben ausführen können, die  menschliche Intelligenz erfordern, wie beispielsweise Problemlösung, Sprachverständnis oder Mustererkennung @bhagwan_comprehensive_2024
== Maschinelles Lernen und wichtige Methoden
Maschinelles Lernen (ML) ist ein Teilgebiet der KI und befasst sich mit der Entwicklung von Algorithmen, die aus Daten lernen und auf Grundlage dieser Daten Vorhersagen treffen @bhagwan_comprehensive_2024. Dabei müssen keine Entscheidungsregeln explizit programmiert werden, da diese während des Trainingsprozesses aus den vorhandenen Daten abgeleitet werden. Abhängig davon, welche Art von Daten dem Modell zur Verfügung stehen und wie der Lernprozess organisiert ist, lassen sich verschiedene Lernparadigmen unterscheiden. Zu den grundlegenden Ansätzen zählen Supervised Learning (überwachtes Lernen), Unsupervised Learning (unüberwachtes Lernen) und Reinforcement Learning (bestärkendes Lernen) @shaveta_review_2023.
=== Supervised Learning(überwachtes Lernen)
Beim überwachten Lernen (Supervised Learning) wird ein Modell anhand von annotierten Trainingsdaten trainiert. Jeder Eingabe ​$x_i$ ist dabei ein bekanntes Ziel $y_i$ zugeordnet. Das Ziel des Lernprozesses besteht darin, eine Funktion $f: X -> Y$ zu erlernen, die für neue, unbekannte Eingaben möglichst korrekte Vorhersagen liefert. Typische Anwendungsgebiete sind die Klassifikation, bei der Daten vordefinierten Klassen zugeordnet werden, sowie die Regression, bei der kontinuierliche Werte vorhergesagt werden (@shaveta_review_2023 S.282) . Der Lernfortschritt wird durch den Vergleich der Modellausgabe mit den bekannten Zielwerten bewertet und über geeignete Optimierungsverfahren verbessert.
=== Unsupervised Learning (unüberwachtes Lernen)
Im Gegensatz dazu stehen beim unüberwachten Lernen (Unsupervised Learning) keine Zielwerte oder Labels zur Verfügung. Das Modell erhält ausschließlich die Eingabedaten und versucht selbstständig, darin enthaltene Strukturen, Zusammenhänge oder Muster zu identifizieren. Häufige Verfahren sind das Clustering, bei dem ähnliche Datenpunkte zu Gruppen zusammengefasst werden, sowie die Dimensionsreduktion, die darauf abzielt, die wesentlichen Informationen eines Datensatzes in einer kompakteren Darstellung abzubilden. Unüberwachtes Lernen eignet sich insbesondere zur explorativen Datenanalyse und zur Entdeckung bisher unbekannter Strukturen.
=== Reinforcement Learning (bestärkendes Lernen)
Das für diese Arbeit
zentral relevante Verfahren ist das bestärkende Lernen (Reinforcement Learning, RL). Dieses verfolgt einen anderen Ansatz. Hier interagiert ein Agent fortlaufend mit einer Umgebung und trifft Entscheidungen in Form von Aktionen. Für diese Aktionen erhält er ein Feedback in Form eines sogenannten Reward-Signals. Anders als beim überwachten Lernen werden dem Agenten keine direkten Korrekturen für einzelne Entscheidungen gegeben. Stattdessen muss er durch Versuch und Irrtum selbst erlernen, welche Handlungsstrategien langfristig zu einem möglichst hohen kumulativen Reward führen @sutton_reinforcement_2018. Aufgrund dieses Ansatzes eignet sich Reinforcement Learning besonders für komplexe Entscheidungsprobleme mit zeitlicher Abhängigkeit, beispielsweise in der Robotik, Navigation oder bei der Entwicklung von Spielstrategien.
Eine besondere Herausforderung im bestärkenden Lernen stellt das sogenannte Exploration-Exploitation-Dilemma dar. Der Agent muss kontinuierlich abwägen, ob er bereits bekannte und erfolgversprechende Aktionen ausführt (Exploitation) oder neue, bislang wenig erforschte Aktionen ausprobiert (Exploration), die langfristig zu einer höheren Belohnung führen könnten @sutton_reinforcement_2018. Die Balance zwischen diesen beiden Strategien ist ein zentraler Aspekt vieler Reinforcement-Learning-Verfahren und hat entscheidenden Einfluss auf deren Leistungsfähigkeit.
=== Markov-Entscheidungsprozess

Der theoretische Rahmen des bestärkenden Lernens wird durch den Markov-Entscheidungsprozess (Markov Decision Process, MDP) beschrieben. Ein MDP modelliert die Interaktion eines Agenten mit seiner Umgebung und bildet damit eine zentrale Grundlage vieler Reinforcement-Learning-Verfahren. Dabei befindet sich der Agent zu einem Zeitpunkt in einem Zustand, wählt eine Aktion aus, erhält anschließend eine Belohnung und gelangt in einen Folgezustand @sutton_reinforcement_2018.

Ein MDP umfasst dabei insbesondere einen Zustandsraum $S$, einen Aktionsraum $A$, Übergangswahrscheinlichkeiten, eine Rewardfunktion sowie einen Diskontierungsfaktor $gamma$. Der Zustandsraum $S$ enthält die möglichen Zustände der Umgebung. Der Aktionsraum $A$ beschreibt die Aktionen, die dem Agenten zur Verfügung stehen. Die Übergangswahrscheinlichkeit $p(s' | s,a)$ gibt an, mit welcher Wahrscheinlichkeit der Agent nach Ausführung der Aktion $a$ im Zustand $s$ in den Folgezustand $s'$ übergeht.

Die Rewardfunktion beschreibt die unmittelbare Rückmeldung, die der Agent nach einer Zustandsänderung erhält. In dieser Arbeit wird sie als erwartete unmittelbare Belohnung eines Übergangs verstanden. Sie kann daher abhängig vom aktuellen Zustand $s$, der ausgeführten Aktion $a$ und dem Folgezustand $s'$ betrachtet werden. Der Diskontierungsfaktor $gamma$ bestimmt, wie stark zukünftige Belohnungen gegenüber unmittelbar erhaltenen Belohnungen gewichtet werden. Werte nahe 0 führen dazu, dass kurzfristige Belohnungen stärker berücksichtigt werden, während Werte nahe 1 langfristige Strategien begünstigen.

Eine zentrale Annahme des MDP ist die Markov-Eigenschaft. Sie besagt, dass die zukünftige Entwicklung des Systems durch den aktuellen Zustand und die gewählte Aktion hinreichend beschrieben wird. Frühere Zustände und Aktionen liefern keine zusätzlichen Informationen, sofern der aktuelle Zustand alle für die Zukunft relevanten Informationen enthält. Durch diese Annahme lassen sich sequenzielle Entscheidungsprobleme strukturiert modellieren und für Reinforcement-Learning-Verfahren nutzbar machen @sutton_reinforcement_2018.

=== Policy und Value-Funktionen

Das zentrale Ziel eines Reinforcement-Learning-Agenten besteht darin, eine möglichst gute Policy zu erlernen. Eine Policy beschreibt das Verhalten des Agenten, indem sie festlegt, welche Aktion in einem bestimmten Zustand ausgewählt wird. Bei einer stochastischen Policy gibt $pi(a | s)$ die Wahrscheinlichkeit an, im Zustand $s$ die Aktion $a$ auszuwählen @sutton_reinforcement_2018. 
Ziel des Lernprozesses ist es, eine Policy zu finden, die über die Zeit einen möglichst hohen erwarteten Return erzielt. Der Return $G_t$ beschreibt die diskontierte Summe der zukünftigen Rewards, die ein Agent nach dem Zeitpunkt $t$ erhält. Formal ergibt sich der diskontierte Return zu:


$G_t = sum_(k=0)^infinity gamma^k R_(t+k+1)$


Dabei bezeichnet $R_(t+k+1)$ den Reward zu einem zukünftigen Zeitpunkt und $gamma$ den Diskontierungsfaktor. Durch die Diskontierung haben unmittelbar eintretende Rewards einen stärkeren Einfluss auf den Return als weiter in der Zukunft liegende Rewards. Der Agent wird dadurch dazu angehalten, nicht nur kurzfristige Belohnungen, sondern auch langfristige Konsequenzen seiner Handlungen zu berücksichtigen @sutton_reinforcement_2018.

Um Zustände und Aktionen hinsichtlich ihres erwarteten langfristigen Nutzens bewerten zu können, werden im Reinforcement Learning sogenannte Value-Funktionen verwendet. Die State-Value-Funktion $v_pi (s)$ beschreibt den erwarteten Return, den ein Agent erzielt, wenn er sich im Zustand $s$ befindet und anschließend der Policy $pi$ folgt:

$v_pi (s) = EE_pi [G_t | S_t = s]$
Die State-Value-Funktion bewertet somit Zustände. Sie gibt an, wie vorteilhaft es langfristig ist, sich unter einer bestimmten Policy in einem bestimmten Zustand zu befinden.

Neben der Bewertung von Zuständen ist häufig auch die Bewertung konkreter Aktionen relevant. Die Action-Value-Funktion $q_pi(s,a)$ beschreibt den erwarteten Return, wenn der Agent im Zustand $s$ zunächst die Aktion $a$ ausführt und anschließend der Policy $pi$ folgt:

$q_pi (s, a) = EE_pi [G_t | S_t = s, A_t = a]$

Damit erlaubt die Action-Value-Funktion eine detailliertere Bewertung möglicher Handlungsalternativen. Sie ist insbesondere für Verfahren relevant, bei denen Aktionen anhand ihres erwarteten langfristigen Nutzens verglichen werden, beispielsweise bei Q-Learning oder Deep Q-Networks. In solchen Verfahren werden Action-Value-Funktionen genutzt oder approximiert, um in einem Zustand geeignete Aktionen auszuwählen @sutton_reinforcement_2018.
=== On-Policy und Off-Policy

Reinforcement-Learning-Verfahren lassen sich unter anderem danach unterscheiden, ob sie on-policy oder off-policy lernen. Bei On-Policy-Verfahren wird die Policy verbessert, die auch zur Erzeugung der Trainingsdaten verwendet wird. Der Agent lernt somit aus Erfahrungen, die mit seiner aktuellen oder nur leicht veränderten Policy gesammelt wurden. Ein klassisches Beispiel für ein On-Policy-Verfahren ist Sarsa @sutton_reinforcement_2018.

Bei Off-Policy-Verfahren wird hingegen zwischen einer Ziel-Policy und einer Verhaltens-Policy unterschieden. Die Verhaltens-Policy erzeugt die Trainingsdaten, während die Ziel-Policy gelernt oder verbessert wird. Dadurch können Off-Policy-Verfahren auch aus Erfahrungen lernen, die nicht direkt durch die aktuell zu optimierende Policy erzeugt wurden. Ein klassisches Beispiel hierfür ist Q-Learning @sutton_reinforcement_2018.

Für diese Arbeit ist die Unterscheidung relevant, da Proximal Policy Optimization (PPO) zu den On-Policy-Verfahren zählt. Die Trainingsdaten werden daher mit der aktuellen Policy des Agenten gesammelt und anschließend zur schrittweisen Verbesserung dieser Policy genutzt.

// - Einordnung: KI ⊃ ML ⊃ RL
// - Abgrenzung supervised / unsupervised / reinforcement learning
// - Markov-Entscheidungsprozesse (MDP): Zustände, Aktionen, Übergänge, Reward,
//   Discount-Faktor γ
// - Policy, Value-Function, Q-Function
// - On-Policy vs. Off-Policy

== Proximal Policy Optimization (PPO)
Proximal Policy Optimization (PPO) ist ein Policy-Gradient-Verfahren, das zwischen der Datenerhebung durch Interaktion mit der Umgebung und der Optimierung einer sogenannten Surrogate-Zielfunktion wechselt. Im Gegensatz zu einfachen Policy-Gradient-Verfahren erlaubt PPO mehrere Optimierungsschritte auf denselben gesammelten Rollout-Daten, ohne dass die Policy dabei zu stark verändert werden soll [@schulman_proximal_2017;S.1].
=== Actor-Critic-Framework
PPO wird in der Praxis häufig im Actor-Critic-Framework eingesetzt. Dabei übernimmt der Actor die Repräsentation der Policy $pi_theta (a | s)$ und bestimmt, mit welcher Wahrscheinlichkeit eine Aktion $a$ in einem Zustand $s$ ausgewählt wird. Der Critic schätzt den langfristigen Nutzen eines Zustands über eine Value-Funktion und dient damit als Bewertungsinstanz für die vom Actor gewählten Aktionen.
Ein zentrales Konzept hierbei ist der Advantage. Der Advantage beschreibt, ob eine ausgeführte Aktion besser oder schlechter war als vom Critic erwartet. Ist der Advantage positiv, spricht dies dafür, dass die gewählte Aktion in einer vergleichbaren Situation wahrscheinlicher werden sollte. Ist der Advantage negativ, sollte ihre Wahrscheinlichkeit entsprechend reduziert werden. Durch diese Trennung zwischen Actor und Critic kann die Varianz der Policy-Gradient-Schätzung reduziert und das Training stabilisiert werden @sutton_reinforcement_2018.
=== Clipped Surrogate Objective
Das zentrale Problem klassischer Policy-Gradient-Methoden besteht darin, dass zu große Aktualisierungsschritte die Policy stark verschlechtern können. PPO adressiert dieses Problem durch ein Clipping-Verfahren, das die Wirkung zu großer Änderungen im Policy-Update begrenzt [@schulman_proximal_2017;S.3f].
Dazu wird zunächst das Wahrscheinlichkeitsverhältnis zwischen neuer und alter Policy für die tatsächlich ausgeführte Aktion definiert:
$ r_t (theta) = frac(pi_theta (a_t | s_t), pi_(theta_"old")(a_t | s_t)) $

Dieses Verhältnis beschreibt, wie stark sich die Wahrscheinlichkeit der gewählten Aktion unter der neuen Policy im Vergleich zur alten Policy verändert hat. Ein Wert von $r_t (theta) = 1$ bedeutet, dass beide Policies die Aktion gleich wahrscheinlich bewerten. Werte größer als 1 bedeuten, dass die neue Policy die Aktion wahrscheinlicher macht; Werte kleiner als 1 bedeuten, dass sie die Aktion weniger wahrscheinlich macht.Die zentrale PPO-Zielfunktion mit Clipping lautet:
$ L^"CLIP" (theta) = EE_t [  min(    r_t (theta) hat(A)_t,    op("clip")(r_t (theta), 1 - epsilon, 1 + epsilon) hat(A)_t  )] $
Dabei bezeichnet $hat(A)_t$ den geschätzten Advantage zum Zeitpunkt $t$. Der erste Term entspricht dem ungeclippten Policy-Gradient-Ziel. Der zweite Term begrenzt das Wahrscheinlichkeitsverhältnis auf den Bereich $[1 - epsilon, 1 + epsilon]$. Durch den Minimum-Operator wird verhindert, dass Änderungen der Policy, die zu einer zu starken Verbesserung des Zielfunktionswertes führen würden, unbeschränkt ausgenutzt werden. Dadurch wirkt PPO großen und potenziell destruktiven Policy-Updates entgegen [@schulman_proximal_2017;S.3f]. Ein häufig verwendeter Wert ist $epsilon = 0.2$. Dies bedeutet jedoch nicht, dass sich die gesamte Policy maximal um 20 % ändern darf. Korrekt ist, dass das Wahrscheinlichkeitsverhältnis im geclippten Term auf den Bereich $[0.8, 1.2]$ begrenzt wird [@schulman_proximal_2017;S.3f].

=== Generalized Advantage Estimation (GAE)
Für die praktische Schätzung des Advantage wird in PPO häufig Generalized Advantage Estimation (GAE) verwendet. GAE kombiniert Informationen aus mehreren Zeitschritten und steuert über den Parameter $lambda$ den Trade-off zwischen Bias und Varianz der Advantage-Schätzung. Kleine Werte von $lambda$ reduzieren typischerweise die Varianz, können aber stärkeren Bias verursachen. Große Werte verringern den Bias, erhöhen jedoch meist die Varianz. In vielen PPO-Konfigurationen wird $lambda = 0.95$ verwendet [@schulman_high-dimensional_2018;S.1f] [@schulman_proximal_2017;S.10].


=== Trainingszyklus und Hyperparameter

Ein PPO-Trainingszyklus besteht typischerweise aus mehreren Schritten. Zunächst sammelt der Agent mit seiner aktuellen Policy Rollouts in der Umgebung. Anschließend werden Advantage-Schätzungen berechnet. Danach wird die Policy über mehrere Epochen mit Minibatches der gesammelten Daten aktualisiert. Nach Abschluss der Optimierung wird die aktualisierte Policy zur neuen alten Policy für die nächste Datensammlung [@schulman_proximal_2017;S.4f].

Für diese Arbeit ist PPO besonders geeignet, da es als On-Policy-Verfahren gut zu kontrollierten Simulationsumgebungen passt und im Unity ML-Agents Framework als etablierter Trainingsalgorithmus verfügbar ist. Gegenüber DQN, das wertbasiert und off-policy arbeitet, sowie SAC, das insbesondere für kontinuierliche Aktionsräume verbreitet ist, stellt PPO für die untersuchte Navigationsaufgabe eine robuste und praktikable Wahl dar.

// - Actor-Critic-Framework: Policy-Netz (Actor) + Value-Netz (Critic)
// - Schulman et al. (2017): Clipping-Mechanismus (ε = 0.2)
// - GAE (Generalized Advantage Estimation): λ = 0.95
// - Vorteil gegenüber Vanilla Policy Gradient (Stabilität)
// - Quelle: Dokumentation/Actor_Critic_mit_PPO.md

== Sequenzmodellierung für RL


Der MDP setzt durch die Markov-Eigenschaft voraus, dass der aktuelle Zustand alle für zukünftige Entscheidungen relevanten Informationen enthält. In praktischen Anwendungen ist diese Voraussetzung aus Sicht des Agenten jedoch häufig nicht vollständig erfüllt, da der Agent meist nur eine begrenzte Beobachtung der Umgebung erhält. Sutton und Barto betonen, dass eine Zustandsrepräsentation nicht auf unmittelbare Sensordaten beschränkt sein muss, sondern auch aus vergangenen Wahrnehmungen oder einem internen Gedächtnis aufgebaut werden kann [@sutton_reinforcement_2018;S.49].

Bei einem Agenten mit Ray-Sensoren beschreibt ein einzelner Timestep beispielsweise nur einen lokalen Ausschnitt der Umgebung. Dadurch kann der Agent aus einer einzelnen Beobachtung nicht zuverlässig ableiten, ob er sich bereits in einer Sackgasse befindet oder welchen Weg er zuvor genommen hat. Solche Problemstellungen lassen sich als partiell beobachtbare Entscheidungsprobleme auffassen, bei denen vergangene Beobachtungen und Aktionen zusätzliche Informationen für die Entscheidungsfindung liefern können.

Sequenzmodelle wie LSTM oder Transformer können diese zeitlichen Informationen nutzen, indem sie mehrere vergangene Zeitschritte berücksichtigen. Dadurch kann der Agent eine bessere interne Repräsentation seiner aktuellen Situation aufbauen und fundiertere Entscheidungen treffen.


=== Long Short-Term Memory (LSTM)
Long Short-Term Memory (LSTM) ist eine spezielle Variante rekurrenter neuronaler Netze (Recurrent Neural Networks, RNNs), die entwickelt wurde, um Informationen über lange Zeiträume hinweg speichern und verarbeiten zu können [@goodfellow_deeplearningbookorgcontentsrnnhtml_2026;S.404]. Während klassische RNNs grundsätzlich für die Verarbeitung sequenzieller Daten geeignet sind, stoßen sie bei langen Eingabesequenzen häufig an ihre Grenzen. Ursache hierfür ist das sogenannte Vanishing-Gradient-Problem, bei dem die während des Trainings berechneten Gradienten mit zunehmender Sequenzlänge immer kleiner werden. Dadurch wird es für das Netzwerk schwierig, Abhängigkeiten zwischen weit auseinanderliegenden Zeitschritten zu erlernen und relevante Informationen langfristig zu speichern [@goodfellow_deeplearningbookorgcontentsrnnhtml_2026;S.404].
Um dieses Problem zu lösen, erweitert LSTM die Architektur klassischer RNNs um eine Speicherstruktur, die als Zellzustand bezeichnet wird. Dieser dient als internes Gedächtnis und ermöglicht die Weitergabe wichtiger Informationen über viele Zeitschritte hinweg. Der Informationsfluss innerhalb des Netzwerks wird dabei durch mehrere lernbare Steuermechanismen, sogenannte Gates, kontrolliert [@goodfellow_deeplearningbookorgcontentsrnnhtml_2026;S.404ff].
Das Forget Gate entscheidet, welche Informationen aus dem bisherigen Gedächtnis beibehalten und welche verworfen werden. Dadurch kann das Netzwerk nicht mehr relevante Informationen gezielt vergessen. Das Input Gate bestimmt, welche neuen Informationen aus dem aktuellen Eingabeschritt in den Zellzustand aufgenommen werden. Das Output Gate legt schließlich fest, welche Teile des internen Gedächtnisses als Ausgabe an den nächsten Zeitschritt beziehungsweise an nachfolgende Netzwerkschichten weitergegeben werden [@goodfellow_deeplearningbookorgcontentsrnnhtml_2026;S. 406f] .
Durch das Zusammenspiel dieser Gates kann ein LSTM relevante Informationen über viele Zeitschritte hinweg speichern und gleichzeitig irrelevante Informationen verwerfen. Dadurch eignet sich die Architektur besonders für Aufgaben, bei denen zeitliche Abhängigkeiten eine wichtige Rolle spielen, beispielsweise bei der Sprachverarbeitung, Zeitreihenanalyse oder im Reinforcement Learning.
Das Gedächtnis eines LSTM wird durch einen kontinuierlich aktualisierten internen Zustand repräsentiert. Welche Informationen gespeichert, überschrieben oder vergessen werden, wird nicht manuell festgelegt, sondern während des Trainings automatisch erlernt. Im Kontext von Reinforcement Learning ermöglicht dies dem Agenten, Informationen aus vergangenen Beobachtungen zu berücksichtigen und dadurch fundiertere Entscheidungen zu treffen. In Unity ML-Agents ist LSTM bereits integriert und kann über die Konfigurationsoption use_recurrent: true aktiviert werden. Dadurch erhält der Agent eine Form von Gedächtnis, die es ihm erlaubt, auch in teilweise beobachtbaren Umgebungen historische Informationen in seine Entscheidungsfindung einzubeziehen.
// - Hochreiter & Schmidhuber (1997)
// - Gates: Forget / Input / Output
// - Implizites Gedächtnis ohne expliziten Sequenz-Buffer
// - In ML-Agents standardmäßig verfügbar (use_recurrent: true)

=== Transformer-Architektur
Die Transformer-Architektur wurde von Vaswani et al. im Jahr 2017 in der einflussreichen Arbeit "Attention Is All You Need" vorgestellt und hat die Verarbeitung sequenzieller Daten grundlegend verändert @vaswani_attention_2023. Ursprünglich wurde sie für Anwendungen der natürlichen Sprachverarbeitung entwickelt, findet heute jedoch auch in zahlreichen anderen Bereichen des maschinellen Lernens Anwendung.
Im Gegensatz zu rekurrenten Architekturen wie LSTM verarbeitet ein Transformer eine Sequenz nicht schrittweise, sondern betrachtet alle Elemente eines definierten Sequenzfensters gleichzeitig. Dadurch können Abhängigkeiten zwischen verschiedenen Positionen einer Sequenz parallel analysiert werden, was sowohl die Trainingsgeschwindigkeit erhöht als auch die Modellierung weitreichender Zusammenhänge erleichtert.
Das zentrale Element der Architektur ist der sogenannte Self-Attention-Mechanismus. Dieser ermöglicht es dem Modell, die Relevanz einzelner Sequenzelemente für die Verarbeitung eines bestimmten Zeitschritts zu bewerten. Jedes Element einer Sequenz kann somit direkt Informationen von allen anderen Elementen berücksichtigen, unabhängig davon, wie weit diese zeitlich voneinander entfernt sind. Auf diese Weise lassen sich langfristige Abhängigkeiten erfassen, ohne die Einschränkungen rekurrenter Strukturen in Kauf nehmen zu müssen [@vaswani_attention_2023;S.6f].
Zur weiteren Steigerung der Modellkapazität wird häufig Multi-Head-Attention eingesetzt. Dabei werden mehrere Attention-Mechanismen parallel ausgeführt, sodass unterschiedliche Beziehungen und Muster innerhalb derselben Sequenz gleichzeitig erlernt werden können. Die einzelnen Aufmerksamkeitsköpfe fokussieren sich dabei auf verschiedene Aspekte der Eingabedaten und tragen gemeinsam zu einer umfassenderen Repräsentation der Sequenz bei [@vaswani_attention_2023;S.4f].
Da die Transformer-Architektur keine rekurrenten Verbindungen besitzt und somit keine inhärente Kenntnis über die Reihenfolge der Eingabedaten hat, muss die Positionsinformation explizit bereitgestellt werden. Dies geschieht durch sogenannte Positional Encodings, welche die Position jedes Sequenzelements kodieren und dem Modell ermöglichen, zeitliche oder räumliche Zusammenhänge innerhalb der Daten zu berücksichtigen [@vaswani_attention_2023; S2-6].
Auch im Reinforcement Learning haben Transformer-Modelle in den vergangenen Jahren zunehmend an Bedeutung gewonnen. Parisotto et al. entwickelten mit Gated Transformer-XL (GTrXL) eine speziell angepasste Transformer-Architektur, die stabile Lernprozesse bei sequenziellen Entscheidungsaufgaben ermöglicht und die Anwendung von Transformern im Reinforcement Learning erheblich voranbrachte @parisotto_stabilizing_2019. Aufbauend auf diesen Erfolgen zeigten Chen et al. mit dem Decision Transformer, dass Reinforcement-Learning-Probleme als reine Sequenzmodellierungsaufgaben formuliert werden können. Anstatt eine klassische Wertfunktion oder Policy zu lernen, erzeugt das Modell Aktionen auf Basis vergangener Zustände, Aktionen und angestrebter Returns und nutzt dabei die Stärken der Transformer-Architektur für die Entscheidungsfindung @chen_decision_2021.
Durch ihre Fähigkeit, langfristige Abhängigkeiten effizient zu modellieren und Sequenzen parallel zu verarbeiten, stellen Transformer mittlerweile eine vielversprechende Alternative zu rekurrenten Architekturen wie LSTM dar und werden zunehmend auch für komplexe Aufgaben im Reinforcement Learning eingesetzt.
// - Vaswani et al. (2017): Attention is All You Need
// - Self-Attention, Multi-Head-Attention, Positional Encoding
// - Anwendung im RL-Kontext: Decision Transformer (Chen 2021), GTrXL (Parisotto 2020)
// - Vor- und Nachteile gegenüber LSTM
// - Quelle: Dokumentation/Transformer_Integration.md, Dokumentation/LSTM_Integration.md

== Wahrnehmung in RL-Agenten
Die Qualität der Wahrnehmung bestimmt maßgeblich, welche Informationen dem Agenten zur Entscheidungsfindung zur Verfügung stehen. In Unity ML-Agents werden Beobachtungen als Eingabevektoren an das neuronale Netz übergeben. Je nach Sensortyp unterscheiden sich Informationsdichte, Rechenaufwand und die Anforderungen an die Netzwerkarchitektur erheblich.



#pagebreak()

// ############################################################################
// ############################################################################
// ##                                                                        ##
// ##   NEUSTRUKTURIERUNG (Entwurf 2) — narrativ entlang der Kausalkette      ##
// ##   Restaurant -> Abstraktion -> Generalisierung -> Messbarkeit ->       ##
// ##   Engine -> Sensorik -> Verarbeitung -> Gedaechtnis -> LSTM/Transf.    ##
// ##                                                                        ##
// ##   HINWEIS: Dieser Block dupliziert die Kapitel-Ueberschriften von      ##
// ##   oben. Nach dem Review den ALTEN Block (oben) loeschen, damit das     ##
// ##   Dokument nur EINE Gliederung enthaelt.                               ##
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
//        · Forschungsluecke/Arch.-Vergleich -> NEU 1.5
//        · (Messbarkeits-Argument NEU 1.4 ist neu, aus Generalisierungs-Inhalt)
// ALT 1 "Problemstellung/Forschungsfrage" -> NEU 1.5 (RQ1-4, H1-4)
// ALT 1 "Zielsetzung und Abgrenzung"      -> NEU 1.6 (1:1)
// ALT 1 "Aufbau der Arbeit"               -> NEU 1.7 (1:1)
//
// --- GRUNDLAGEN (bleibt Kapitel 2, nur Reihenfolge/Rahmung) ---
// ALT 2 "ML und Reinforcement Learning"   -> NEU 2.1 (1:1)
// ALT 2 "Proximal Policy Optimization"    -> NEU 2.2 (1:1)
// ALT 2 "Wahrnehmung in RL-Agenten"       -> NEU 2.3 (VORGEZOGEN vor Sequenzmodell.)
//        (die Sensor-Substanz speist zusaetzlich die Entscheidung in NEU 4.4)
// ALT 2 "Sequenzmodellierung fuer RL"     -> NEU 2.4
//        · LSTM-Unterkapitel                -> NEU 2.4.2
//        · Transformer-Unterkapitel         -> NEU 2.4.3
//        · (Gedaechtnisproblem NEU 2.4.1 ist neu/kurz; Motivation auch in 1.5)
// ALT 2 "Unity ML-Agents Toolkit"         -> NEU 2.5 (1:1)
//
// --- STAND DER TECHNIK ---
// ALT 3 "Stand der Technik"               -> NEU 3 (1:1)
//
// --- ACHTUNG: METHODIK (alt 4) und SYSTEMARCHITEKTUR (alt 5) TAUSCHEN ---
// ALT 5 "Gesamtueberblick"                -> NEU 4.1
// ALT 5 "Map-System / Datenmodell"        -> NEU 4.2.1
// ALT 5 "Map-System / MapGenerator"       -> NEU 4.2.2
// ALT 5 "Prozedurale Map-Generierung"     -> NEU 4.2.3 (UMGERAHMT: Rueckgriff 1.4,
//                                            "Umsetzung der Messbarkeitsbedingung")
// ALT 5 "Agent-System" (alle Unterpunkte) -> NEU 4.3
// ALT 5 "Sensorik"                        -> NEU 4.4 (+ explizite Wahl "warum Ray")
// ALT 5 "Reward-System"                   -> NEU 4.5 (1:1)
// ALT 5 "Trainingsinfrastruktur"          -> NEU 4.6 (1:1)
//
// ALT 4 "Wissenschaftliche Rahmung"       -> NEU 5.1
// ALT 4 "Agenten-Matrix/Vergleichsdesign" -> NEU 5.2
// ALT 4 "Kontrollierte Variablen"         -> NEU 5.3 (Vorspann + 5.3.1)
//        (NEU 5.3.2 "Notwendige YAML-Abweichungen" ist ZUSATZ; Quelle:
//         02_Anforderungen_Fairer_Vergleich.md, Abschnitt A.2)
// ALT 4 "Evaluationsprotokoll"            -> NEU 5.4 (Primaer/General./Statistik)
//
// --- MODELLARCHITEKTUREN ---
// ALT 6 "MLP / LSTM / Transformer / Geplante" -> NEU 6.1 / 6.2 / 6.3 / 6.4
//        ACHTUNG: der Bau-/Debugging-PROZESS des Transformers wandert nach
//        NEU 7.6; in 6.3 bleibt nur die statische ARCHITEKTUR-Beschreibung.
//
// --- UMSETZUNG ---
// ALT 7 "Milestones 1-2 / 3 / 4 / 5 / 6"  -> NEU 7.1 / 7.2 / 7.3 / 7.4 / 7.5 (1:1)
// ALT 7 "Milestone 7: Transformer-/LSTM-Integration" -> AUFTEILEN:
//        · Transformer-Teil + "Iterative Fehlerdiagnose" (Bug 1-5)
//                                           -> NEU 7.6, nach PROBLEMKLASSEN sortiert
//                                              (7.6.1 Patch, 7.6.2 A, 7.6.3 B, 7.6.4 C)
//        · LSTM-Teil                        -> NEU 7.7 (bewusst knapp)
// ALT 7 "Trainings-Iterationen V5-V13"    -> NEU 7.6.5 (verdichtete Tabelle,
//                                            erweitert bis V22; Detail -> Anhang)
//
// --- EVALUATION (nur FINALE Ergebnisse, keine Doppelung mit 7.6) ---
// ALT 8 "MLP-Baseline"                    -> NEU 8.1
// ALT 8 "Transformer-/LSTM-Iterationen"   -> WICHTIG: der ITERATIONS-VERLAUF
//        (Reward-Kurven V5-V13, Diagnose) gehoert nach NEU 7.6, NICHT hierher.
//        In Kap. 8 bleiben nur die abschliessenden Vergleichszahlen.
// ALT 8 "Paarweise Architektur-Vergleiche" -> NEU 8.2
// ALT 8 "Generalisierung held-out Maps"   -> NEU 8.3
// ALT 8 "Statistische Auswertung"         -> NEU 8.4
// ALT 8 "Diskussion"                      -> NEU 8.5
//
// --- UEBERTRAGBARKEIT ---
// ALT 9 "Analogie Labyrinth <-> real"     -> ZWEIGETEILT:
//        · die Analogie-Tabelle/Rahmung     -> nach vorn zu NEU 1.2
//        · die praktische Auswertung         -> bleibt NEU 9.1
// ALT 9 "Hardware-/Software-Anforderungen" -> NEU 9.2 (1:1)
// ALT 9 "Bewertungsmatrix"                -> NEU 9.3 (1:1)
// ALT 9 "Limitationen der Uebertragbarkeit"-> NEU 9.4 (1:1)
//
// --- FAZIT ---
// ALT 10 (alle Unterpunkte)               -> NEU 10.1-10.4 (1:1)
//
// --- ANHANG ---
// ALT Anhang                              -> NEU Anhang, ZUSAETZLICH:
//        · YAML-Basis + markierte Abweichungen (stuetzt NEU 5.3.2)
//        · vollstaendige Iterationstabelle V1-V22 m. TensorBoard (stuetzt 7.6.5)
// ----------------------------------------------------------------------------


// ============================================================================
// 1. EINLEITUNG  — Kausalkette als roter Faden
//DAVID ============================================================================
= Einleitung

== Ausgangsszenario: Serviceroboter im Restaurant

// - Konkreter Anker: KI-gesteuerte Serviceroboter sollen autonom navigieren
// - Warum ein reales, greifbares Szenario als Ausgangspunkt (statt abstrakt)

== Von der realen Umgebung zur testbaren Abstraktion

// - Uebersetzung realer Umgebung in eine vergleichbare, abstrahierte Welt
//   -> testbar ohne physischen Roboter
// - Analogie-Tabelle: Korridor <-> Gang, Lava <-> Stufe/Kabel,
//   prozedurales Layout <-> veraenderliche Umgebung
//   (aus altem Kap. "Uebertragbarkeit" nach vorn gezogen)

== Generalisierung als zentrale Anforderung

// - Jedes Restaurant sieht anders aus -> Agent muss generalisieren,
//   nicht einen Grundriss auswendig lernen
// - Das ist die zentrale Anforderung, nicht bloss Memorierung

== Messbarkeit von Generalisierung

// - TRAGENDES ARGUMENT 1:
//   Generalisierung ist nur nachweisbar auf Layouts, die im Training NIE
//   vorkamen -> setzt systematisch erzeugbare Layouts (prozedurale
//   Map-Generierung) UND ein zurueckgehaltenes, ungesehenes Test-Set voraus
// - Map-Generierung ist damit Bedingung der Messbarkeit, kein Feature

== Offene Fragen und Forschungsfrage

// - Abgeleitete offene Fragen (in dieser Reihenfolge):
//     (a) Wie lassen sich KI-Agenten in einer 3D-Welt implementieren,
//         welche Herausforderungen bringt die Game-Engine mit?
//     (b) Welche Sensorik bildet reale Wahrnehmung ab -> warum Ray-basiert?
//     (c) Wie verarbeitet der Agent Informationen zu Entscheidungen?
//     (d) Sackgassen: ein gedaechtnisloser Agent laeuft reaktiv gegen die
//         Wand -> Gedaechtnis noetig
// - Hauptforschungsfrage:
//   "Kann ein Transformer-basierter RL-Agent in einer selbst gebauten
//    3D-Labyrinthwelt generalisierbares Navigations- und Hindernis-
//    vermeidungsverhalten erlernen, das sich auf unbekannte Map-Layouts
//    uebertragen laesst?"
// - Erweiterte Forschungsfragen RQ1-RQ4, Hypothesen H1-H4
// In 1.5 nur die Haupt-Forschungsfrage plus die vier RQ als Fragen formulieren
// Vorwärtsverweis auf 5.1 setzen




== Zielsetzung und Abgrenzung

// - Pflichtumfang: 3D-Labyrinth, 5 Maps, Ray-Sensorik, Lava/Hole/Sackgassen,
//   Transformer als Kernmodell, MLP-Baseline, >= 1 Ablationsstudie,
//   Generalisierungstest, reproduzierbares Repo, Bericht + Video-Demos
// - Optionale, umgesetzte Erweiterungen: prozedurale Map-Generierung,
//   Curriculum Learning, LSTM-Vergleich, Multi-Area-Training
// - NICHT geleistet: Sim-to-Real, Multi-Agent, dynamische Hindernisse

== Aufbau der Arbeit

// - Kurze Uebersicht der Kapitel


// ============================================================================
// 2. THEORETISCHE GRUNDLAGEN  — als Werkzeugkasten, geordnet nach den Fragen
//DAVID ============================================================================
= Theoretische Grundlagen

== Maschinelles Lernen und Reinforcement Learning

// - Einordnung KI ⊃ ML ⊃ RL; supervised / unsupervised / reinforcement
// - Markov-Entscheidungsprozesse (MDP), Policy, Value-/Q-Function
// - On-Policy vs. Off-Policy

== Proximal Policy Optimization (PPO)

// - Actor-Critic-Framework (Actor-Netz + Critic-Netz)
// - Schulman et al. (2017): Clipping (ε = 0.2), GAE (λ = 0.95)
// - Vorteil ggue. Vanilla Policy Gradient (Stabilitaet)

== Wahrnehmung in RL-Agenten

// - Sensortypen: Ray-Sensoren, Kamera (CNN), Vector-Observations
// - Beobachtungsraeume und Normalisierung
// - (liefert die Substanz fuer die Sensor-Entscheidung in 4.4)

== Sequenzmodellierung und Gedaechtnis in RL

=== Das Gedaechtnisproblem reaktiver Agenten

// - TRAGENDES ARGUMENT 2 (KURZ, konzeptionell, 1 Absatz):
//   Ein gedaechtnisloser Agent kann nicht wissen, aus welcher Richtung er
//   kam -> reaktives Anlaufen gegen die naechste Wand in Sackgassen
// - Motiviert, warum ueberhaupt sequenzfaehige Architekturen noetig sind
// - Querverweis auf 1.5 (Frage) und 7.6.4 (empirischer Beleg)

=== Long Short-Term Memory (LSTM)

// - Hochreiter & Schmidhuber (1997); Forget-/Input-/Output-Gates
// - Implizites Gedaechtnis ohne expliziten Sequenz-Buffer
// - In ML-Agents standardmaessig verfuegbar (use_recurrent: true)

=== Transformer-Architektur

// - Vaswani et al. (2017); Self-/Multi-Head-Attention, Positional Encoding
// - RL-Kontext: Decision Transformer (Chen 2021), GTrXL (Parisotto 2020)
// - Vor-/Nachteile ggue. LSTM NEUTRAL beschreiben (keine Wertung vorwegnehmen)

== Unity ML-Agents Toolkit

// - Architektur: Unity-Environment <-> Python-Trainer (gRPC)
// - Komponenten: Agent, Behavior Parameters, Decision Requester, Sensoren
// - Workflow: YAML-Config, ONNX-Export, TensorBoard; Version 0.30.0


// ============================================================================
// 3. STAND DER TECHNIK
//KATYA ============================================================================
= Stand der Technik

// - Klassisches Pathfinding (A*, Dijkstra) vs. RL-Navigation
// - RL-Navigation: DeepMind Atari (Mnih 2015), Habitat/AI2-THOR, CARLA
// - Memory-augmented RL: DNC, GTrXL
// - Curriculum Learning (Bengio 2009)
// - Procedural Content Generation fuer RL (Justesen et al. 2018)

== Forschungslücke
// - was die zitierten Arbeiten nicht abdecken und was diese Arbeit beiträgt. 


// ============================================================================
// 4. SYSTEMARCHITEKTUR UND UMGEBUNG  — erst die Welt bauen (vor Methodik)
//FINN ============================================================================
= Systemarchitektur und Umgebung
//was das System kann
// weicht  von der verbreiteten Erwartung „Methodik vor Implementierung ab, kurz begründen warum "man muss die Welt kennen, um das Experimentaldesign zu verstehen"
== Gesamtueberblick

// - Komponentendiagramm: Unity-Env (Editor/Standalone-Build) <-> Python-Trainer
//   (mlagents-learn, PPO) <-> TensorBoard; Kopplung ueber ML-Agents-gRPC-Port
// - je --num-envs ein eigener Unity-Prozess (Headless), eigener Port
// - Engine Unity + ML-Agents-Package (com.unity.ml-agents 2.0.2 im Projekt)
// - Code-Layout:
//     Assets/Scripts/{Map, Agent, Camera, Audio, Competition, Visual}
//     Assets/Editor/ (Generatoren, Szenen-Builder, Validatoren)
//     Assets/{Scenes, Prefabs}/
//     training/  (Python: Patch, Policies, Export, Reports)
//     config/    (Trainer-YAMLs)
//     results/   (Trainingslaeufe, Checkpoints, ONNX)

== Map-System

=== Datenmodell
// Achtung Redundanz mit Kapitel 7.1 vermeiden
// - CellType-Enum, 9 Werte: Empty, Floor, Wall, Obstacle, Goal, SpawnPoint,
//   Lava, Hole, Platform  (Lava/Hole/Platform sind die Gefahren-/Sprung-Typen)
// - MapData (ScriptableObject): width, height, flaches Array CellType[] cells,
//   Indexierung y*width+x; GetCell / SetCell
// - MapData-Laufzeitfelder (nicht serialisiert): cellHeightOffsets (Platform-Hoehe,
//   Default 0.75), noRuntimeObstacles-Flag

=== MapGenerator (Runtime)

// - reiner Renderer: nimmt fertige MapData und instanziiert Tiles (kein Bauen)
// - Prefab-Mapping (BuildPrefabMap): Floor/Obstacle/Goal/SpawnPoint -> floorPrefab,
//   Wall -> wallPrefab, Lava -> lavaPrefab, Hole -> holePrefab, Platform -> platformPrefab
// - Tiles aus wiederverwendbarem Tile-Pool (kein Instantiate/Destroy pro Episode)
// - dynamische Spawn-Wahl: zufaellige Floor/SpawnPoint-Zelle, meidet Lava/Hole-Nachbarn
// - dynamische Goal-Wahl: zufaellige Zielzelle, verschieden von Spawn
// - Marker-Objekte (SpawnPoint, Goal) separat instanziiert; Goal +0.5 Y
// - persistente KillZone (Trigger-Box unter der Map, y=-20) fuer Loch-Faelle
// - optionales Kamera-Framing (autoFrameCamera, ortho/perspektiv)
// - WICHTIG: keine Laufzeit-Hindernis-Platzierung, keine BFS-Validierung hier
//   -> Hindernisbau + Loesbarkeitscheck passieren in der prozeduralen Pipeline (s.u.)
// - Platzierungs-Modi (Enums):
//     SpawnPlacementMode    {RandomSpawnPoints, PredefinedSpawnPoints}
//     GoalPlacementMode     {RandomGoalCells, PredefinedGoalSpawnPoints}
//     ObstaclePlacementMode {RandomOnFloor, PredefinedSpawnPoints}
//     MapSelectionMode      {Fixed, Random, Sequential}   // NICHT Curriculum
// - Curriculum ist ein separater TrainingMode {Standard, Curriculum};
//   im Curriculum liefert CurriculumTracker.GetNextLayout() die MapData
// - Multi-Area-Setup: TrainingArea-Prefab, mehrfach in der Szene
//     Training_MultiArea = 10 Areas, Transformer_Test_V2 = 16 Areas,
//     Einzel-Szenen (MLP_Training, Transformer_Test) = 1 Area (Parallelisierung
//     dann ueber --num-envs)

=== Prozedurale Generierung als Umsetzung der Messbarkeitsbedingung

// - UMGERAHMT: Rueckgriff auf 1.4 — hier wird die geforderte Bedingung baulich
//   eingeloest (nicht als "Feature")
// - Einstiegspunkt ProceduralLayoutGenerator.GenerateLayout(seed, difficulty):
//     bis zu 10 Versuche; Pipeline: BuildTopology -> Raeume -> Korridore -> Waende
//     -> Spawn/Goal -> Coverage-Check (>=15%) -> Cluster -> Platforms -> Pfad-Check
//   Aufruf aus Editor-Skripten (MapGeneratorEditor, CurriculumV2Builder), nicht Runtime
// - RoomCorridorGraph: Raum-Korridor-Graph
//     BORDER-Puffer = 2 (Inhalte nie am Grid-Rand), MIN_CORRIDOR_LEN = 4
//     2-Tile-breite Korridore (Hauptrichtung + Senkrechte)
//     Raumtypen Start / Goal / DeadEnd; GoalRoom = am weitesten entfernter Knoten
//     (Manhattan); Terminal-Korridore enden blind (spaeter Hole); optionale Loops
// - ObstacleClusterPlacer: Cluster aus Lava/Hole (+ Platform)
//     Goal-Korridor    -> Lava, Tiefe 1/2/3 (gewichtet), Platform ab Tiefe > 1
//     DeadEnd/Terminal -> Hole, Tiefe 2 (durch Groesse nicht ueberspringbar)
//     Loop-Korridor    -> 50% Lava Tiefe 1
//     DeadEnd-Korridor -> Chance: kein Hindernis / Hole / Lava
// - SemanticPathfinder: Loesbarkeitscheck (BFS, 4-Nachbarschaft)
//     Floor/Spawn/Goal/Platform begehbar; Hole nie
//     Lava begehbar wenn Cluster-Tiefe == 1 (ueberspringbar) ODER Platform vorhanden
//     -> jede ausgelieferte Map ist garantiert loesbar
// - Schwierigkeitsgrade (DifficultyLevel, aufsteigend):
//     Trivial -> TrivialCorr -> TrivialBranch -> TrivialHole -> TrivialHazard
//     -> Easy -> Medium -> Hard   (+ Sonderstufe TrivialLava)
//     Trivial-Familie: direkte 7x7-Konstruktion; Easy/Medium/Hard: Graph-Pipeline
//     DifficultySettings pro Stufe: Grid-Groesse, Korridorzahl, Verzweigungstiefe,
//     Hindernis-Wahrscheinlichkeiten

== Agent-System
// Klasse: LabyrinthAgent : Agent  (Assets/Scripts/Agent/LabyrinthAgent.cs)
// BehaviorName "LabyrinthNavigator", DecisionPeriod 5

=== Aktionsraum

// - diskret, 3 Branches mit Groessen [3, 3, 3]
//     Branch 0 Bewegung: 0 = nichts, 1 = vorwaerts, 2 = rueckwaerts
//     Branch 1 Drehung : 0 = nichts, 1 = links,     2 = rechts
//     Branch 2 Sprung  : nur Wert 1 loest Sprung aus -> effektiv binaer
// - Heuristik (manuelle Steuerung): W/S = vor/zurueck, A/D = drehen, Space = Sprung
// - kein "SuperSprung": Sprung ist ein einzelner AddForce-Impuls, nur wenn geerdet

=== Observation-Space

// - Vektor-Observations, konfigurationsabhaengig (Flag v24CompatMode)
// - Volles Set = 31 Werte:
//     18  Boden-Sensor (9 Positionen x [Typ-Code, norm. Distanz])
//      3  Eigengeschwindigkeit (lokal, / moveSpeed)
//      1  isGrounded
//      1  Distanz zum Ziel (/ maxObservationDistance = 20)
//      3  Richtung zum Ziel (lokal, normiert)
//      4  Wand-Raycasts (vorne, rechts, links, hinten; norm. Distanz)
//      1  Line-of-Sight zum Ziel (0/1)
// - v24CompatMode (aktuelles Agent-Prefab) = 21 Werte: nur 18 Boden + 3 Velocity
//   (V24-Transformer wurde ohne die restlichen Obs trainiert)
// - dazu separater Ray-Sensor (s. Kapitel Sensorik), stacked = 2
// - NumStackedVectorObservations = 1 fuer den Vektor-Sensor

=== Bewegungs- und Sprungphysik

// - Rigidbody: Masse 1, Drag 0.5, Constraints = FreezeRotation X+Z (nur Y-Drehung)
// - MoveRotation (turnSpeed 180 Grad/s), MovePosition (moveSpeed 5), AddForce-Impuls
//   (jumpForce 10.5, nur bei isGrounded)
// - GroundCheck: Raycast nach unten, geerdet auf Floor/Bridge/Platform/Goal
// - Wall-Climb-Guard: y > spawnY + wallClimbMaxY (5) -> Penalty (Anti-Kletter-Exploit)
// - maxUpwardVelocity-Cap (8) in FixedUpdate: begrenzt Aufwaerts-Geschwindigkeit (V11/V12)

=== (Third-Person-Kamera) // kann man diskutieren ob man es braucht zur not raus, aber schon interessant wegen showcase etc. und um den agenten zu verstehen wie erfunktinoiert

// - ThirdPersonCamera: Smooth-Follow in LateUpdate
// - Position via SmoothDamp (positionSmoothTime 0.1), Rotation via Slerp (speed 5)
// - lokaler Offset zum Agenten (Hoehe 3, Distanz 5) -> folgt Blickrichtung
// - weitere Kameras vorhanden (Front-Follow, Drone, CameraSwitcher) — optional

== Sensorik — und die begruendete Wahl der Ray-Wahrnehmung

// - ENTSCHEIDUNG SICHTBAR MACHEN: warum Ray statt (nur) Kamera fuer die
//   Basis-Vergleichsgruppe -> CPU-tauglich, robust, direkt interpretierbar
// - Horizontaler RayPerceptionSensor (ML-Agents-Komponente am Prefab):
//     11 Rays (RaysPerDirection 5 -> 2*5+1), 120° (MaxRayDegrees 60 = Halbwinkel),
//     Reichweite 12, Stacked = 2, SphereCast-Radius 0.25
// - 6 Detectable Tags: Wall, Obstacle, Lava, Hole, Goal, Bridge
// - Manueller Boden-Sensor (im Agent-Code, kein RayPerceptionSensor):
//     9 Raycasts nach unten (Reichweite 2), je 2 Werte (Typ-Code + norm. Distanz)
//     Typ-Codes: Floor +1, Lava -1, Hole -0.5, Bridge +0.5, kein Treffer -1.5
//     Positionen: unter dem Agenten, vorne 1/2 Zellen, diagonal, seitlich

== Reward-System
// keine DesignEntscheidungen und ihre Wirkung (abgrenzung 7.4)
// - Architektur: zentrale Vergabe im Agent; externe Objekte (Lava, KillZone)
//   loesen nur OnTriggerEnter aus, der Agent vergibt den Reward
// - Kern-Terme (formale Funktion) und Werte:
//     Ziel erreicht        goalReward       = +30   (Episode-Ende, Erfolg)
//     Lava-Tod             lavaDeathPenalty = -3    (Episode-Ende)
//     Loch-Tod (KillZone)  holeDeathPenalty = -3    (Episode-Ende)
//     Timeout (MaxStep)    timeoutPenalty   = -10
//     Zeitstrafe/Step      stepPenalty      = -0.002
//     PBRS-Shaping         F = (prevDist − γ·currDist) · scale
//                          γ (pbrsGamma) = 1.0, scale (distanceShapingScale) = 0.01
// - weitere aktive Terme (fuer vollstaendige Funktion noetig):
//     Lava-Sprung-Versuch  +1.5, dann /4, /8, danach 0 (abklingend, Edge-Trigger)
//     Lava-Ueberquerung    +8 (nach Landung)
//     Loch-Ueberflug       -1 (Edge-Trigger; Loecher sollen umgangen werden)
//     Line-of-Sight        +0.005 (bei freier Sicht zum Ziel)
//     Wall-Climb           -1 (bei Ueberschreiten der Hoehe)
// - MaxStep pro Curriculum-Phase (phaseMaxSteps): 600 / 1200 x4 / 1500 / 2000 / 2500
// - Curiosity ist KEIN Agent-Reward, sondern ein Trainer-Reward-Signal (Config):
//     nur in Transformer- und LSTM-Curiosity-Config aktiv (strength 0.05),
//     nicht in der Standard-PPO-Config
// - Quelle: Reward_Strategie.md

== Trainingsinfrastruktur

// - Python-venv mit mlagents 0.30.0 (im Patch-Skript benannt), PyTorch 2.0.1
//   (CUDA-Variante cu118 nur in Doku, nicht im Code verankert -> ggf. pruefen)
// - Patch-Skript training/patch_mlagents.py: ruestet die venv fuer Custom-Policies
//   nach (Transformer-Memory): kopiert transformer_memory.py, erweitert settings.py
//   (memory_type) und networks.py (Transformer-Branch neben LSTM);
//   start_training.py wendet den Patch automatisch an
// - Trainer-Konfigurationen (config/):
//     PPO-Baseline (labyrinth_training.yaml): lr 3e-4, batch 512, buffer 10240,
//       gamma 0.99, MLP 256x2, normalize false, max_steps 6.4M
//     Transformer (labyrinth_transformer.yaml): memory_type transformer,
//       sequence_length 16, memory_size 128, curiosity 0.05, gamma 0.997, max_steps 60M
//     weitere: labyrinth_lstm*.yaml, model_comparison*.yaml
// - Parallelisierung: Multi-Area (mehrere TrainingAreas je Szene) + Headless-Builds
//   via --num-envs; je Worker eigener mlagents-Port und eigene Curriculum-State-Datei
// - Hardware: <vom Autor einzutragen — CPU/GPU/RAM, Trainingsdauer>


// ============================================================================
// 5. METHODIK UND EXPERIMENTELLES DESIGN  — nach dem System
//ALLE ============================================================================
= Methodik und experimentelles Design

== Wissenschaftliche Rahmung //DAVID
//Achtung Redundanz 1.5 ABGRENZEN iwi
// - Forschungsfragen RQ1-RQ4, Hypothesen H1-H4
// -  jede RQ auf Metrik + Hypothese + zuständigen Vergleich abbilden (sonst Wiederholung mit 1.5)

== Vergleichsdesign //maybe besseren Namen finden wird jetzt mit wissenschaflticher Rahmung fussioniert (war davor eigenständige Überschrift, hier soll nur kurz erklärt werden )
// Transformer, LSTM, MLP 
//DAVID



== Kontrollierte Variablen und begruendete Abweichungen //ALEX

// - VORSPANN (Grundprinzip): pro Vergleich aendert sich nur EINE Variable,
//   alles andere ist eingefroren -> Messgrundlage fuer die Unterabschnitte.

=== Identische Parameter //ALEX

// - PPO-Kern identisch fuer alle Agenten: learning_rate 3e-4, batch_size 512,
//   buffer_size, beta, epsilon 0.2, lambd 0.95, num_epoch, max_steps,
//   time_horizon, gamma, hidden_units 256, num_layers 2
// - Reward-Struktur identisch und VOR dem Training eingefroren
//   (inkl. Curiosity: fuer ALLE an oder fuer KEINEN)
// - Sensor-Basis und Seeds identisch

=== Notwendige YAML-Abweichungen und ihre Begruendung //ALEX

// - DEINE FRAGE / EXPLIZIT: die YAMLs sind NICHT zu 100% identisch — und das
//   ist korrekt
// - Kontrolliert abweichende Parameter:
//     · memory_type: lstm | transformer  (je nach Agent)
//     · vis_encode_type: simple           (nur bei Kamera-Agenten)
//     · Sensor-Konfiguration              (Ray vs. Kamera vs. Kombination)
// - Begruendung: diese Parameter sind KONSTITUTIV fuer den Vergleichs-
//   gegenstand selbst — man kann Transformer vs. LSTM nicht vergleichen,
//   ohne memory_type zu aendern. Eine erzwungene 100%-Identitaet waere
//   nicht "fairer", sondern sinnlos.
// - Quelle: 02_Anforderungen_Fairer_Vergleich.md (Abschnitt A.2)

== Abweichung in Tuning-Iterationen //KATYA
// "Problem": Transformer wurde um einiges mehr "getuned" als bsp MLP
// Begründen warum das so war, das das dem geschuldet ist das der MLP nativ in Unity läuft das deswegen kaum tuning benötigt da er sehr einfach zu implementieren ist. 
// Das wir den Transformer nachpatchen mussten was auch für iterationsbedarf gesorgt hat. 
// das der lstm ebenfalls in unity einfach einzubinden war
// bissi was kochen halt

== Evaluationsprotokoll //FINN

=== Primaermetriken //FINN
// - Erfolgsrate (letzte 100 Episoden), Konvergenzgeschwindigkeit,
//   Kollisionsrate, Mean Episodenlaenge, Cumulative Reward

=== Generalisierungsmetriken //FINN //können wir erst nach ergebniss machen
// - Held-out Maps (nie im Training gesehen); Overfitting-Index
//   = Trainings-Erfolgsrate − Generalisierungs-Erfolgsrate
// 

=== Statistische Auswertung //FINN //können wir erst nach ergebniss machen, 
// - Mann-Whitney U, Bonferroni (α' = 0.005), Cliff's Delta,
//   95%-Bootstrap-Konfidenzintervalle


// ============================================================================
// 6. MODELLARCHITEKTUREN  — die konkrete Antwort auf die Frage aus 2.4
//katya, Finn, Alex ============================================================================
= Modellarchitekturen

== MLP-Baseline //katya

// - Standard ML-Agents: 2 Hidden-Layer, 256 Units, direkt auf Observation
// - mlp_baseline_v2: +0.81 Reward (2 Mio. Steps, 10 Agents)

== LSTM-Memory (Custom Policy)//ALEX

// - hidden_size 64, num_layers 1; ~82k Parameter
// - Patch-Strategie: additive elif-Bloecke in mlagents NetworkBody
// - Output-Shape GAE-kompatibel

== Transformer-Memory (Custom Policy)//FINN

// - d_model 256, nhead 4, num_layers 2; gelerntes Positional Encoding
// - manuelle MultiheadAttention, batch_first = False; ~1,07 Mio. Parameter
// - (Bau-/Debugging-Prozess: siehe 7.6)



// ============================================================================
// 7. UMSETZUNG NACH MEILENSTEINEN  (mit Kernabschnitt 7.6)
//Hauptteil ALEX, kleine teile katya und finn ============================================================================
= Umsetzung
// wie das System entstanden ist

== Umgebung: Datenmodell, Layouts und prozedurale Generierung
// Quelle: frueher M1-2 ZUSAMMENGEFUEHRT mit M6-Generierung.

// - Datenmodell der Karte: [was speichert es? warum diese Struktur?]
// - 5 manuell entworfene Layouts: [wozu? Baseline / Referenz / Test?]
// - Custom Editor (Preview): [welches Problem loeste er?]
// - Prozedurale Generierung:
//     - variable Grid-Groesse (BORDER = 2) [warum prozedural statt
//         weiter manuell? welche Rolle hat BORDER = 2?]
//     - Terminal-Korridore (echte Sackgassen) [warum noetig?]
// - Schwierigkeitsgrade Easy/Medium/Hard (DifficultySettings.Factory)
//     [welche Parameter variieren? wodurch unterscheiden sie sich?]
//
// TODO: pro Punkt das "Warum" ergaenzen.


== Hindernis- und Terminierungslogik
// Quelle: frueher M4.
//
// - Tag-basierte Hindernisse: Lava, Hole, Bridge, KillZone
//     [warum tag-basiert? welche Alternative wurde verworfen?]
// - Lava-Trigger-Plate: [wie funktioniert der Trigger? warum Plate?]
// - Hole-Mechanik (HoleSurface-Layer, KillZone):
//     [wie greifen Layer und KillZone ineinander?]
//
// QUERVERWEIS: die "zentrale Reward-Vergabe" ist eng an diese
//   Todeslogik gekoppelt, steht aber jetzt unter "Belohnungsdesign"
//   (siehe ENTSCHEIDUNG dort). Falls hier besser aufgehoben:
//   den einen Punkt zurueckverschieben.


== Agent und Wahrnehmung
// Quelle: frueher M3.
//
// - Agent-Klasse LabyrinthAgent.cs
//     (Initialize / OnEpisodeBegin / CollectObservations / ...)
//     [Aktionsraum? Beobachtungsraum? was passiert je Lifecycle-Hook?]
// - RayPerceptionSensor3D: [was erfasst er? warum dieser Sensor?]
// - Boden-Sensor: [welche Information? welches Verhalten ermoeglicht er?]
// - Sprungkalibrierung: [Ziel? welches Problem ohne sie?]
//
// TODO: Dateiname LabyrinthAgent.cs im Fliesstext sparsam nennen,
//   nicht als Ueberschrift der Darstellung.


== Belohnungsdesign
// Designentscheidung und ihre Wirkung (Achtung ABgrenzung 4.6)
// Quelle: frueher M5 (Reward-Anteil) + zentrale Reward-Vergabe aus M4.

//   -> Kopplung an Todeslogik per Querverweis oben markiert.
//
// - zentrale Reward-Vergabe: [warum zentral statt verteilt in den
//     Hindernis-Skripten? welchen Vorteil bringt das?]
// - Reward-Strategie: [welche Signale? Shaping vs. sparse? warum?]
// - YAML-Config: [welche zentralen Hyperparameter? Begruendung der Werte?]
// - Multi-Area: [warum mehrere Areas? Effekt aufs Training?]


== Training und Curriculum
// Quelle: frueher M5 (Training/Ergebnisse) + M6-Curriculum.
//
// - Trainingsaufbau: TensorBoard verifiziert
//     [was wurde ueberwacht? welche Metriken?]
// - Curriculum (CurriculumConfig + CurriculumTracker):
//     [welche Stufen? welches Kriterium fuer den Uebergang? warum?]
//



== Transformer-Integration: von V1 bis zum lauffaehigen Modell //FINN

// - KERNLEISTUNG, prominent: der 22-fach dokumentierte, messgetriebene
//   Integrationsprozess. Nach PROBLEMKLASSEN geordnet (nicht rein chronologisch),
//   die Chronologie lebt in der verdichteten Tabelle (7.6.5).

=== Warum kein Fork: der venv-Patch-Ansatz

// - additive elif-Bloecke im mlagents NetworkBody statt Fork
// - Patch-Skript idempotent + --undo; Argument: Wartbarkeit

=== Warum kein Pre-Trained Modell

// s. Heistermann Email shit....

=== Problemklasse A - Framework-/Engine-Workarounds

// - manuelle MultiheadAttention (Workaround PyTorch-2.0-CUDA-Segfault)
// - batch_first = False (Workaround ONNX-Export-Bug)

=== Problemklasse B - Inference/Training-Konsistenz

// - PPO-Ratio-Inkonsistenz: Inference (seq=1) != Training (seq=8)
// - Loesung: Rolling-Memory-Buffer (letzte 7 MLP-Encodings) -> konsistente
//   Log-Probs, gueltige PPO-Ratio

=== Problemklasse C - Reward-/Curriculum-Pathologien

// - Sparse Reward (Goal in 1 Mio. Steps nie gefunden) -> Trivial-Phase + PBRS
//   + Distanz-Observation
// - Wall-Climb (PhysX-Depenetration) -> Guard + maxUpwardVelocity-Cap
// - Eck-Heuristik/Memorierung -> zufaellige Goal-Platzierung
// - PBRS farmbar; Discount-Faktor entscheidend

=== Iterationsuebersicht V1-V22 (verdichtete Tabelle)

// - Tabelle: Version | Hypothese/Aenderung | Kennzahl-Wirkung (belegt) | Erkenntnis
// - vollstaendige Tabelle + Einzel-Kennzahlen (TensorBoard-Belege) im Anhang
// - Auszug bekannter Iterationen:
//     V5  kein Causal Mask -> kein Lernen
//     V6  Beta zu hoch, Entropy faellt nicht
//     V7  Value Loss kollabiert (Buffer zu klein)
//     V8  Buffer 40960, Time Horizon 256
//     V9  8.7 Mio. Steps, Plateau Reward 8.9 (Timeout-Stagnation)
//     V10 goalReward 10, stepPenalty −0.005, Success-Rate-Logging
//     V11 agent-relative Bewegung + Dreh-Action, seq_length 8 -> 16
//     V12 timeoutPenalty −2, Lava-Adrenalin-Reward
//     V13 γ = 0.997, goalReward 30, Curiosity-Modul, curriculum-aware MaxStep
//     ... bis V22 (spaetere Iterationen ggf. nur auf Branch milestone-7)

== LSTM-Integration //ALEX

// da weiß ich jetzt leider nicht so viel wie es da mit verisonen und so aussieht muss alex machen

== MLP-Integration //Katya
// weiß ich auch nciht muss katja sagen
// Hier aber darauf hinweisen das der aufwand asynchron ist zu den anderen (und das kurz begründen (weil es halt in unity direkt integriert ist, es der leichteste ist etc.))

// ============================================================================
// 8. EVALUATION UND ERGEBNISSE  — nur FINALE Vergleiche (keine Doppelung mit 7.6)
//DAVID ============================================================================
= Evaluation

// HINWEIS: finale vollstaendige Laeufe 
// ggf. noch nicht abgeschlossen -> Zwischenergebnisse kennzeichnen.

== MLP-Baseline



== Architektur-Vergleiche

// nach metriken vergleichen (keine ahnung trainingsgeschwindigkeit erfolgsrate und so kp)

== Generalisierung auf held-out Maps

// - 3 unabhaengige Eval-Maps; Erfolgs-/Kollisionsrate, Overfitting-Index

== Statistische Auswertung

// - Mann-Whitney U + Bonferroni, Cliff's Delta, Bootstrap-CI, Lernkurven mit CI-Band

== Diskussion

// - Bewertung H1-H4; welche Architektur lernt schneller / generalisiert besser
// - Beobachtetes Verhalten (Wall-Hugging, Lava-Avoidance, PBRS-Artefakte)


// ============================================================================
// 9. UEBERTRAGBARKEIT UND PRAKTISCHE ANWENDBARKEIT  (verweist zurueck auf 1.1/1.2)
//FINN ============================================================================
= Uebertragbarkeit und praktische Anwendbarkeit

== Analogie Labyrinth <-> reale Navigationsszenarien

// - Rueckgriff auf die Rahmung aus 1.1/1.2 (nicht neu einfuehren, auswerten)
// - Serviceroboter, Lager-/Indoor-Logistik, Spiele-NPCs

== Hardware- und Software-Anforderungen

// - Ray-only (CPU, niedrige Kosten) / Kamera (GPU) / Multi-Sensor (robust, teuer)
//das schreibt uns claude dann
== Bewertungsmatrix

// - Kriterien x Gewichte x Agenten; Empfehlung je Einsatzszenario
// -  Gewichte müssen begründet werden 

== Limitationen der Uebertragbarkeit

// - 2D-Abstraktion, statische Hindernisse, Sim-to-Real-Gap, idealisierte Sensorik


// ============================================================================
// 10. FAZIT UND AUSBLICK
//KATYA ============================================================================
= Fazit und Ausblick

== Zusammenfassung

// - Gebaut: 3D-Labyrinth, prozedurale Generierung, Curriculum, Custom-LSTM,
//   Custom-Transformer, Multi-Area, vollstaendige Evaluations-Pipeline

== Beantwortung der Forschungsfragen

// - RQ1 Sensortyp, RQ2 Temporal-Architektur, RQ3 Sensor-Fusion,
//   RQ4 praktische Uebertragbarkeit

== Limitationen und Lessons Learned
// Verweis auf 9.4 (limitation übertragbarkeit) sonst übertragbarkeit nur kurz erwähnen dann verweis.
// - PPO + Transformer: Inference/Training-Konsistenz nicht trivial
// - PBRS nuetzlich aber farmbar; Discount-Faktor entscheidend
// - Curriculum: Phasenwechsel als Stress-Test; Reward Engineering sensibel

== Ausblick

// - Vollstaendige Trainingsmatrix; CNN-/Multi-Sensor-Pfad (M8-M10)
// - Dynamische Hindernisse, Multi-Agent, Sim-to-Real


// ============================================================================
// ANHANG (in appendix.typ)
// ============================================================================
// - YAML-Konfigurationen: identische Basis + je Agent MARKIERTE Abweichungen
//   (stuetzt 5.3.2 "Notwendige YAML-Abweichungen")
// - Vollstaendige Iterationstabelle V1-V22 mit TensorBoard-Belegen
//   (stuetzt 7.6.5)
// - Reward-Tabelle (vollstaendig)
// - Uebersicht aller bearbeiteten Issues (#2 - #134)
// - Hardware-/Software-Stack
// - Repository-Struktur


