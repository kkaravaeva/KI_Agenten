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

// - Hochreiter & Schmidhuber (1997)
// - Gates: Forget / Input / Output
// - Implizites Gedächtnis ohne expliziten Sequenz-Buffer
// - In ML-Agents standardmäßig verfügbar (use_recurrent: true)

=== Transformer-Architektur

// - Vaswani et al. (2017): Attention is All You Need
// - Self-Attention, Multi-Head-Attention, Positional Encoding
// - Anwendung im RL-Kontext: Decision Transformer (Chen 2021), GTrXL (Parisotto 2020)
// - Vor- und Nachteile gegenüber LSTM
// - Quelle: Dokumentation/Transformer_Integration.md, Dokumentation/LSTM_Integration.md

== Wahrnehmung in RL-Agenten

// - Sensortypen: Ray-Sensoren, Kamera (CNN), Vector-Observations
// - Beobachtungsräume und Normalisierung
// - Quelle: Dokumentation/ArtenSensoren.md

== Unity ML-Agents Toolkit

// - Architektur: Unity-Environment ↔ Python-Trainer (gRPC)
// - Komponenten: Agent, Behavior Parameters, Decision Requester, Sensor Components
// - Trainings-Workflow: YAML-Config, ONNX-Export, TensorBoard-Integration
// - Version 0.30.0 (Release-Stand des Projekts)
// - Quelle: Dokumentation/MlAgents.md


// ============================================================================
// 3. STAND DER TECHNIK / VERWANDTE ARBEITEN
// ============================================================================
= Stand der Technik //Katja

// - Klassische Pathfinding-Algorithmen (A*, Dijkstra) vs. RL-Navigation
// - RL-basierte Navigation: DeepMind Atari (Mnih et al. 2015), AlphaGo,
//   Habitat / AI2-THOR (Embodied AI), CARLA (autonomes Fahren)
// - Memory-augmented RL: Differentiable Neural Computer, GTrXL
// - Curriculum Learning in RL (Bengio 2009)
// - Procedural Content Generation für RL-Training (Justesen et al. 2018)


// ============================================================================
// 4. METHODIK UND EXPERIMENTELLES DESIGN
// ============================================================================
= Methodik

== Wissenschaftliche Rahmung //Finn

// - Forschungsfragen RQ1–RQ4
// - Hypothesen H1–H4 (Multi-Sensor-Vorteil, Transformer-bei-Kamera,
//   Ray-Konvergenz, Beste-Gesamtkonfiguration)

== Agenten-Matrix und Vergleichsdesign //David

// - Tabellarische Übersicht der Agenten-Konfigurationen:
//     Baseline (Ray + MLP)
//     A3 Ray + LSTM        A4 Ray + Transformer
//     A1 Kamera+CNN+LSTM   A2 Kamera+CNN+Transformer
//     A6 Multi+CNN+LSTM    A5 Multi+CNN+Transformer
// - Paarweise Vergleiche: Architektur innerhalb je Sensorgruppe,
//   Sensortyp-übergreifend, gegen MLP-Baseline

== Kontrollierte Variablen //Alex

// - Identische Hyperparameter über alle Agenten:
//   Trainingsschritte, Reward-Struktur, Map-Algorithmus, PPO-Parameter,
//   5 unabhängige Seeds (42, 123, 456, 789, 1337)

== Evaluationsprotokoll //David

=== Primärmetriken
// - Erfolgsrate (Success Rate über letzte 100 Episoden)
// - Konvergenzgeschwindigkeit (Steps bis 80 % Erfolgsrate)
// - Kollisionsrate (Anteil Episoden mit Lava-/Hole-Tod)
// - Mean Episodenlänge
// - Cumulative Reward (TensorBoard)

=== Generalisierungsmetriken
// - Held-out Maps (3 fixe Eval-Maps, nie im Training gesehen)
// - Overfitting-Index = Trainings-Erfolgsrate − Generalisierungs-Erfolgsrate

=== Statistische Auswertung
// - Mann-Whitney U Test (nicht-parametrisch)
// - Bonferroni-Korrektur (α' = 0.005 bei 10 paarweisen Vergleichen)
// - Cliff's Delta als Effektgröße
// - 95 % Bootstrap-Konfidenzintervalle


// ============================================================================
// 5. SYSTEMARCHITEKTUR UND UMGEBUNG 
// ============================================================================
= Systemarchitektur //Finn

== Gesamtüberblick

// - Komponentendiagramm: Unity-Editor / Build ↔ Python-Trainer ↔ TensorBoard
// - Code-Layout: Assets/Scripts/{Map, Agent, Camera}, training/, config/, results/
// - Quelle: Dokumentation/Architektur.md

== Map-System

=== Datenmodell
// - CellType-Enum (Empty, Floor, Wall, Obstacle, Goal, SpawnPoint)
// - MapData (ScriptableObject, flaches Array, GetCell/SetCell)

=== MapGenerator (Runtime)
// - Layout-basierte Generierung mit Prefab-Mapping
// - Spawn-/Goal-/Obstacle-Platzierung dynamisch zur Laufzeit
// - BFS-Pfadvalidierung (Lösbarkeit garantiert)
// - Konfigurierbare Modi: SpawnPlacementMode, GoalPlacementMode,
//   ObstaclePlacementMode (Random vs. Predefined)
// - MapSelectionMode: Fixed / Random / Sequential / Curriculum
// - Multi-Area-Setup (4–10 parallele TrainingAreas)
// - Tile-Pool (Performance-Optimierung)

=== Prozedurale Map-Generierung
// - RoomCorridorGraph: 2-Tile-Korridore, Wand-Saum, BORDER-Pufferzone
// - ObstacleClusterPlacer: Cluster aus Lava/Hole/Platform
// - SemanticPathfinder: Lösbarkeitscheck mit Sprung-/Plattform-Semantik
// - Schwierigkeitsgrade (Trivial → TrivialCorr → TrivialBranch → TrivialHole
//   → TrivialHazard → Easy → Medium → Hard)
// - Quelle: Dokumentation/Prozedurale_Map_Generierung.md

== Agent-System

=== Aktionsraum
// - 3 Branches: Bewegung (idle/vor/zurück), Rotation (idle/links/rechts), Sprung
// - Agent-relative Bewegung (V11-Refactoring): konsistentes Bezugssystem für
//   Sensorik, Zielvektor und Aktionen

=== Observation-Space
// - VectorSensor (14 Floats):
//     · Eigengeschwindigkeit lokal (3)
//     · isGrounded (1)
//     · Zielrichtung lokal (3)
//     · Boden-Sensor (3 × 2 = 6)
//     · normalisierte Distanz zum Goal (1)  [V12: PBRS-Observation]
// - RayPerceptionSensor3D (automatisch, 11 Rays × 2 Frames × 6 Tags + 2 Werte)

=== Bewegungs- und Sprungphysik
// - Rigidbody-basiert mit MovePosition / MoveRotation / AddForce
// - Sprungkalibrierung: 1-Zellen-Lücke überspringbar, 2-Zellen nicht
// - Wall-Climb-Guard und maxUpwardVelocity-Cap (V11/V12-Fix)

=== Third-Person-Kamera
// - Smooth-Follow in LateUpdate, in lokalem Agent-Raum
// - Quelle: ThirdPersonCamera.cs

== Sensorik

// - Horizontaler RayPerceptionSensor: 11 Rays, 120°, 12 Zellen Reichweite,
//   Stacked = 2 für implizite Bewegungserkennung
// - 6 Detectable Tags: Wall, Obstacle, Lava, Hole, Goal, Bridge
// - Manueller Boden-Sensor: 3 Raycasts (unter, +1, +2 in Bewegungsrichtung)
//   mit Typ-Codes (Floor +1, Bridge +0.5, Hole −0.5, Lava −1, Abgrund −1.5)

== Reward-System

// - Formale Reward-Funktion:
//     R = goalReward · 𝟙[Ziel] + lavaPen · 𝟙[Lava] + holePen · 𝟙[Hole]
//         + timeoutPen · 𝟙[Timeout] + stepPenalty · T + R_PBRS
// - Aktuelle Werte (V13): goalReward = +30, lava/hole = −1, timeout = −5,
//   stepPenalty = −0.001 (curriculum-aware MaxStep)
// - PBRS (Potential-Based Reward Shaping): F = (prevDist − γ · currDist) · scale
// - Curiosity-Modul (V13, strength = 0.05) für Exploration in Lava-Phasen
// - Quelle: Dokumentation/Reward_Strategie.md

== Trainingsinfrastruktur

// - Python venv (mlagents 0.30.0, PyTorch 2.0.1+cu118)
// - Patch-Skript (training/patch_mlagents.py) für Custom-Policies
// - Multi-Area-Training (4–16 Areas pro Unity-Instanz)
// - Headless-Parallelisierung (6 Unity-Instanzen × 16 Areas = 96 Agents)
// - Hardware: RTX 3050 Laptop GPU, Ryzen 5 5625U


// ============================================================================
// 6. MODELLARCHITEKTUREN 
// ============================================================================
= Modellarchitekturen

== MLP-Baseline //Katja 
// - Standard ML-Agents Setup: 2 Hidden-Layer, 256 Units
// - Direkt auf konkatenierten Observation-Vektor
// - Trainingsergebnis Milestone 5: mlp_baseline_v2 erreicht +0.81 Reward
//   (2 Mio. Steps, 10 parallele Agents)

== LSTM-Memory (Custom Policy) //Alex

// - hidden_size = 64, num_layers = 1, batch_first = True
// - 82 432 Parameter
// - Patch-Strategie: additive elif-Blöcke in mlagents NetworkBody
// - Output-Shape [batch·seq_len, output_size] — GAE-kompatibel
// - Quelle: Dokumentation/LSTM_Integration.md

== Transformer-Memory (Custom Policy) //Finn

=== Architektur
// - d_model = 256, nhead = 4, num_layers = 2
// - Gelerntes Positional Encoding via nn.Embedding + register_buffer
// - Manuelle MultiheadAttention (Workaround: PyTorch-2.0-CUDA-Segfault)
// - batch_first = False (Workaround: ONNX-Export-Bug)
// - ~1 070 000 Parameter

=== Rolling-Memory-Buffer (Fix v2)
// - Problem: Inference (seq_len=1) ≠ Training (seq_len=8) → PPO-Ratio inkonsistent
// - Lösung: memory-Tensor speichert letzte 7 MLP-Encodings;
//   Inference rekonstruiert vollständige 8-Step-Sequenz
// - Konsequenz: konsistente Log-Probs, gültige PPO-Ratio

=== Integration in ML-Agents
// - venv-Patch statt Fork (geringerer Wartungsaufwand)
// - Patch-Skript idempotent + --undo-Option
// - Quelle: Dokumentation/Transformer_Integration.md



// ============================================================================
// 7. UMSETZUNG NACH MEILENSTEINEN
// ============================================================================
= Umsetzung //Alex

== Milestones 1–2: Map-System und Mehrere Layouts

// - Datenmodell (CellType, MapData, MapGenerator)
// - 5 manuell entworfene Layouts (25×30 und 18×30)
// - Custom Editor (MapGeneratorEditor) mit Preview-Buttons
// - Issues #2, #3, #4, #19, #20, #39–#44

== Milestone 3: Agent-Grundsystem

// - LabyrinthAgent.cs: Initialize / OnEpisodeBegin / CollectObservations /
//   OnActionReceived / Heuristic
// - RayPerceptionSensor3D-Konfiguration (11 Rays, 120°)
// - Boden-Sensor (manuelle Raycasts)
// - Sprungkalibrierung (jumpForce 3.5, moveSpeed 2)
// - Issues #21–#36

== Milestone 4: Hindernisse und Todeslogik

// - Tag-basierter Ansatz: Lava, Hole, Bridge, KillZone (keine neuen CellTypes)
// - Lava-Prefab als IsTrigger-Plate (flach, kalibrierte Trigger-Höhe)
// - Hole-Mechanik: HoleSurface-Layer, Physics-Matrix-Trick, KillZone unter der Map
// - Zentrale Reward-Vergabe in LabyrinthAgent.OnTriggerEnter
// - Konfigurierbare Penalties: lavaDeathPenalty, holeDeathPenalty
// - Issues #82–#88

== Milestone 5: Reward-System und erstes Training

// - Reward-Strategie (Reward_Strategie.md): goalReward, deathPenalty,
//   stepPenalty, MaxStep = 2500
// - YAML-Konfiguration (config/labyrinth_training.yaml)
// - Multi-Area-Setup (4–10 parallele Areas)
// - TensorBoard-Integration verifiziert
// - mlp_baseline_v1 (CPU) und mlp_baseline_v2 (GPU, 2 Mio. Steps, +0.81 Reward)
// - Bekannte Limitierung v2: Obstacles waren auf 0 gesetzt → Modell trainierte
//   ohne Hindernisse
// - Issues #93–#99

== Milestone 6: Prozedurale Generierung und Curriculum

// - Variable Grid-Größe mit 2-Tile-Pufferzone (BORDER = 2)
// - Terminal-Korridore (echte Sackgassen mit Hole am Ende)
// - Adaptive Korridorlängen, Coverage-Check, Multi-Cluster-Bug-Fix
// - Drei Schwierigkeitsgrade (Easy/Medium/Hard) per DifficultySettings.Factory
// - Curriculum-System: CurriculumConfig (ScriptableObject) +
//   CurriculumTracker (static), synchronisierter Phasenwechsel
// - Issues #127, #133, #134

== Milestone 7: Transformer- und LSTM-Integration

// - Custom Transformer Policy via venv-Patch (Issue #113)
// - Custom LSTM Policy als direkte Baseline (Issue #131)
// - Trivial-Layouts (7×7 ohne Hindernisse) + erweiterte Trivial-Familie
//   (TrivialCorr, TrivialBranch, TrivialHole, TrivialHazard)
// - Curriculum-Erweiterung auf 8 Phasen (Trivial → ... → Hard)

=== Iterative Fehlerdiagnose und Fixes

// - Bug 1: PPO-Ratio-Inkonsistenz Transformer (Inference seq=1, Training seq=8)
//          Fix: Rolling Memory Buffer
// - Bug 2: Sparse Reward (Agent fand Goal in 1 Mio. Steps nie)
//          Fix: Trivial-Phase + PBRS-Shaping + Distanz-Observation
// - Wall-Climb (Bug 3): PhysX-Depenetration schleudert Agent nach oben
//          Fix: Wall-Climb-Guard + maxUpwardVelocity-Cap
// - Eck-Heuristik (Bug 4): nur 4 Trivial-Konfigurationen → Memorierung
//          Fix: zufällige Goal-Platzierung in Trivial-Maps
// - Goal-Collider halb im Boden (Bug 5)
//          Fix: y-Offset 0.5 in MapGenerator.CellToWorld für Goal
// - Quelle: Dokumentation/Trainingsanalyse_Transformer_Milestone7.md

=== Trainings-Iterationen V5–V13

// - V5: kein Causal Mask → kein Lernen
// - V6: Beta zu hoch, Entropy fällt nicht
// - V7: Value Loss kollabiert (Buffer zu klein)
// - V8: größerer Buffer (40960), Time Horizon 256
// - V9: 8.7 Mio. Steps, Plateau bei Reward 8.9, Episode Length 1199 (Timeout-Stagnation)
// - V10: goalReward 10, stepPenalty −0.005, Success-Rate-Logging
// - V11: Agent-relative Bewegung + Dreh-Action, sequence_length 8 → 16
// - V12: timeoutPenalty −2, Lava-Adrenalin-Reward (Diminishing Returns)
// - V13: γ = 0.997, goalReward 30, Curiosity-Modul, curriculum-aware MaxStep


// ============================================================================
// 8. EVALUATION UND ERGEBNISSE
// ============================================================================
= Evaluation

// HINWEIS: Stand Mai 2026 sind die finalen vollständigen Trainingsläufe
// für die Vergleichsmatrix (5 Mio. Steps × 5 Seeds × 7 Agenten) noch
// nicht abgeschlossen. Dieses Kapitel enthält die bisherigen Zwischenergebnisse
// und wird im weiteren Projektverlauf ergänzt.

== MLP-Baseline (Milestone 5)

// - 2 Mio. Steps, 10 Agents, RTX 3050
// - Reward-Konvergenz von −2.4 → +0.81 nach ~1.4 Mio. Steps
// - Vergleich v1 (CPU, 4 Agents) vs. v2 (GPU, 10 Agents)
// - Trainingsdauer ~1h 44min

== Transformer- und LSTM-Iterationen (Milestone 7)

// - Reward-Verläufe V5–V13 mit Diagnose
// - Quantitative Diagnose: Entropy, Policy Loss, Value Loss, Reward, Episode Length
// - Beobachtung: Erfolgreiches Lernen auf Trivial → TrivialHole
//   Stagnation bei TrivialHazard und Easy-Maps (Diagnose: Discount-Faktor +
//   PBRS-Pathologie + Avoidance-Transfer)

== Paarweise Architektur-Vergleiche

=== Ray-Gruppe: LSTM (A3) vs. Transformer (A4)
// - geplant nach Milestone 7

=== Kamera-Gruppe: LSTM (A1) vs. Transformer (A2)
// - geplant Milestone 9

=== Multi-Sensor-Gruppe: LSTM (A6) vs. Transformer (A5)
// - geplant Milestone 10

== Generalisierung auf held-out Maps

// - 3 unabhängige Evaluations-Maps (Recursive Backtracking, Cellular Automata,
//   Room-Placement)
// - Erfolgsrate, Kollisionsrate, Overfitting-Index pro Agent

== Statistische Auswertung

// - Mann-Whitney U + Bonferroni
// - Cliff's Delta
// - Bootstrap-Konfidenzintervalle
// - Lernkurven-Plots mit CI-Band

== Diskussion

// - Bewertung der Hypothesen H1–H4
// - Welche Architektur lernt schneller, welche generalisiert besser?
// - Beobachtetes Verhalten (Wall-Hugging, Lava-Avoidance, PBRS-Artefakte)


// ============================================================================
// 9. ÜBERTRAGBARKEIT UND PRAKTISCHE ANWENDBARKEIT //Katja
// ============================================================================
= Übertragbarkeit und praktische Anwendbarkeit

== Analogie Labyrinth ↔ reale Navigationsszenarien

// - Generische Szenarien (Serviceroboter, Lager-/Indoor-Logistik, Spiele-NPCs)
// - Mapping-Tabelle: Korridor → Gang, Lava → Stufe/Kabel, prozedurales Layout
//   → veränderliches Umgebungs-Layout

== Hardware- und Software-Anforderungen

// - Ray-only: Ultraschall/LiDAR, CPU-tauglich, niedrige Kosten
// - Kamera: RGB-Kamera, GPU empfohlen, mittlere Kosten
// - Multi-Sensor: höchste Robustheit, höchste Kosten

== Bewertungsmatrix

// - Kriterien × Gewichte × Agenten
// - Empfehlung je Einsatzszenario

== Limitationen der Übertragbarkeit

// - 2D-Abstraktion, statische Hindernisse, Sim-to-Real-Gap, idealisierte Sensorik


// ============================================================================
// 10. FAZIT UND AUSBLICK //Alex
// ============================================================================
= Fazit und Ausblick

== Zusammenfassung

// - Was wurde gebaut: 3D-Labyrinth, prozedurale Generierung, Curriculum,
//   Custom-LSTM, Custom-Transformer, Multi-Area-Training, vollständige
//   Evaluations-Pipeline

== Beantwortung der Forschungsfragen

// - RQ1 Sensortyp
// - RQ2 Temporal-Architektur
// - RQ3 Sensor-Fusion
// - RQ4 Praktische Übertragbarkeit

== Limitationen und Lessons Learned

// - PPO + Transformer: Inference/Training-Konsistenz nicht trivial
// - PBRS: nützlich, aber farmbar; Discount-Faktor entscheidend
// - Curriculum Learning: Phasenwechsel sind Stress-Test für gelernte Policies
// - Reward Engineering: kleine Werte mit großem Einfluss

== Ausblick

// - Vollständige Trainingsmatrix (5 Mio. Steps × 5 Seeds × 7 Agenten)
// - CNN-Pfad und Multi-Sensor-Fusion (M8–M10)
// - Dynamische Hindernisse, kooperatives Multi-Agent-Setup
// - Sim-to-Real-Transfer auf physischen Roboter


// ============================================================================
// ANHANG (in appendix.typ verschoben)
// ============================================================================
// - YAML-Konfigurationen (labyrinth_training.yaml,
//   labyrinth_transformer.yaml, labyrinth_lstm.yaml)
// - Reward-Tabelle (vollständig)
// - Übersicht aller bearbeiteten Issues (#2 – #134)
// - Hardware-/Software-Stack
// - TensorBoard-Screenshots (Lernkurven)
// - Repository-Struktur
