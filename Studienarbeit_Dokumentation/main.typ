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
/*
= Einleitung
// >>> AUFTEILUNG DIESES KAPITELS (ALT -> NEU):
//     "Motivation und Kontext"           -> SPLIT: 1.1 Restaurant | 1.2 Abstraktion(+Analogie) | 1.3 Generalisierung | 1.5 Forschungslücke
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

Reinforcement Learning (RL) bietet einen grundsätzlich anderen Ansatz: Anstatt einen optimalen Pfad auf einer vollständigen Karte zu berechnen, erlernt ein RL-Agent durch wiederholte Interaktion mit seiner Umgebung eine Verhaltensstrategie (Policy), die Beobachtungen auf Aktionen abbildet. Wissen über die Karte ist dabei nicht Voraussetzung, sondern das Resultat des Lernprozesses. Der Agent entwickelt implizit Navigationsstrategien, die auf seine Sensorinformationen zurückgreifen. Mit tiefen neuronalen Netzen als Funktionsapproximatoren (Deep RL) sind in den letzten Jahren bemerkenswerte Ergebnisse in komplexen Navigationsaufgaben erzielt worden @mnih_human-level_2015. Reinforcement Learning stellt einen vielversprechender Ansatz zur Lösung des autonomen Navigationsproblemes dar.
Die vorliegende Arbeit untersucht, welche neuronale Netzwerkarchitektur einem RL-Agenten besonders geeignet ist, um in einer prozedural generierten 3D-Labyrinthwelt zuverlässig von einem Startpunkt zu einem Ziel zu navigieren. Als Lernverfahren wird Proximal Policy Optimization @schulman_proximal_2017  eingesetzt, das sich als stabiler Standard für diskrete Aktionsräume in simulierten Umgebungen etabliert hat. Die Umgebung wird in Unity 6 (Version 6000.2.6f1) mithilfe des ML-Agents-Frameworks realisiert; begonnen wurde das Projekt unter Unity 2021.3, im Zuge des Aufbaus der Vergleichspipeline wurde auf Unity 6 aktualisiert.
== Problemstellung

// - Hauptforschungsfrage (Vergleichsformulierung wie 1.1 — kein Transformer-Fokus):
//   "Welche neuronale Netzwerkarchitektur (MLP, LSTM oder Transformer) ist für
//    einen RL-Agenten geeignet, um in einer prozedural generierten 3D-Labyrinthwelt
//    generalisierbares Navigations- und Hindernisvermeidungsverhalten zu erlernen,
//    das sich auf unbekannte Map-Layouts übertragen lässt?"
// - Forschungsfragen F1-F3 (temporales Gedächtnis · LSTM vs. Transformer ·
//   Generalisierung); Übertragbarkeit nur qualitativ in Kap. 9,
//   Sensorvergleich -> Ausblick Kap. 10
// - Hypothesen H1–H3 (gerichtet, zu F1–F3; in 1.x Forschungsfrage ausformuliert)
Das in dieser Arbeit betrachtete Navigationsproblem weist zwei Eigenschaften auf, die es von den Annahmen klassischer Pfadfindungsalgorithmen grundlegend unterscheiden.
Zum einen die partielle Observierbarkeit. Der Agent nimmt seine Umgebung über lokale Sensorik statt über eine globale Karte wahr. Kernstück ist ein Ray-Perception-Sensor: elf Raycasts, die in einem Winkel von 120° ausgesandt werden und beim Auftreffen auf erkannte Objekte (Wände, Hindernisse, Lava, Löcher, Ziel, Brücken) deren Typ und Entfernung zurückliefern; über zwei Zeitschritte gestapelt ergeben sie 176 Ray-Beobachtungen. Ergänzt wird diese Information durch einen 31-dimensionalen Handcoded-Vektor: 18 Werte eines nach unten gerichteten Boden-Sensors (9 Punkte mit je Typ-Code und Distanz), 3 Werte Eigengeschwindigkeit, 1 Bodenkontakt-Flag, 1 normalisierte Zieldistanz, 3 Werte Zielrichtung, 4 Wand-Raycasts und 1 Line-of-Sight-Flag. Der Agent besitzt zu keinem Zeitpunkt eine globale Karte seiner Umgebung. Das Navigationsproblem ist damit formal ein Partially Observable Markov Decision Process  (POMDP, Kaelbling et al., 1998 ): Der aktuelle Beobachtungsvektor allein identifiziert den Zustand der Welt nicht eindeutig.

Die zweite Eigenschaft sind Sackgassen und das Gedächtnisproblem. Partielle Observierbarkeit wird kritisch, wenn der Agent in eine Sackgasse gerät.
Ohne Erinnerung daran, welche Richtungen er bereits erfolglos versucht hat, verhält sich ein gedächtnisloser Agent in einer Sackgasse reaktiv: Er nimmt in jedem Timestep dieselben Ray-Werte wahr und trifft dieselbe Entscheidung(er dreht sich im Kreis oder wechselt zwischen zwei Positionen). Die Beobachtung „Wand links, Wand rechts, Wand vorne" ist ohne temporalen Kontext nicht von der Situation „Wand links, Wand rechts, Wand vorne, und ich bin gerade von hinten hereingekommen" zu unterscheiden. Ein Multilayer Perceptron (MLP) ohne temporales Gedächtnis ist strukturell außerstande, diese Unterscheidung zu treffen. Zwei gestapelte Beobachtungs-Frames (stacked = 2) und die permanent verfügbare Zielrichtungs-Observation entschärfen die partielle Observierbarkeit zwar lokal; eine Sackgassen-Rückverfolgung erfordert jedoch temporalen Kontext über deutlich mehr als zwei Timesteps — genau diese Lücke sollen LSTM und Transformer füllen.
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
// ANKERENTSCHEIDUNG (verbindlich): Das Fragensystem dieser Arbeit ist F1-F3.
// Die früheren RQ1 (Sensortyp) und RQ3 (Sensor-Fusion) sind KEINE Forschungsfragen
// mehr — sie verlangen einen Sensormodalitäts-Vergleich, der gestrichen wurde, und
// existieren nur noch als zurückgestellte Erweiterung im Ausblick (Kap. 10).
// Übertragbarkeit (früher RQ4) wird qualitativ in Kap. 9 diskutiert — ohne
// RQ-Label und ohne Metrik.
Aus der beschriebenen Problemstellung leiten sich drei Forschungsfragen ab, die in dieser Arbeit empirisch beantwortet werden:

F1: Mehrwert temporalen Gedächtnisses:

"Verbessert zeitliches Gedächtnis (LSTM bzw. Transformer) die Erfolgsrate eines RL-Agenten in partiell observierbaren Labyrinthwelten gegenüber einem gedächtnislosen MLP-Basisagenten?"

Diese Frage prüft die grundlegende Hypothese, dass temporale Kontextinformation für die betrachtete Aufgabe notwendig oder zumindest deutlich vorteilhaft ist. Gemessen wird die Erfolgsrate (Anteil erfolgreich abgeschlossener Episoden) in separaten Evaluationsläufen nach Trainingsabschluss; das vollständige Messprotokoll ist in Kapitel 5.5 definiert.

F2: Vergleich LSTM und Transformer:
"Unterscheiden sich LSTM und Transformer in ihrer Konvergenzgeschwindigkeit und ihrem finalen Leistungsscore bei Ray-basierter Labyrinth-Navigation?"

Diese Frage zielt auf die praktische Wahl zwischen den beiden Gedächtnisarchitekturen. Konvergenzgeschwindigkeit wird operationalisiert als die Anzahl Trainingsschritte bis zum nachhaltigen Überschreiten einer Erfolgsrate von 80 %; der finale Score wird als mittlerer kumulativer Episoden-Reward in separaten Evaluationsläufen erhoben. Die vollständigen Metrik-Definitionen folgen in Kapitel 5.5.

F3: Generalisierung auf unbekannte Maps:
"Welche der drei Architekturen (MLP, LSTM, Transformer) generalisiert am zuverlässigsten auf prozedural generierte Maps, die während des Trainings nie gesehen wurden?"

Generalisierung wird auf drei fixierten Evaluation-Maps gemessen, die vor Trainingsbeginn eingefroren und während des gesamten Trainings nicht verwendet wurden. Die Differenz zwischen Trainings- und Generalisierungs-Erfolgsrate dient als Overfitting-Index.

Die drei Forschungsfragen sind bewusst aufeinander aufbauend: F1 klärt, ob Gedächtnis prinzipiell nützt; F2 differenziert zwischen den Gedächtnistypen; F3 bewertet die praktische Robustheit der besten Konfiguration.

Zu den drei Forschungsfragen werden folgende gerichtete Hypothesen aufgestellt:
// TODO: Richtungen von H2/H3 ggf. gegen den Forschungsplan prüfen
H1 (zu F1): Agenten mit temporalem Gedächtnis (LSTM, Transformer) erreichen nach Trainingsabschluss eine höhere Erfolgsrate als der gedächtnislose MLP-Basisagent; der Unterschied zeigt sich insbesondere in Layouts mit Sackgassen.

H2 (zu F2): Der Transformer erreicht einen höheren finalen Leistungsscore als das LSTM, benötigt jedoch mehr Trainingsschritte bis zum nachhaltigen Überschreiten der 80-%-Erfolgsschwelle (langsamere Konvergenz).

H3 (zu F3): Architekturen mit temporalem Gedächtnis weisen einen geringeren Overfitting-Index auf als der MLP-Basisagent, generalisieren also zuverlässiger auf prozedural generierte Maps, die im Training nie gesehen wurden.
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
Sensorik: Ausschließlich Ray-basierte Wahrnehmung. Der Agent verwendet den RayPerceptionSensor3D von Unity ML-Agents in Kombination mit einem manuell kodierten VectorSensor. Kamerabasierte Beobachtungen (Pixel-Tensoren) und Multi-Sensor-Konfigurationen werden in dieser Arbeit nicht untersucht. Diese Einschränkung ist methodisch begründet: Erstens isoliert die einheitliche Ray-Sensorik aller Agenten die Wirkung der temporalen Architektur von der Wirkung des visuellen Encoders, denn bei Kamera-Agenten wäre unklar, ob beobachtete Unterschiede aus dem Temporal-Modul oder aus dem CNN-Modul stammen. Zweitens erlaubt die niedrigdimensionale Ray-Repräsentation (Float-Vektoren statt Pixel-Arrays) deutlich kürzere Trainingszeiten und damit eine höhere Anzahl vollständiger Experiment-Wiederholungen. Der ursprünglich erwogene Sensormodalitäts-Vergleich (Kamera, Sensor-Fusion) wird als zurückgestellte Erweiterung im Ausblick (Kapitel 10) wieder aufgegriffen.

 Als Trainingsalgorithmus wird Proximal Policy Optimization (PPO) verwendet. Alternative Verfahren wie Deep Q-Networks @mnih_human-level_2015 oder Soft Actor-Critic @haarnoja_soft_2018 werden nicht betrachtet. PPO bietet im Unity ML-Agents Framework nativen Support für LSTM-Architekturen; der Transformer-Support wurde im Rahmen dieser Arbeit durch einen Patch der Python-Trainingsumgebung nachgerüstet (Kapitel 7.6). PPO ist zudem als On-Policy-Verfahren mit diskreten Aktionsräumen besonders gut geeignet. DQN ist primär für Value-Based Learning ohne explizite Policy-Parametrisierung ausgelegt. SAC ist für kontinuierliche Aktionsräume optimiert.

Umgebung: Keine dynamischen Hindernisse. Das Labyrinth enthält ausschließlich statische Hindernisse: Wände, Lavafelder und Bodenlöcher. Pro Episode wird ein anderes, vorab prozedural generiertes und eingefrorenes Layout geladen; innerhalb einer Episode ist die Umgebung vollständig statisch. Bewegliche Hindernisse (rotierende Stacheln, patroullierende Gegner) würden die Komplexität der Aufgabe erheblich erhöhen und die Interpretation der Ergebnisse erschweren. Sie bleiben einer möglichen Weiterentwicklung vorbehalten.

Diese Einschränkungen sind keine Schwäche, sondern methodische Stärke des Designs: Die Kontrolle von Sensormodalität und Lernverfahren erlaubt es, beobachtete Leistungsunterschiede primär auf die temporale Architektur zurückzuführen. Ein strenger Kausalanspruch wird jedoch nicht erhoben, da sich die Trainingskonfigurationen der Architekturen in einzelnen Tuning-Parametern (u. a. learning_rate, batch_size, buffer_size, gamma, Curiosity-Stärke) unterscheiden; diese Abweichungen werden in Abschnitt 5.3 begründet und in Kapitel 10 als Limitation geführt.
== Aufbau der Arbeit //Optional (Arbeitspakete?)

// - Kurze Übersicht der Kapitel
*/


= Einleitung

//== Ausgangsszenario: Serviceroboter im Restaurant
== Motivation und Kontext

Autonome Serviceroboter gewinnen in Dienstleistungsbranchen zunehmend an Bedeutung. In Bereichen wie Gastronomie, Hotellerie und Gesundheitswesen werden sie als Möglichkeit betrachtet, wiederkehrende Service- und Transportaufgaben zu automatisieren sowie Mitarbeitende bei alltäglichen Tätigkeiten zu entlasten. Die Fortschritte in den Bereichen Robotik, Sensorik und künstliche Intelligenz eröffnen dabei neue Möglichkeiten für den praktischen Einsatz intelligenter Systeme @wirtz_brave_2018[S. 9 ff.].

Eine Voraussetzung für den erfolgreichen Einsatz solcher Systeme ist die Fähigkeit zur autonomen Navigation. Ein Serviceroboter muss seine Umgebung wahrnehmen, Hindernisse erkennen und selbstständig Entscheidungen treffen, um ein vorgegebenes Ziel sicher zu erreichen. Im Gegensatz zu klassischen regelbasierten Systemen sollen moderne Roboter dabei flexibel auf Veränderungen ihrer Umgebung reagieren können. Für die Entwicklung solcher Navigationsstrategien hat sich Reinforcement Learning (RL) als vielversprechender Ansatz etabliert. Agenten lernen durch Interaktion mit ihrer Umgebung eigenständig, welche Aktionen langfristig zu einer erfolgreichen Zielerreichung führen @sutton_reinforcement_2018[S. 1 - 8].

Die Untersuchung entsprechender Lernverfahren auf realen Robotersystemen ist jedoch mit erheblichem Aufwand verbunden. Neben den Kosten für Hardware und Sensorik können Fehlentscheidungen während des Trainings zu Beschädigungen der Umgebung oder des Roboters führen. Darüber hinaus sind reale Experimente häufig zeitaufwendig und nur eingeschränkt reproduzierbar. Aus diesem Grund werden neue Verfahren zunächst in Simulationsumgebungen entwickelt und evaluiert @juliani_unity_2020[S. 1 - 6].

Um die für diese Arbeit relevante Navigationsaufgabe systematisch untersuchen zu können, wird die reale Umgebung eines Restaurants in ein abstrahiertes Simulationsmodell überführt. Ziel dieser Abstraktion ist nicht die möglichst realitätsnahe Nachbildung eines Restaurants, sondern die Reduktion auf jene Eigenschaften, die für die Navigation eines autonomen Agenten wesentlich sind. Der Agent muss weiterhin Wege finden, Hindernisse vermeiden und ein Ziel erreichen. Gleichzeitig wird die Umgebung so vereinfacht, dass unterschiedliche Lernverfahren unter identischen Bedingungen untersucht und miteinander verglichen werden können.

Die Beziehung zwischen realem Anwendungsszenario und Simulationsmodell ist in Tabelle @tab_abstraktion dargestellt.

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

== Problemstellung

Die Fähigkeit eines Agenten, eine einzelne Trainingsumgebung erfolgreich zu durchlaufen, stellt noch keinen ausreichenden Nachweis für intelligentes Navigationsverhalten dar. Hohe Erfolgsraten können auch dann erreicht werden, wenn der Agent lediglich spezifische Kartenstrukturen oder Bewegungsabfolgen auswendig lernt. In diesem Fall wäre das erlernte Verhalten eng an die Trainingsumgebung gebunden und nur eingeschränkt auf neue Situationen übertragbar.

Für reale Anwendungen ist ein solches Verhalten jedoch unzureichend. Restaurants unterscheiden sich hinsichtlich ihrer Raumaufteilung, der Anordnung von Tischen und Laufwegen sowie möglicher Hindernisse. Darüber hinaus können sich diese Gegebenheiten während des Betriebs verändern. Ein autonomer Serviceroboter muss daher in der Lage sein, bereits erlernte Strategien auf unbekannte Umgebungen anzuwenden, anstatt ausschließlich bekannte Situationen wiederzuerkennen.

Diese Fähigkeit wird als Generalisierung bezeichnet. Im Kontext des Reinforcement Learnings beschreibt Generalisierung die Fähigkeit eines Agenten, auch in Umgebungen erfolgreich zu agieren, die während des Trainings nicht beobachtet wurden. Sie stellt eine zentrale Herausforderung moderner Lernverfahren dar, da eine gute Leistung auf Trainingsdaten nicht automatisch eine gute Leistung auf unbekannten Situationen garantiert @goodfellow_deeplearningbookorgcontentsmlhtml_nodate[S. 111 - 120].

Neben der Generalisierung spielt die Verarbeitung zeitlicher Zusammenhänge eine wichtige Rolle. Während sich einige Navigationsentscheidungen allein auf Basis der aktuellen Wahrnehmung treffen lassen, existieren auch Situationen, in denen Informationen aus vergangenen Beobachtungen relevant werden.

Klassische Feed-Forward-Netzwerke besitzen kein explizites Gedächtnis und treffen ihre Entscheidungen ausschließlich auf Grundlage der aktuellen Eingabe. Architekturansätze wie Long Short-Term Memory Networks (LSTM) oder Transformer-Modelle ermöglichen dagegen die Berücksichtigung vergangener Beobachtungen und könnten dadurch Vorteile bei komplexen Navigationsaufgaben bieten.

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
Da Generalisierung das zentrale Qualitätskriterium dieser Arbeit darstellt, muss ihre Bewertung objektiv und reproduzierbar erfolgen.
Um Generalisierung nachweisen zu können, muss die Leistung eines Agenten auf Umgebungen untersucht werden, die während des Trainings nicht beobachtet wurden. Nur unter dieser Voraussetzung lässt sich feststellen, dass das erlernte Verhalten auf neue Situationen übertragbar ist.

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

Darüber hinaus stellt sich die Frage, auf welcher Informationsgrundlage der Agent seine Entscheidungen trifft. Damit ein Agent zielgerichtet handeln kann, müssen relevante Eigenschaften der Umgebung erfasst und in einer für das neuronale Netzwerk verarbeitbaren Form bereitgestellt werden. Die konkrete Ausgestaltung der Wahrnehmung beeinflusst maßgeblich, welche Informationen dem Agenten während der Navigation überhaupt zur Verfügung stehen.

Eine weitere offene Fragestellung betrifft die Verarbeitung dieser Informationen. Während einige Navigationssituationen allein anhand der aktuellen Beobachtung lösbar sind, können in komplexeren Labyrinthstrukturen Situationen entstehen, in denen zusätzliche Kontextinformationen benötigt werden. Beispielsweise kann ein Agent in Sackgassen oder an mehrdeutigen Kreuzungen davon profitieren, Informationen aus vergangenen Beobachtungen in seine Entscheidungsfindung einzubeziehen.

Klassische Feed-Forward-Netzwerke treffen ihre Entscheidungen ausschließlich auf Basis der aktuellen Eingabe und verfügen über kein explizites Gedächtnis. Demgegenüber ermöglichen Architekturen wie Long Short-Term Memory Networks (LSTM) oder Transformer-Modelle die Berücksichtigung zeitlicher Zusammenhänge über mehrere Zeitschritte hinweg. Daraus ergibt sich die Vermutung, dass Gedächtnismechanismen insbesondere bei Navigationsaufgaben in partiell beobachtbaren Umgebungen einen Vorteil bieten könnten.

Vor diesem Hintergrund ergibt sich die zentrale Forschungsfrage dieser Arbeit:


"Welche neuronale Netzwerkarchitektur (MLP, LSTM oder Transformer) ist für einen Reinforcement-Learning-Agenten geeignet, um in einer prozedural generierten 3D-Labyrinthwelt generalisierbares Navigations- und Hindernisvermeidungsverhalten zu erlernen, das sich auf unbekannte Kartenlayouts übertragen lässt?"

Zur Beantwortung dieser Forschungsfrage werden die folgenden Teilfragen untersucht:

*F1: Mehrwert temporalen Gedächtnisses*

Verbessert ein temporaler Gedächtnismechanismus in Form eines LSTM- oder Transformer-Modells die Navigationsleistung eines Reinforcement-Learning-Agenten gegenüber einem gedächtnislosen MLP-Basisagenten?

*F2: Vergleich von LSTM und Transformer*

Welche Unterschiede zeigen LSTM- und Transformer-Architekturen hinsichtlich Lernverhalten, Trainingsdynamik und Leistungsfähigkeit bei der Ray-basierten Navigation in einer Labyrinthumgebung?

*F3: Generalisierung auf unbekannte Kartenlayouts*

Welche der untersuchten Architekturen (MLP, LSTM oder Transformer) generalisiert am zuverlässigsten auf prozedural generierte Karten, die während des Trainings nicht beobachtet wurden?

Die Teilfragen bauen logisch aufeinander auf. Zunächst wird untersucht, ob ein Gedächtnismechanismus für die betrachtete Navigationsaufgabe grundsätzlich einen Mehrwert bietet. Anschließend erfolgt ein direkter Vergleich der beiden Gedächtnisarchitekturen LSTM und Transformer. Abschließend wird analysiert, in welchem Umfang sich die erlernten Strategien auf bislang unbekannte Kartenlayouts übertragen lassen.

Zur Beantwortung der Forschungsfragen werden die folgenden Hypothesen aufgestellt:

*H1:* Agenten mit temporalem Gedächtnis (LSTM oder Transformer) erreichen eine höhere Navigationsleistung als ein gedächtnisloser MLP-Basisagent.

*H2:* Transformer-Architekturen erzielen eine höhere Endleistung als LSTM-Modelle, benötigen jedoch mehr Trainingsaufwand bis zur Konvergenz.

*H3:* Architekturen mit temporalem Gedächtnis weisen eine höhere Generalisierungsfähigkeit auf als ein MLP-Basisagent und zeigen ein geringeres Maß an Overfitting gegenüber den Trainingskarten.

Die Operationalisierung dieser Forschungsfragen sowie die zur Evaluation verwendeten Metriken und Auswertungsverfahren werden in Kapitel ? beschrieben





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
//   Generalisierung), Hypothesen H1-H3; Sensorfragen sind KEINE RQ mehr
//   (-> Ausblick Kap. 10), Übertragbarkeit qualitativ in Kap. 9
// In 1.5 nur die Haupt-Forschungsfrage plus F1-F3 als Fragen formulieren
// Vorwärtsverweis auf 5.1 setzen




== Zielsetzung und Abgrenzung

Ziel dieser Arbeit ist die Entwicklung und Evaluation einer Reinforcement-Learning-Umgebung zur Untersuchung generalisierbarer Navigationsstrategien in dreidimensionalen Labyrinthwelten. Hierzu wird auf Basis der Unity-Spielengine und des ML-Agents Toolkits eine Simulationsumgebung entwickelt, in der autonome Agenten lernen, ein Ziel zu erreichen und gleichzeitig verschiedene Hindernisse zu vermeiden.

Im Mittelpunkt der Untersuchung steht der Vergleich dreier unterschiedlicher neuronaler Netzwerkarchitekturen. Neben einem Multi-Layer-Perceptron (MLP) als gedächtnislose Baseline werden ein Long Short-Term Memory Network (LSTM) sowie ein Transformer-Modell implementiert und unter vergleichbaren Bedingungen trainiert. Die Leistungsfähigkeit der Architekturen wird anhand ihrer Navigationsleistung sowie ihrer Fähigkeit zur Generalisierung auf zuvor ungesehene Kartenlayouts bewertet.

Die entwickelte Umgebung umfasst eine Ray-basierte Wahrnehmung, verschiedene Hindernistypen wie Lavafelder, Löcher und Sackgassen sowie ein System zur prozeduralen Kartengenerierung. Durch die automatische Erzeugung unterschiedlicher Kartenlayouts können Trainings- und Testumgebungen voneinander getrennt werden, wodurch eine systematische Bewertung der Generalisierungsfähigkeit ermöglicht wird.

Zum Pflichtumfang der Arbeit gehören:

- die Entwicklung einer dreidimensionalen Labyrinthumgebung in Unity,
- die Implementierung eines Reinforcement-Learning-Agenten auf Basis von PPO,
- die Integration und Evaluation der Architekturen MLP, LSTM und Transformer,
- die Implementierung einer Ray-basierten Wahrnehmung,
- die Durchführung von Generalisierungstests auf zuvor ungesehenen Karten,
- die Dokumentation der Ergebnisse sowie die Bereitstellung einer reproduzierbaren Trainings- und Evaluationsumgebung.

Darüber hinaus werden mehrere Erweiterungen umgesetzt. Hierzu zählen insbesondere die prozedurale Kartengenerierung, Curriculum Learning zur schrittweisen Steigerung der Aufgabenschwierigkeit, Multi-Area-Training zur effizienteren Datensammlung sowie der direkte Vergleich unterschiedlicher Gedächtnisarchitekturen.

Von der Zielsetzung bewusst abgegrenzt werden Fragestellungen, die den Umfang dieser Arbeit überschreiten würden. Hierzu zählen insbesondere der Transfer der Ergebnisse auf reale Robotersysteme (Sim-to-Real), Mehragentenszenarien, dynamische Hindernisse, die Untersuchung unterschiedlicher Sensormodalitäten sowie die Entwicklung neuer Reinforcement-Learning-Algorithmen. Ebenso erfolgt keine quantitative Bewertung der Übertragbarkeit auf reale Serviceroboter. Diese wird stattdessen in Kapitel 9 qualitativ diskutiert.

Der Fokus der Arbeit liegt somit ausschließlich auf der Frage, welchen Einfluss unterschiedliche neuronale Netzwerkarchitekturen auf das Erlernen und die Generalisierung von Navigationsverhalten in einer kontrollierten Simulationsumgebung besitzen.


// - Pflichtumfang: 3D-Labyrinth, 5 Maps, Ray-Sensorik, Lava/Hole/Sackgassen,
//   Transformer als Kernmodell, MLP-Baseline, >= 1 Ablationsstudie,
//   Generalisierungstest, reproduzierbares Repo, Bericht + Video-Demos
// - Optionale, umgesetzte Erweiterungen: prozedurale Map-Generierung,
//   Curriculum Learning, LSTM-Vergleich, Multi-Area-Training
// - NICHT geleistet: Sim-to-Real, Multi-Agent, dynamische Hindernisse

== Aufbau der Arbeit

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
//     (NEU 2.4.1 Gedächtnisproblem: NEU/kurz; Motivation auch in 1.5)

== Künstliche Intelligenz
Künstliche Intelligenz (KI) bezeichnet den Bereich der Informatik, der sich mit der Entwicklung maschinenbasierter Systeme befasst, die Aufgaben ausführen können, die  menschliche Intelligenz erfordern, wie beispielsweise Problemlösung, Sprachverständnis oder Mustererkennung @bhagwan_comprehensive_2024[S. 276 ]
== Maschinelles Lernen und wichtige Methoden
Maschinelles Lernen (ML) ist ein Teilgebiet der KI und befasst sich mit der Entwicklung von Algorithmen, die aus Daten lernen und auf Grundlage dieser Daten Vorhersagen treffen  @bhagwan_comprehensive_2024[S. 276 f.]. Dabei müssen keine Entscheidungsregeln explizit programmiert werden, da diese während des Trainingsprozesses aus den vorhandenen Daten abgeleitet werden. Abhängig davon, welche Art von Daten dem Modell zur Verfügung stehen und wie der Lernprozess organisiert ist, lassen sich verschiedene Lernparadigmen unterscheiden. Zu den grundlegenden Ansätzen zählen Supervised Learning (überwachtes Lernen), Unsupervised Learning (unüberwachtes Lernen) und Reinforcement Learning (bestärkendes Lernen) @shaveta_review_2023[S. 282 f.].
=== Supervised Learning(überwachtes Lernen)
Beim überwachten Lernen (Supervised Learning) wird ein Modell anhand von annotierten Trainingsdaten trainiert. Jeder Eingabe ​$x_i$ ist dabei ein bekanntes Ziel $y_i$ zugeordnet. Das Ziel des Lernprozesses besteht darin, eine Funktion $f: X -> Y$ zu erlernen, die für neue, unbekannte Eingaben möglichst korrekte Vorhersagen liefert. Typische Anwendungsgebiete sind die Klassifikation, bei der Daten vordefinierten Klassen zugeordnet werden, sowie die Regression, bei der kontinuierliche Werte vorhergesagt werden @shaveta_review_2023[S. 282]. Der Lernfortschritt wird durch den Vergleich der Modellausgabe mit den bekannten Zielwerten bewertet und über geeignete Optimierungsverfahren verbessert.
=== Unsupervised Learning (unüberwachtes Lernen)
Im Gegensatz dazu stehen beim unüberwachten Lernen (Unsupervised Learning) keine Zielwerte oder Labels zur Verfügung. Das Modell erhält ausschließlich die Eingabedaten und versucht selbstständig, darin enthaltene Strukturen, Zusammenhänge oder Muster zu identifizieren. Häufige Verfahren sind das Clustering, bei dem ähnliche Datenpunkte zu Gruppen zusammengefasst werden, sowie die Dimensionsreduktion, die darauf abzielt, die wesentlichen Informationen eines Datensatzes in einer kompakteren Darstellung abzubilden @shaveta_review_2023[S. 283]. Unüberwachtes Lernen eignet sich insbesondere zur explorativen Datenanalyse und zur Entdeckung bisher unbekannter Strukturen.
=== Reinforcement Learning (bestärkendes Lernen)
Das für diese Arbeit
zentral relevante Verfahren ist das bestärkende Lernen (Reinforcement Learning, RL). Dieses verfolgt einen anderen Ansatz. Hier interagiert ein Agent fortlaufend mit einer Umgebung und trifft Entscheidungen in Form von Aktionen. Für diese Aktionen erhält er ein Feedback in Form eines sogenannten Reward-Signals. Anders als beim überwachten Lernen werden dem Agenten keine direkten Korrekturen für einzelne Entscheidungen gegeben. Stattdessen muss er durch Versuch und Irrtum selbst erlernen, welche Handlungsstrategien langfristig zu einem möglichst hohen kumulativen Reward führen @sutton_reinforcement_2018[S. 1 f.]. Aufgrund dieses Ansatzes eignet sich Reinforcement Learning besonders für komplexe Entscheidungsprobleme mit zeitlicher Abhängigkeit, beispielsweise in der Robotik, Navigation oder bei der Entwicklung von Spielstrategien.
Eine besondere Herausforderung im bestärkenden Lernen stellt das sogenannte Exploration-Exploitation-Dilemma dar. Der Agent muss kontinuierlich abwägen, ob er bereits bekannte und erfolgversprechende Aktionen ausführt (Exploitation) oder neue, bislang wenig erforschte Aktionen ausprobiert (Exploration), die langfristig zu einer höheren Belohnung führen könnten @sutton_reinforcement_2018[S. 3]. Die Balance zwischen diesen beiden Strategien ist ein zentraler Aspekt vieler Reinforcement-Learning-Verfahren und hat entscheidenden Einfluss auf deren Leistungsfähigkeit.
=== Markov-Entscheidungsprozess

Der theoretische Rahmen des bestärkenden Lernens wird durch den Markov-Entscheidungsprozess (Markov Decision Process, MDP) beschrieben. Ein MDP modelliert die Interaktion eines Agenten mit seiner Umgebung und bildet damit eine zentrale Grundlage vieler Reinforcement-Learning-Verfahren. Dabei befindet sich der Agent zu einem Zeitpunkt in einem Zustand, wählt eine Aktion aus, erhält anschließend eine Belohnung und gelangt in einen Folgezustand @sutton_reinforcement_2018[S. 47 f.].

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

Dieses Verhältnis beschreibt, wie stark sich die Wahrscheinlichkeit der gewählten Aktion unter der neuen Policy im Vergleich zur alten Policy verändert hat. Ein Wert von $r_t (theta) = 1$ bedeutet, dass beide Policies die Aktion gleich wahrscheinlich bewerten. Werte größer als 1 bedeuten, dass die neue Policy die Aktion wahrscheinlicher macht; Werte kleiner als 1 bedeuten, dass sie die Aktion weniger wahrscheinlich macht.Die zentrale PPO-Zielfunktion mit Clipping lautet:
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

== Sequenzmodellierung für RL


Der MDP setzt durch die Markov-Eigenschaft voraus, dass der aktuelle Zustand alle für zukünftige Entscheidungen relevanten Informationen enthält. In praktischen Anwendungen ist diese Voraussetzung aus Sicht des Agenten jedoch häufig nicht vollständig erfüllt, da der Agent meist nur eine begrenzte Beobachtung der Umgebung erhält. Sutton und Barto betonen, dass eine Zustandsrepräsentation nicht auf unmittelbare Sensordaten beschränkt sein muss, sondern auch aus vergangenen Wahrnehmungen oder einem internen Gedächtnis aufgebaut werden kann @sutton_reinforcement_2018[S. 49].

Bei einem Agenten mit Ray-Sensoren beschreibt ein einzelner Timestep beispielsweise nur einen lokalen Ausschnitt der Umgebung. Dadurch kann der Agent aus einer einzelnen Beobachtung nicht zuverlässig ableiten, ob er sich bereits in einer Sackgasse befindet oder welchen Weg er zuvor genommen hat. Solche Problemstellungen lassen sich als partiell beobachtbare Entscheidungsprobleme auffassen, bei denen vergangene Beobachtungen und Aktionen zusätzliche Informationen für die Entscheidungsfindung liefern können.

Sequenzmodelle wie LSTM oder Transformer können diese zeitlichen Informationen nutzen, indem sie mehrere vergangene Zeitschritte berücksichtigen. Dadurch kann der Agent eine bessere interne Repräsentation seiner aktuellen Situation aufbauen und fundiertere Entscheidungen treffen.


=== Long Short-Term Memory (LSTM)
Long Short-Term Memory (LSTM) ist eine spezielle Variante rekurrenter neuronaler Netze (Recurrent Neural Networks, RNNs), die entwickelt wurde, um Informationen über lange Zeiträume hinweg speichern und verarbeiten zu können @goodfellow_deeplearningbookorgcontentsrnnhtml_2026[S. 404]. Während klassische RNNs grundsätzlich für die Verarbeitung sequenzieller Daten geeignet sind, stoßen sie bei langen Eingabesequenzen häufig an ihre Grenzen. Ursache hierfür ist das sogenannte Vanishing-Gradient-Problem, bei dem die während des Trainings berechneten Gradienten mit zunehmender Sequenzlänge immer kleiner werden. Dadurch wird es für das Netzwerk schwierig, Abhängigkeiten zwischen weit auseinanderliegenden Zeitschritten zu erlernen und relevante Informationen langfristig zu speichern @goodfellow_deeplearningbookorgcontentsrnnhtml_2026[S. 404].
Um dieses Problem zu lösen, erweitert LSTM die Architektur klassischer RNNs um eine Speicherstruktur, die als Zellzustand bezeichnet wird. Dieser dient als internes Gedächtnis und ermöglicht die Weitergabe wichtiger Informationen über viele Zeitschritte hinweg. Der Informationsfluss innerhalb des Netzwerks wird dabei durch mehrere lernbare Steuermechanismen, sogenannte Gates, kontrolliert @goodfellow_deeplearningbookorgcontentsrnnhtml_2026[S. 404 ff.].
Das Forget Gate entscheidet, welche Informationen aus dem bisherigen Gedächtnis beibehalten und welche verworfen werden. Dadurch kann das Netzwerk nicht mehr relevante Informationen gezielt vergessen. Das Input Gate bestimmt, welche neuen Informationen aus dem aktuellen Eingabeschritt in den Zellzustand aufgenommen werden. Das Output Gate legt schließlich fest, welche Teile des internen Gedächtnisses als Ausgabe an den nächsten Zeitschritt beziehungsweise an nachfolgende Netzwerkschichten weitergegeben werden @goodfellow_deeplearningbookorgcontentsrnnhtml_2026[S. 406 f.].
Durch das Zusammenspiel dieser Gates kann ein LSTM relevante Informationen über viele Zeitschritte hinweg speichern und gleichzeitig irrelevante Informationen verwerfen. Dadurch eignet sich die Architektur besonders für Aufgaben, bei denen zeitliche Abhängigkeiten eine wichtige Rolle spielen, beispielsweise bei der Sprachverarbeitung, Zeitreihenanalyse oder im Reinforcement Learning.
Das Gedächtnis eines LSTM wird durch einen kontinuierlich aktualisierten internen Zustand repräsentiert. Welche Informationen gespeichert, überschrieben oder vergessen werden, wird nicht manuell festgelegt, sondern während des Trainings automatisch erlernt. Im Kontext von Reinforcement Learning ermöglicht dies dem Agenten, Informationen aus vergangenen Beobachtungen zu berücksichtigen und dadurch fundiertere Entscheidungen zu treffen. In Unity ML-Agents ist LSTM bereits integriert und kann über die Konfigurationsoption use_recurrent: true aktiviert werden. Dadurch erhält der Agent eine Form von Gedächtnis, die es ihm erlaubt, auch in teilweise beobachtbaren Umgebungen historische Informationen in seine Entscheidungsfindung einzubeziehen.
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
*Im Rahmen dieser Arbeit erhält der Agent pro Zeitschritt insgesamt 14 numerische Beobachtungswerte. Dazu zählen die normalisierte Eigengeschwindigkeit des Agenten, ein Indikator für den Bodenkontakt (isGrounded), der Richtungsvektor zum Zielobjekt sowie die Informationen eines manuell implementierten Bodensensors. Dieser basiert auf drei nach vorne gerichteten Raycasts und liefert sowohl Informationen über die erkannte Bodenart als auch die normalisierte Distanz zum jeweils getroffenen Objekt.* //Überprüfen ob dass auch stimmt mit den 14 numerischen beobachtungswerte
=== Ray-Sensoren (RayPerceptionSensor)
Neben Vektorbeobachtungen bietet Unity ML-Agents die Möglichkeit, die Umgebung mithilfe von Ray-Sensoren (RayPerceptionSensor) wahrzunehmen. Hierbei werden virtuelle Strahlen vom Agenten ausgesendet, die Kollisionen mit Objekten in der Umgebung erkennen. Für jeden Strahl werden Informationen über den erkannten Objekttyp sowie dessen Entfernung zum Agenten erfasst. Dadurch entsteht eine kompakte und effiziente Repräsentation der unmittelbaren Umgebung, ohne dass eine aufwendige Bildverarbeitung erforderlich ist @juliani_unity_2020[S.12f].

*In dieser Arbeit wird ein RayPerceptionSensor3D eingesetzt, der insgesamt elf Strahlen über einen Sichtwinkel von 120° aussendet. Jeder Strahl kann sechs unterschiedliche Objekttypen erkennen: Wall, Lava, Hole, Goal, Obstacle und Bridge. Die maximale Reichweite beträgt zwölf Zellen. Zusätzlich werden zwei aufeinanderfolgende Beobachtungen gestapelt (Stacked Raycasts = 2). Durch diese zeitliche Erweiterung erhält der Agent implizite Informationen über Veränderungen in seiner Umgebung und kann beispielsweise Bewegungen oder Richtungsänderungen besser erkennen.* // Überprüfen
=== Kamerasensor (CameraSensor)
BRAUCHEN WIR DEN ÜBERHAUPT AUFZÄHLEN
=== Beobachtungsraum und Normalisierung
Unabhängig vom verwendeten Sensortyp spielt die Vorverarbeitung der Beobachtungsdaten eine wichtige Rolle für die Stabilität des Lernprozesses. Damit einzelne Merkmale das Training nicht aufgrund ihrer Größenordnung dominieren, sollten sämtliche Eingabewerte in vergleichbaren Wertebereichen vorliegen @goodfellow_deeplearningbookorgcontentsconvnetshtml_nodate[S.179]. Nicht normalisierte Eingaben können zu instabilen Gradienten und einer schlechteren Konvergenz des neuronalen Netzes führen.
*Aus diesem Grund werden in dieser Arbeit sämtliche durch den VectorSensor bereitgestellten Beobachtungen auf das Intervall [−1,1][-1, 1][−1,1] skaliert. Die vom RayPerceptionSensor erzeugten Distanz- und Klassifikationsinformationen werden hingegen automatisch durch Unity ML-Agents normalisiert. Dadurch liegen alle Beobachtungen in einem konsistenten numerischen Bereich vor, was effizientes und stabiles Training der Agenten unterstützt.* // Überprüfen
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
//        · (Gedächtnisproblem NEU 2.4.1 ist neu/kurz; Motivation auch in 1.5)
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
//        (NEU 5.3.2 "Notwendige YAML-Abweichungen" ist ZUSATZ; Quelle:
//         02_Anforderungen_Fairer_Vergleich.md, Abschnitt A.2)
// ALT 4 "Evaluationsprotokoll"            -> NEU 5.4 (Primär/General./Statistik)
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

// - Einordnung KI ⊃ ML ⊃ RL; supervised / unsupervised / reinforcement
// - Markov-Entscheidungsprozesse (MDP), Policy, Value-/Q-Function
// - On-Policy vs. Off-Policy

== Proximal Policy Optimization (PPO)

// - Actor-Critic-Framework (Actor-Netz + Critic-Netz)
// - Schulman et al. (2017): Clipping (ε = 0.2), GAE (λ = 0.95)
// - Vorteil ggue. Vanilla Policy Gradient (Stabilität)

== Wahrnehmung in RL-Agenten

// - Sensortypen als HINTERGRUND: Ray-Sensoren, Kamera (CNN), Vector-Observations
//   (Kamera nur theoretische Einordnung — wird NICHT empirisch untersucht;
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

// - Hochreiter & Schmidhuber (1997); Forget-/Input-/Output-Gates
// - Implizites Gedächtnis ohne expliziten Sequenz-Buffer
// - In ML-Agents standardmäßig verfügbar (network_settings.memory: memory_size,
//   sequence_length; use_recurrent ist Alt-Syntax)

=== Transformer-Architektur

// - Vaswani et al. (2017); Self-/Multi-Head-Attention, Positional Encoding
// - RL-Kontext: Decision Transformer (Chen 2021), GTrXL (Parisotto 2019)
// - Vor-/Nachteile ggue. LSTM NEUTRAL beschreiben (keine Wertung vorwegnehmen)

== Unity ML-Agents Toolkit

// - Architektur: Unity-Environment <-> Python-Trainer (gRPC)
// - Komponenten: Agent, Behavior Parameters, Decision Requester, Sensoren
// - Workflow: YAML-Config, ONNX-Export, TensorBoard; Version 0.30.0

*/
// ============================================================================

= Stand der Technik

Nachdem in Kapitel 2 die theoretischen Grundlagen der eingesetzten Verfahren erläutert wurden, ordnet dieses Kapitel die vorliegende Arbeit in den aktuellen Forschungsstand ein. Zunächst werden etablierte Simulationsplattformen für das Deep Reinforcement Learning verglichen und die Wahl des Unity-ML-Agents-Frameworks begründet. Anschließend wird der Forschungsstand zur lernbasierten Navigation in dreidimensionalen Umgebungen betrachtet --- vom Umgang mit partieller Beobachtbarkeit über die Belohnungsgestaltung bis zur Generalisierung auf unbekannte Umgebungen. Abschließend wird aus dem dargestellten Forschungsstand der Handlungsbedarf abgeleitet, an dem die vorliegende Arbeit ansetzt.

== Simulationsumgebungen und das Unity-ML-Agents-Framework

Verfahren des Deep Reinforcement Learning benötigen typischerweise Millionen von Interaktionsschritten, bis sich ein brauchbares Verhalten einstellt. Das Training findet daher fast ausschließlich in simulierten Umgebungen statt, in denen die Simulationsgeschwindigkeit gegenüber der Echtzeit erhöht und Episoden beliebig oft wiederholt werden können. In der Forschung haben sich hierfür verschiedene Plattformen etabliert. DeepMind Lab stellt auf Basis der Quake-III-Engine prozedural erzeugbare 3D-Labyrinthe bereit und wurde gezielt für die Navigations- und Explorationsforschung entwickelt. @beattie_deepmind_2016 Einen ähnlichen Ansatz verfolgt ViZDoom auf Basis der Doom-Engine, das RL-Forschung mit rein visuellen Beobachtungen ermöglicht. @kempka_vizdoom_2016 Beide Plattformen sind jedoch auf ihre jeweilige Engine festgelegt und erlauben nur begrenzte Anpassungen der Weltlogik.

Das Unity-ML-Agents-Toolkit verfolgt demgegenüber einen allgemeineren Ansatz: Es verbindet die Unity-Engine als frei gestaltbare Simulationsumgebung mit einer Python-Schnittstelle für das Training. Juliani et al. @juliani_unity_2020 argumentieren, dass Spiele-Engines wie Unity durch ihre flexible Physiksimulation, die visuelle Gestaltungsfreiheit und die Steuerbarkeit der Simulationsgeschwindigkeit besonders geeignete Plattformen für die Entwicklung intelligenter Agenten darstellen. Für die vorliegende Arbeit ist darüber hinaus entscheidend, dass die Weltlogik --- Zelltypen, Gefahrenfelder, prozedurale Layouterzeugung --- vollständig selbst gestaltbar ist, was bei den engine-gebundenen Plattformen nur eingeschränkt möglich wäre. 
== Lernbasierte Navigation in 3D-Umgebungen

Die autonome Navigation in dreidimensionalen Umgebungen zählt zu den klassischen Anwendungsfeldern des Deep Reinforcement Learning. Im Hinblick auf die Zielsetzung dieser Arbeit --- einen Agenten zu entwickeln, der generalisierbares Navigationsverhalten in Labyrinthen mit Gefahrenfeldern erlernt --- ist es unabdingbar, den Forschungsstand zur lernbasierten Navigation, zum Umgang mit partieller Beobachtbarkeit, zur Belohnungsgestaltung und zur Generalisierung näher zu betrachten. In den folgenden Teilkapiteln wird der Forschungsstand hierzu erläutert.

=== Anfänge der lernbasierten Navigationsforschung

Die moderne Erforschung der lernbasierten Navigation in 3D-Umgebungen nahm ihren Ausgang mit dem Erfolg des Deep Reinforcement Learning auf zweidimensionalen Spielumgebungen durch Mnih et al. @mnih_human-level_2015 im Jahr 2015. In der Folge verlagerte sich der Forschungsschwerpunkt auf komplexere dreidimensionale Welten.

Erstmals untersuchten Mirowski et al. @mirowski_learning_2017 im Jahr 2017 systematisch das Navigationslernen in großen 3D-Labyrinthen allein auf Basis visueller Beobachtungen. Sie erkannten, dass reine End-to-End-Navigation aus Rohbeobachtungen äußerst datenhungrig ist, und führten zusätzliche Hilfsaufgaben (engl. Auxiliary Tasks) ein, darunter die Vorhersage von Tiefeninformationen und die Erkennung bereits besuchter Orte. In ihren Untersuchungen kamen sie zum Ergebnis, dass diese Hilfsaufgaben das Navigationslernen erheblich beschleunigen, da sie dem Netz zusätzliches Struktursignal über die räumliche Beschaffenheit der Umgebung liefern. Zudem setzten sie rekurrente Netzarchitekturen ein, um Informationen über die Zeit hinweg zu aggregieren. @mirowski_learning_2017

Im selben Jahr veröffentlichten Zhu et al. @zhu_target-driven_2017 ihre Forschungsergebnisse zur zielgerichteten visuellen Navigation in Innenraumszenen. Sie untersuchten einen Ansatz, bei dem das anzusteuernde Ziel selbst Teil der Netzeingabe ist, sodass ein einzelnes trainiertes Modell unterschiedliche Ziele ansteuern kann, ohne für jedes Ziel neu trainiert werden zu müssen. @zhu_target-driven_2017 Dieses Prinzip, das Ziel nicht fest in die Policy einzubauen, sondern als variable Information bereitzustellen, findet sich auch im Aufbau der vorliegenden Arbeit wieder, in der Start- und Zielposition in jeder Episode zufällig neu platziert werden.

=== Grundlagen des Lernens unter partieller Beobachtbarkeit <sec:partielle-beobachtbarkeit>

Wie in sec:sequenzmodellierung erläutert, sind Labyrinthumgebungen partiell beobachtbar: Der Agent nimmt in jedem Zeitschritt nur einen lokalen Ausschnitt der Welt wahr. Eine rein reaktive Policy, die ausschließlich die aktuelle Beobachtung verarbeitet, erreicht in solchen Umgebungen schnell eine Leistungsgrenze, da sie mehrdeutige Situationen nicht auflösen kann. Typische Fehlerbilder sind das Oszillieren in Sackgassen oder das wiederholte Absuchen bereits erkundeter Bereiche. @hausknecht_deep_2015

Hausknecht und Stone @hausknecht_deep_2015 zeigten bereits 2015, dass die Erweiterung eines tiefen Q-Netzes um eine rekurrente LSTM-Schicht die Leistung in partiell beobachtbaren Aufgaben deutlich verbessert. Das LSTM verdichtet die Historie vergangener Beobachtungen in einem internen Zustandsvektor und stellt dem Agenten damit ein implizites Gedächtnis zur Verfügung. @hausknecht_deep_2015 Auch Mirowski et al. @mirowski_learning_2017 setzten für ihre Labyrinthnavigation auf gestapelte rekurrente Einheiten. Rekurrente Gedächtnisarchitekturen stellen damit den etablierten Ausgangspunkt für Navigationsaufgaben unter partieller Beobachtbarkeit dar; in ML-Agents sind sie in Form eines optionalen LSTM-Speichers direkt in die PPO-Trainingspipeline integriert. @juliani_unity_2020

Rekurrente Netze weisen jedoch einen strukturellen Nachteil auf: Sämtliche Informationen vergangener Zeitschritte müssen durch einen komprimierten internen Zustand fester Größe propagiert werden. Weit zurückliegende Beobachtungen können dabei verblassen, und das Training über lange Sequenzen ist schwer parallelisierbar. Diese Einschränkungen bilden die wesentliche Motivation für den Einsatz von Aufmerksamkeitsmechanismen, deren Grundlagen in sec:transformer-grundlagen erläutert wurden. @parisotto_stabilizing_2019

=== Grundlagen der Belohnungsgestaltung

Neben dem Lernalgorithmus und der Modellarchitektur hat die Gestaltung der Belohnungsfunktion wesentlichen Einfluss auf den Trainingserfolg. In Navigationsaufgaben ist die natürliche Belohnung --- das Erreichen des Ziels --- spärlich (engl. sparse), da sie erst am Ende einer erfolgreichen Episode auftritt. Ein zufällig explorierender Agent findet das Ziel in großen Labyrinthen anfangs nur selten, wodurch das Lernsignal weitgehend ausbleibt. @sutton_reinforcement_2018

Als Reward Shaping wird die Anreicherung der Belohnungsfunktion um Zwischenbelohnungen bezeichnet, etwa Strafen für Zeitverbrauch oder für das Betreten gefährlicher Felder. Ng et al. @ng_policy_1999 zeigten bereits 1999, dass potentialbasiertes Reward Shaping die optimale Policy nicht verändert, während naiv gewählte Zwischenbelohnungen unerwünschtes Verhalten hervorrufen können, beispielsweise das wiederholte Einsammeln derselben Teilbelohnung anstelle der eigentlichen Zielerreichung. @ng_policy_1999 Für die vorliegende Arbeit ergibt sich daraus die Anforderung, die Belohnungsfunktion nicht nur qualitativ zu beschreiben, sondern mit konkreten, begründeten Zahlenwerten zu spezifizieren. Ein verbreitetes Grundmuster für Navigationsaufgaben ist die Kombination aus einer positiven Terminalbelohnung für das Erreichen des Ziels, negativen Terminalbelohnungen für das Scheitern sowie einer kleinen negativen Belohnung pro Zeitschritt, die als Zeitdruck wirkt und passives Verhalten verhindert. @sutton_reinforcement_2018

=== Generalisierung auf unbekannte Umgebungen

Ein zentrales Qualitätskriterium lernender Navigationsagenten ist, dass sie nicht einzelne Karten auswendig lernen, sondern übertragbares Verhalten entwickeln. Dieses Problem ist in der Forschung als Generalisierungsproblem bekannt. Zhang et al. @zhang_study_2018 untersuchten 2018 das Überanpassungsverhalten von Deep-RL-Agenten und kamen zum Ergebnis, dass Agenten bei Training auf einer festen, kleinen Menge von Umgebungen massiv überanpassen: Ihre Leistung bricht auf strukturell ähnlichen, aber ungesehenen Varianten drastisch ein, obwohl die Trainingsleistung hoch ist. @zhang_study_2018

Cobbe et al. @cobbe_quantifying_2019 quantifizierten diesen Effekt ein Jahr später systematisch anhand prozedural generierter Level. Sie wiesen nach, dass überraschend große Trainingsmengen, in ihren Experimenten mehrere Tausend Levelvarianten, erforderlich sein können, bevor die Leistung auf ungesehenen Leveln mit der Trainingsleistung gleichzieht. @cobbe_quantifying_2019 Als Konsequenz etablierten Cobbe et al. @cobbe_leveraging_2020 mit dem Procgen Benchmark eine Evaluationsumgebung, in der Trainings- und Testlevel strikt getrennt prozedural erzeugt werden, um tatsächliche Generalisierung anstelle von Memorierung zu messen. @cobbe_leveraging_2020

Aus diesen Arbeiten lassen sich zwei methodische Anforderungen für die vorliegende Arbeit ableiten. Erstens muss die Trainingsumgebung ausreichende Variation bereitstellen. Das in dieser Arbeit entwickelte Map-System mit mehreren Grundlayouts, prozeduraler Layouterzeugung sowie pro Episode zufällig platzierten Start-, Ziel- und Hindernispositionen dient genau diesem Zweck. Zweitens muss die Evaluation auf zurückgehaltenen Karten erfolgen, die während des Trainings nicht verwendet wurden, da Erfolgsraten auf Trainingskarten die tatsächliche Fähigkeit des Agenten systematisch überschätzen würden. @zhang_study_2018 @cobbe_quantifying_2019

== Ableitung des Handlungsbedarfs für die vorliegende Arbeit

Der dargestellte Stand der Technik zeigt, dass die einzelnen Bausteine der vorliegenden Arbeit jeweils gut erforscht sind: PPO ist ein etabliertes, robustes Trainingsverfahren @schulman_proximal_2017, Unity ML-Agents eine erprobte Plattform für selbst gestaltete Trainingsumgebungen @juliani_unity_2020, die Labyrinthnavigation ein klassisches Untersuchungsfeld @mirowski_learning_2017 und die Notwendigkeit von Umgebungsvariation für die Generalisierung empirisch belegt @zhang_study_2018 @cobbe_quantifying_2019. Der Einsatz von Transformern als Entscheidungsmodell im Online-Reinforcement-Learning ist durch den GTrXL prinzipiell demonstriert @parisotto_stabilizing_2019, allerdings überwiegend auf großskaligen Forschungsplattformen mit erheblichem Rechenaufwand.

// ============================================================



// ============================================================================
// 4. SYSTEMARCHITEKTUR UND UMGEBUNG  — erst die Welt bauen (vor Methodik)
//FINN ============================================================================
= Systemarchitektur und Umgebung

Dieses Kapitel beschreibt das entwickelte System in seinem Endzustand als Versuchsapparat: Dargestellt wird, was das Experiment voraussetzt, um die Forschungsfragen F1--F3 beantworten zu können. Die Umgebung steht dabei bewusst vor der Methodik, denn das Vergleichsdesign (Kapitel 5) ist nur vor dem Hintergrund der Welt verständlich, in der gemessen wird. Wie das System entstanden ist, einschließlich der revidierten Zwischenstände, dokumentiert Kapitel 7 (@sec:iterationen). Dieses Kapitel liefert den Zustand, Kapitel 7 die Genese.

== Gesamtüberblick

Das Gesamtsystem bildet einen geschlossenen Regelkreis aus Unity-Umgebung, PPO-Trainer und TensorBoard-Monitoring: Die Unity-Szene liefert Beobachtungen und Belohnungssignale, der Python-Trainer optimiert die Policy und sendet Aktionen zurück, TensorBoard protokolliert den Trainingsverlauf. Alle drei verglichenen Architekturen laufen unter identischer Kopplung in demselben Apparat. Damit ist die Netzarchitektur die einzige zwischen den Vergleichsgruppen variierte Größe. Das darauf aufbauende Vergleichsdesign wird in Kapitel 5 entwickelt.

// TODO: Komponentendiagramm als Abbildung ergänzen
// (Unity-Umgebung <-> gRPC <-> PPO-Trainer <-> TensorBoard).

Die Umgebung diente als reproduzierbarer Testbereich über Seeds, in dem die Forschungsfragen F1-F3 untersucht werden konnten: Jedes Kartendesign konnte deterministisch aus einem Seed generiert werden und konnte somit vor Beginn des Trainings fixiert, frei wiederverwendet oder absichtlich vom Training ausgeschlossen werden (@sec:prozgen). Die verwendeten Versionen und die Struktur des Repositories sind in @tab:systemstack zusammengefasst.

#figure(
  table(
    columns: 2,
    align: (left, left),
    [*Komponente*], [*Spezifikation*],
    [Engine], [Unity 6 (6000.2.6f1)],
    [ML-Agents (Unity-Paket)], [`com.unity.ml-agents` 2.0.2],
    [ML-Agents (Python-Trainer)], [`mlagents` 0.30.0 (Details: @tab:traininginfra)],
    [Kopplung Unity--Trainer], [ML-Agents-gRPC; je `--num-envs`-Instanz ein eigener Headless-Unity-Prozess mit eigenem Port],
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

Eine Karte besteht aus typisierten Zellen, die in einem zweidimensionalen System angeordnet sind (@tab:datenmodell). Mehrere Aspekte dieses Datenmodells sind relevant für die Beantwortung der Forschungsfragen. Erstens schafft die Menge der Zelltypen mit Lava und Loch in Verbindung mit den Sackgassen der prozeduralen Layouts eine größere Vielfalt der Teil-Observabilität, mit der das temporäre Gedächtnis umgehen muss (F1, siehe die Problemstellung in @sec:forschungsfrage). Zweitens verbindet der Zelltyp Plattform den Inhalt der Karte mit dem Konzept der Lösbarkeit: Lavas können nur mit einer Plattform oder durch Springen aus Tiefe 1 überwunden werden. Diese Logik rechtfertigt das in @sec:prozgen erklärte Konzept der Lösbarkeit und stellt die Quelle der Fehler in der Generalisierungsmetrik dar (F3).

#figure(
  table(
    columns: 2,
    align: (left, left),
    [*Element*], [*Spezifikation*],
    [CellType (Enum, 9 Werte)], [Empty, Floor, Wall, Obstacle, Goal, SpawnPoint, Lava, Hole, Platform],
    [MapData (ScriptableObject)], [`width`, `height`, `CellType[] cells`; Zellindex `y * width + x`; Zugriff über `GetCell`/`SetCell`],
    [Laufzeitfelder], [`cellHeightOffsets` (Default 0.75); Flag `noRuntimeObstacles`],
  ),
  caption: [Datenmodell der Karten: Zelltyp-Satz und Felder von MapData.],
) <tab:datenmodell>

=== MapGenerator zur Laufzeit

Zur Laufzeit instanziiert der MapGenerator nur ein bestimmtes Layout als 3D-Szene. Er fungiert nur als Renderer. Wie im Offline-Pipeline (@sec:prozgen) detailliert beschrieben, erfolgen die Hinderniskonstruktion und die Überprüfung der Lösbarkeit außerhalb des MapGenerators. Aufgrund dieser Trennung wird es möglich, Karten zu generieren (F3, @sec:evalprotokoll). Durch die Trennung ist es plausibel, Karten vor Beginn des Trainings zu erstellen, diese „einzufrieren“ und einige als ungesehenes Bewertungssets vorzubehalten. Es ist unmöglich zu garantieren, dass eine Testkarte, während der Laufzeit der Kartenübertragung, im Trainingsprozess nicht präsentiert wurde, weshalb diese Trennung eine notwendige Bedingung ist, um Generalisierung zu messen.

Das Curriculum ist als eigener Training Mode implementiert und nicht als Karten-Auswahlmodus (@tab:mapgen). Die gestufte Schwierigkeit ist bewusst als kontrollierte Trainingsbedingung konzipiert und entsteht nicht zufällig durch die Kartenauswahl. Die methodische Begründung folgt in Kapitel 5, die technische Umsetzung in Kapitel 7.

Für den Architekturvergleich ist außerdem der Multi-Area-Betrieb entscheidend. Mehrere identische Trainingsflächen pro Szene gewährleisten für jede Architektur denselben Sampling-Durchsatz und schaffen damit die Voraussetzung für einen fairen Vergleich. Kapitel 5 erläutert das Versuchsdesign. Die Vergleichs-Szene, in der alle drei Architekturen gleichzeitig mit derselben Anzahl an Trainingsflächen trainieren, bildet dabei die Grundlage dieser Aussage. Die Anzahl der Trainingsflächen pro Szene ist in @tab:mapgen dokumentiert.

#figure(
  table(
    columns: 2,
    align: (left, left),
    [*Element*], [*Spezifikation*],
    [Tile-Pool], [wiederverwendete Kacheln mit Prefab-Mapping je Zelltyp; kein Instantiate/Destroy je Episode],
    [Spawn- und Zielposition], [im Trainings-Prefab vordefiniert aus den gebackenen Layout-Zellen (genau je eine pro prozeduralem Layout); die dynamische Meide-Logik (Lava-/Hole-Nachbarn, Ziel ≠ Spawn) ist nur Standard-/Fallback-Pfad; Ziel-Variation entsteht offline über den Layout-Pool (@tab:curriculum), nicht zur Laufzeit; Marker um +0.5 auf der Y-Achse versetzt; optionales Kamera-Framing],
    [KillZone], [persistente Trigger-Box bei y = −20; terminiert Episoden nach Sturz in ein Loch (Terminierungsmechanik; Entstehung: Kapitel 7)],
    [Platzierungs-Modi], [Spawn-, Goal- und ObstaclePlacementMode; MapSelectionMode {Fixed, Random, Sequential}; Curriculum-Quelle: `CurriculumTracker.GetNextLayout()`],
    [Trainingsflächen je Szene], [Training_MultiArea: 10; Transformer_Test_V2: 16; Vergleichs-Szene „Training Area“: 27 (3 × 9, d. h. 9 je Architektur); Einzelszenen: 1 je Prozess, skaliert über `--num-envs`],
  ),
  caption: [Laufzeit-Kartenaufbau: Objektverwaltung, Platzierungslogik und Trainingsflächen je Szene.],
) <tab:mapgen>

=== Prozedurale Generierung als Umsetzung der Messbarkeitsbedingung <sec:prozgen>

Kapitel 1 formuliert die zentrale Bedingung für den Nachweis von Generalisierung (@sec:messbarkeit): Generalisierung kann nur auf Layouts nachgewiesen werden, die während des Trainings nie gesehen wurden. Dafür sind systematisch erzeugbare Layouts sowie ein zurückgehaltenes, ungesehenes Test-Set erforderlich. Die prozedurale Generierung schafft diese Voraussetzung. Sie ist eine grundlegende Voraussetzung für den Nachweis der Generalisierung (F3).

Die Layouts entstehen in einer graphbasierten Pipeline aus Räumen und Korridoren (@tab:prozgen). Jede erzeugte Karte durchläuft abschließend eine Lösbarkeitsprüfung: Der SemanticPathfinder verifiziert per Breitensuche über die 4er-Nachbarschaft, dass vom Startpunkt ein begehbarer Pfad zum Ziel existiert. Welche Zelltypen dabei als begehbar gelten, folgt exakt der Hindernis-Semantik des Datenmodells (@sec:datenmodell; Regeln in @tab:prozgen). Diese Garantie ist für die Interpretation aller späteren Ergebnisse entscheidend: Scheitert ein Agent an einer Karte, ist das Scheitern dem Agenten zuzuschreiben, nicht einer unlösbaren Karte (F3).

Jedes Layout geht deterministisch aus einem Seed hervor. So lassen sich Karten systematisch und reproduzierbar erzeugen. Darauf beruht das zurückgehaltene, im Training nie gesehene Evaluations-Set. Dadurch wird der Overfitting-Index als Differenz aus Trainings- und Generalisierungs-Erfolgsrate messbar (Definition in @sec:evalprotokoll, Ergebnisse in @sec:generalisierung).

Die erzeugten Layouts sind zudem nach Schwierigkeit gestuft (@tab:curriculum). Diese aufsteigende Schwierigkeitsleiter definiert die Progression des Curriculum-Trainings, deren Wirkung auf die Konvergenz der Architekturen später gemessen wird (F1/F2, @sec:architekturvergleiche). Die zugehörige Trainingsbedingung legt Kapitel 5 fest, ihre Entstehung schildert Kapitel 7.

Schließlich erzeugt die Hindernis-Semantik der Pipeline gezielt Situationen, die für die Forschungsfragen entscheidend sind: Terminal-Korridore enden blind in einem Loch, Lava bildet Sprung-Hürden und Verzweigungen führen in Sackgassen. Gerade diese partiell observierbaren Situationen erfordern temporales Gedächtnis (F1). Die Schwierigkeit der Umgebung entsteht damit nicht zufällig, sondern ist gezielt konstruiert.

#figure(
  table(
    columns: 2,
    align: (left, left),
    [*Stufe*], [*Spezifikation*],
    [Einstiegspunkt], [`ProceduralLayoutGenerator.GenerateLayout(seed, difficulty)`; bis zu 10 Generierungsversuche je Aufruf; Aufruf ausschließlich in Editor-Skripten (MapGeneratorEditor, CurriculumV2Builder), nicht zur Laufzeit],
    [Pipeline], [BuildTopology → Räume → Korridore → Wände → Spawn/Ziel → Coverage ≥ 15 % → Hindernis-Cluster → Platforms → Pfad-Check],
    [RoomCorridorGraph], [`BORDER` = 2; `MIN_CORRIDOR_LEN` = 4; Korridore 2 Kacheln breit; Raumtypen Start, Goal, DeadEnd; Goal-Raum ist der Knoten mit größter Manhattan-Distanz (zu 75 %), mit 25 % Wahrscheinlichkeit der zweitweiteste (`goalIndex` = 1 bei `rng` \< 0.25); optionale Loops],
    [ObstacleClusterPlacer], [je Korridortyp: Goal-Korridor Lava der Tiefe 1/2/3 (Platform ab Tiefe \> 1); DeadEnd-/Terminal-Korridor Hole der Tiefe 2; Loop-Korridor zu 50 % Lava der Tiefe 1; DeadEnd-Korridor wahlweise kein Hindernis, Hole oder Lava],
    [SemanticPathfinder], [Breitensuche (BFS) über die 4er-Nachbarschaft; begehbar: Floor, SpawnPoint, Goal, Platform sowie CellType.Obstacle (Rückwärtskompatibilität zu Alt-Assets); Hole nie; Lava nur bei Tiefe 1 oder mit Platform],
  ),
  caption: [Offline-Generierungspipeline: Einstiegspunkt, Konstanten und Lösbarkeitsregeln.],
) <tab:prozgen>

#figure(
  table(
    columns: 2,
    align: (left, left),
    [*Element*], [*Spezifikation*],
    [DifficultyLevel-Enum (Reihenfolge)], [Trivial → TrivialCorr → TrivialBranch → TrivialHole → TrivialHazard → Easy → Medium → Hard; zusätzlich TrivialLava],
    [Trainiertes 8-Phasen-Curriculum (CurriculumV2Builder)], [Trivial → TrivialCorr → TrivialHole → TrivialLava → TrivialHazard → Easy → Medium → Hard; TrivialBranch ist keine Phase (100 erzeugte Layouts bleiben ungenutzt); TrivialLava ist reguläre Phase 3],
    [Phasen-Schleife], [`loopPhases` = true: nach Hard Rücksprung auf Easy (relevant für die Interpretation der Trainings-Erfolgsrate, @sec:evalprotokoll)],
    [Layout-Pool], [100--200 Seeds je Stufe, offline erzeugt und eingefroren],
    [Konstruktion], [Trivial fix 7 × 7; übrige Trivial-Stufen direkte Konstruktion mit variabler Größe (Räume 2--4, Korridorlänge 4--9, vier Formtypen); TrivialLava aus separatem LavaMapGenerator; Easy/Medium/Hard über die Graph-Pipeline (@tab:prozgen)],
    [DifficultySettings je Stufe], [Grid-Größe, Korridorzahl, Verzweigungstiefe, Hindernis-Wahrscheinlichkeiten],
  ),
  caption: [Schwierigkeitsleiter und trainiertes Curriculum: Enum-Reihenfolge, Phasenfolge und Konstruktionsparameter der Layout-Pools.],
) <tab:curriculum>

== Agent-System

Die gesamte Agentenlogik (Beobachtungsaufbau, Aktionsausführung und Belohnungsvergabe) liegt in der Klasse LabyrinthAgent (`Assets/Scripts/Agent/LabyrinthAgent.cs`) und ist für alle Architekturen identisch. Die drei Vergleichsagenten unterscheiden sich ausschließlich durch ihren Behavior-Namen und die dahinterliegende Netzarchitektur (@tab:behaviors). 

#figure(
  table(
    columns: 4,
    align: (left, left, left, center),
    [*Behavior-Name*], [*Rolle*], [*Beobachtungen*], [*DecisionPeriod*],
    [MLP_Navigator], [Vergleichsagent (F1--F3)], [31 Vektor + 176 Ray (@tab:sensorspez)], [5],
    [LSTM_Navigator], [Vergleichsagent (F1--F3)], [31 Vektor + 176 Ray (@tab:sensorspez)], [5],
    [Transformer_Navigator], [Vergleichsagent (F1--F3)], [31 Vektor + 176 Ray (@tab:sensorspez)], [5],
  ),
  caption: [Behaviors des Agent-Systems: die drei Vergleichsagenten.],
) <tab:behaviors>

=== Aktionsraum

Der Agent handelt über einen diskreten Aktionsraum mit drei Branches (Bewegung, Drehung und Sprung) (@tab:aktionsraum). Der Aktionsraum ist für MLP, LSTM und Transformer identisch und damit eine kontrollierte Variable des Vergleichs. Beobachtete Leistungsunterschiede sind somit durch die Netzarchitektur begründet. Das Vergleichsdesign, das auf dieser Konstanz aufbaut, wird in Kapitel 5 entwickelt.

#figure(
  table(
    columns: 3,
    align: (left, center, left),
    [*Branch*], [*Größe*], [*Semantik*],
    [0 (Bewegung)], [3], [keine Bewegung / vorwärts / rückwärts],
    [1 (Drehung)], [3], [keine Drehung / links / rechts],
    [2 (Sprung)], [3], [effektiv binär (nur Wert 1 belegt); einzelner AddForce-Impuls, ausgeführt nur bei Bodenkontakt],
  ),
  caption: [Diskreter Aktionsraum der drei Vergleichsagenten (drei Branches der Größe 3).],
) <tab:aktionsraum>

=== Observation-Space <sec:obsspace>

Alle drei Vergleichsagenten erhalten denselben Beobachtungssatz: 31 Vektor-Beobachtungen und 176 Ray-Beobachtungen. Der Szenen-Builder weist MLP_Navigator, LSTM_Navigator und Transformer_Navigator über dasselbe Prefab identische Eingaben zu. Unterschiede in F1 und F2 spiegeln damit ausschließlich Unterschiede der Netzarchitektur wider. Kapitel 5 entwickelt das Vergleichsdesign auf dieser Grundlage.

Die vollständige Spezifikation des Beobachtungssatzes enthält @tab:sensorspez (@sec:sensorik). Für alle Agenten gilt außerdem `NumStackedVectorObservations = 1`, sodass die Vektor-Beobachtungen nicht zusätzlich gestapelt werden.

=== Bewegungs- und Sprungphysik

Der Agent bewegt sich physikbasiert über einen Rigidbody, die Kinematik-Parameter (@tab:physik) sind für alle drei Architekturen identisch. Zwei dieser Parameter sind unmittelbar experimentell relevant. moveSpeed normiert die Geschwindigkeits-Beobachtung (@tab:sensorspez), während die Sprungkraft die Lösbarkeitssemantik der Karten bestimmt, indem sie Lava der Tiefe 1 per Sprung überwindbar macht (@sec:prozgen). Im Endzustand umfasst die Sprungphysik außerdem einen Wall-Climb-Guard sowie eine Begrenzung der vertikalen Geschwindigkeit (Werte in @tab:physik). Die Hintergründe beider Mechanismen werden in der Iterationsdarstellung in Kapitel 7 erläutert (@sec:iterationen).

// TODO: jumpForce 10.5 und maxUpwardVelocity 8 sind die EFFEKTIVEN Werte aus
// Agent.prefab; die Script-Defaults weichen ab (9.0 / 7.0) — Kennzeichnung in
// @tab:physik beibehalten, optional Script-Defaults angleichen.

#figure(
  table(
    columns: 3,
    align: (left, center, left),
    [*Parameter*], [*Wert*], [*Anmerkung*],
    [turnSpeed], [180°/s], [],
    [moveSpeed], [5], [Bezugsgröße der Geschwindigkeits-Normierung (@tab:sensorspez)],
    [jumpForce], [10.5], [effektiver Wert aus Agent.prefab; Impuls nur bei Bodenkontakt],
    [maxUpwardVelocity], [8], [effektiver Wert aus Agent.prefab; begrenzt die vertikale Geschwindigkeit],
    [wallClimbMaxY], [5], [Wall-Climb-Guard (@sec:iterationen)],
    [Masse], [1], [Rotation um X- und Z-Achse fixiert (FreezeRotation)],
    [GroundCheck], [Raycast abwärts], [trifft Floor, Bridge, Platform, Goal; Bedingung für den Sprung],
  ),
  caption: [Bewegungs- und Sprungphysik des Agenten. jumpForce und maxUpwardVelocity sind die effektiven Werte aus Agent.prefab (Script-Defaults abweichend).],
) <tab:physik>

== Sensorik — und die begründete Wahl der Ray-Wahrnehmung <sec:sensorik>

Die Beschränkung auf Ray-basierte Wahrnehmung ist methodisch begründet. Erstens isoliert die einheitliche Ray-Sensorik aller drei Agenten die Wirkung der temporalen Architektur von der Wirkung des visuellen Encoders: Bei Kamera-Agenten wäre unklar, ob beobachtete Unterschiede aus dem Temporal-Modul oder aus dem CNN-Modul stammen. Zweitens erlaubt die niedrigdimensionale Ray-Repräsentation (Float-Vektoren statt Pixel-Arrays) deutlich kürzere Trainingszeiten und damit eine höhere Anzahl vollständiger Experiment-Wiederholungen — eine Voraussetzung statistischer Aussagekraft. Drittens liefern die typisierten Treffer der Detectable Tags direkt interpretierbare Information darüber, welcher Hindernistyp wahrgenommen wurde; in der Generalisierungsanalyse (@sec:generalisierung) lässt sich damit untersuchen, woran das Verhalten auf ungesehenen Karten scheitert (F3). Der ursprünglich erwogene Sensormodalitäts-Vergleich (Kamera, Sensor-Fusion) wird als zurückgestellte Erweiterung im Ausblick (@sec:ausblick) wieder aufgegriffen.

@tab:sensorspez spezifiziert den vollständigen Sensor- und Beobachtungssatz der drei Vergleichsagenten. Die Tabelle ist die autoritative und einzige Quelle dieser Spezifikation; alle übrigen Stellen der Arbeit verweisen hierher, ohne Werte zu wiederholen.

#figure(
  table(
    columns: 4,
    align: (left, center, left, left),
    [*Komponente*], [*Dimension*], [*Inhalt*], [*Wertebereich*],
    [RayPerceptionSensor3D (horizontal)], [176], [11 Rays ($2 times 5 + 1$) über 120° (MaxRayDegrees 60), Reichweite 12, SphereCast 0.25; 6 Detectable Tags (Wall, Obstacle, Lava, Hole, Goal, Bridge); je Ray Tag-Kodierung, Trefferflag und normierte Distanz; stacked = 2], [$[0,1]$ (automatisch normalisiert)],
    [Boden-Sensor (manuell, VectorSensor)], [18], [9 Raycasts abwärts (Reichweite 2), Positionen unter/vorne 1--2/diagonal/seitlich; je \[Typ-Code, norm. Distanz\]; Codes: Floor $+1$, Bridge $+0.5$, Hole $-0.5$, Lava $-1$, kein Treffer $-1.5$], [Typ-Code $[-1.5, 1]$; Distanz $[0,1]$],
    [Eigengeschwindigkeit], [3], [lokale Geschwindigkeit, normiert auf moveSpeed], [ca. $[-1, 1.6]$],
    [Bodenkontakt], [1], [isGrounded-Flag], [${0,1}$],
    [Zieldistanz], [1], [Distanz zum Ziel / maxObservationDistance (20), ungeclampt], [$[0, approx 2.25]$],
    [Zielrichtung], [3], [normierter Richtungsvektor zum Ziel], [$[-1,1]$],
    [Wand-Raycasts], [4], [normierte Distanzen in vier Richtungen], [$[0,1]$],
    [Line-of-Sight], [1], [Sichtlinien-Flag zum Ziel], [${0,1}$],
  ),
  caption: [Vollständige Sensor- und Beobachtungsspezifikation der drei Vergleichsagenten (autoritative Quelle): 31 Vektor-Beobachtungen plus 176 Ray-Beobachtungen.],
) <tab:sensorspez>
// TODO: Wertebereiche (Velocity ~1.6, Zieldistanz ungeclampt ~2.25) final gegen
// den Code verifizieren.

== Reward-System <sec:reward-system>

Die Belohnungsfunktion ist für alle drei Architekturen identisch und wurde vor Beginn der Vergleichsläufe festgeleg (@tab:reward). Sie bildet damit die gemeinsame Zielvorgabe des Experiments. F1 und F2 sollen Unterschiede der Netzarchitektur messen, nicht des Belohnungsdesigns. Das Vergleichsdesign, das auf dieser Konstanz aufbaut, wird in Kapitel 5 entwickelt. Die Herleitung der einzelnen Terme sowie ihre beobachtete Wirkung sind bewusst nicht Gegenstand dieses Kapitels. Sie gehören zur Entstehungsgeschichte des Systems und werden in Kapitel 7 behandelt. Hier wird ausschließlich die gemeinsame, im Experiment unveränderte Belohnungsfunktion beschrieben.

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
    [Lava-Überquerung], [+8], [],
    [Loch-Überflug], [−1], [],
    [Sichtlinie zum Ziel (Line-of-Sight)], [+0.005], [],
    [Wall-Climb], [−1], [vgl. @sec:iterationen],
    [phaseMaxSteps], [600 / 1200 (vier Phasen) / 1500 / 2000 / 2500], [maximale Episodenlänge je Curriculum-Phase (@tab:curriculum)],
    [Vergabe], [zentral im LabyrinthAgent], [externe Trigger (Lava, KillZone) melden ausschließlich über OnTriggerEnter],
  ),
  caption: [Belohnungsfunktion der drei Vergleichsagenten — identisch für alle Architekturen und vor den Vergleichsläufen eingefroren. Die Curiosity-Stärken je Behavior sind Teil der Trainer-Konfiguration und stehen in @tab:yaml-abweichungen.],
) <tab:reward>

== Trainingsinfrastruktur

Das Training läuft in einer Python-Umgebung (venv) mit ML-Agents 0.30.0, die für den Vergleich benötigte Transformer-Policy ist in dieser Version nicht enthalten und wird über ein Patch-Skript in die virtuelle Umgebung nachgerüstet. Der venv-Patch hält die Nachrüstung reproduzierbar und auf wenige, klar umrissene Eingriffe begrenzt. Begründung und Integrationsprozess dokumentiert @sec:transformer-integration.

Die Trainer-Konfigurationen unterscheiden sich systematisch zwischen den Architekturen, maßgeblich für den Vergleich ist model_comparison_final_v3.yaml. Abweichungen und ihre Begründung dokumentiert @sec:yaml-abweichungen. Die Bestandteile der Trainingsinfrastruktur fasst @tab:traininginfra zusammen.

// TODO: PyTorch-Version der Trainings-venv per "pip show torch" verifizieren und in
// @tab:traininginfra festschreiben (2.0.1+cu118 ist bislang nur in der Arbeitshilfe
// dokumentiert; der Segfault-Workaround-Kommentar in transformer_policy.py stützt 2.0.x).
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
    [Patch], [`training/patch_mlagents.py`: kopiert `transformer_memory.py`, erweitert `settings.py` und `networks.py`; `start_training.py` wendet den Patch automatisch an],
    [Export-venv], [separat (`setup_and_export.ps1`), `torch` 1.8.1+cpu],
    [Historische Solo-Konfigurationen (Meilenstein 7)], [`labyrinth_training.yaml` (PPO-Baseline: Lernrate 3e-4, Batch 512, Buffer 10 240, $gamma$ = 0.99, MLP 256 × 2, normalize false, max_steps 6.4 M); `labyrinth_transformer.yaml` (sequence_length 16, memory_size 128, Curiosity 0.05, $gamma$ = 0.997, max_steps 60 M); `labyrinth_lstm*.yaml`],
    [Vergleichslauf F1--F3 (maßgeblich)], [`model_comparison_final_v3.yaml`: drei Behaviors in einem Lauf; identische Basisparameter in Abschnitt 5.3.1, sämtliche Abweichungen ausschließlich in @tab:yaml-abweichungen],
    [Parallelisierung], [Multi-Area (@tab:mapgen) plus Headless-Prozesse über `--num-envs`; je Worker ein eigener gRPC-Port und eine eigene Curriculum-State-Datei],
  ),
  caption: [Trainingsinfrastruktur: Umgebungen, Patch-Mechanismus und Konfigurationsebenen.],
) <tab:traininginfra>



// ============================================================================
// 5. METHODIK UND EXPERIMENTELLES DESIGN  — nach dem System
//ALLE ============================================================================
= Methodik und experimentelles Design

== Wissenschaftliche Rahmung //DAVID
// ARBEITSTEILUNG (keine Nacherzählung von 1.5): Die Einleitung stellt die Fragen,
// die Methodik macht sie messbar. 5.1 ist deshalb eine Operationalisierungstabelle,
// kein Fließtext-Recap; die Metrik-DEFINITIONEN (80-%-Schwelle, gleitendes Fenster,
// Overfitting-Index-Formel, Eval-Set) stehen ausschließlich in @sec:evalprotokoll.

#figure(
  table(
    columns: 5,
    align: (left, left, left, left, left),
    [*Frage*], [*Metrik*], [*Hypothese*], [*zuständiger Vergleich*], [*beantwortet in*],
    [F1: Mehrwert temporalen Gedächtnisses], [Erfolgsrate (Definition: @sec:evalprotokoll)], [H1], [MLP vs. LSTM/Transformer], [@sec:architekturvergleiche],
    [F2: LSTM vs. Transformer], [Konvergenzgeschwindigkeit; finaler Leistungsscore (Definitionen: @sec:evalprotokoll)], [H2], [LSTM vs. Transformer], [@sec:architekturvergleiche],
    [F3: Generalisierung auf unbekannte Maps], [Overfitting-Index auf held-out Maps (Definition: @sec:evalprotokoll)], [H3], [alle drei Architekturen], [@sec:generalisierung],
  ),
  caption: [Operationalisierung der Forschungsfragen: Metrik, Hypothese, zuständiger Vergleich und Ergebnis-Abschnitt.],
) <tab:operationalisierung>

== Vergleichsdesign //maybe besseren Namen finden wird jetzt mit wissenschaflticher Rahmung fussioniert (war davor eigenständige Überschrift, hier soll nur kurz erklärt werden )
// Transformer, LSTM, MLP 
//DAVID



== Kontrollierte Variablen und begründete Abweichungen //ALEX

// - VORSPANN (Grundprinzip): pro Vergleich ändert sich nur EINE Variable,
//   alles andere ist eingefroren -> Messgrundlage für die Unterabschnitte.

=== Identische Parameter //ALEX

// - Wirklich identisch für alle drei Behaviors (model_comparison_final_v3.yaml):
//   epsilon 0.2, lambd 0.95, num_epoch 3, hidden_units 256, num_layers 2,
//   max_steps 30M, seed 42, num_envs 3, Checkpoint-/Summary-Takt
//   (NICHT in dieser Liste: alle abweichenden Parameter — die stehen
//   ausschließlich in @tab:yaml-abweichungen in 5.3.2, dort als begründete
//   "Best vs. Best"-Abweichungen geführt; hier nicht wiederholen)
// - Reward-Struktur identisch und VOR dem Training eingefroren
// - Sensor-Basis und Seeds identisch
Das Grundprinzip des Anforderungskatalogs meint, dass sich zwischen den Agenten nur der Vergleichsgegenstand unterscheidet.Alles andere bleibt gleich. Dies ist in zwei Ebenen umgesetzt.
Die erste Ebene ist die Umgebung und ist vollständig identisch, da alle drei Architekturen gleichzeitig im selben Trainingslauf trainieren. Das bedeutet, dass bei allen drei Architekturen die gleiche Szene, die gleichen Karten, das gleiche Curriculum mit exakt denselben Erfolgs-Gattern und Episodenlimits vorliegt. Ebenfalls teilen sich alle drei die gleiche Physik und die gleiche Belohnungsfunktion. Auch das Agentenskript und der Beobachtungsraum sind identisch, da jeder Agent dieselben 31 Vektorobservations inklusive Zielrichtungsvektor und dieselbe Ray-Sensorik bekommt. Auch Unterbrechungen und Neustarts während des Trainings wirken sich gleichermaßen auf alle aus.
Die zweite Ebene ist die Trainer-Konfiguration. Hier sind alle Parameter identisch, die  nicht im nachfolgenden Abschnitt 5.3.2 als begründete Abweichung aufgeführt werden.

=== Notwendige YAML-Abweichungen und ihre Begründung <sec:yaml-abweichungen> //ALEX

// EINZIGE HEIMAT der Abweichungsliste — 1.6, 4.6 und Kap. 10 verweisen nur
// hierher (@tab:yaml-abweichungen), keine Kopien. Volle YAMLs im Anhang.
// Quelle: 02_Anforderungen_Fairer_Vergleich.md (Abschnitt A.2)

Die Trainer-Konfigurationen der drei Architekturen (model_comparison_final_v3.yaml) sind nicht zu 100 % identisch — und das ist methodisch korrekt. Die Abweichungen zerfallen in zwei Klassen. Konstitutiv ist einzig memory_type: Ohne diesen Parameter gäbe es keinen Vergleichsgegenstand — man kann Transformer und LSTM nicht vergleichen, ohne memory_type zu ändern; eine erzwungene 100-%-Identität wäre nicht „fairer", sondern sinnlos. Daneben stehen nicht-konstitutive Tuning-Abweichungen nach dem Prinzip „Best vs. Best": Jede Architektur läuft mit ihrer jeweils besten bekannten Konfiguration. @tab:yaml-abweichungen listet sämtliche Abweichungen; max_steps (30 M), seed (42) und die in Abschnitt 5.3.1 genannten Parameter sind für alle drei Behaviors identisch. Die vollständigen YAML-Konfigurationen sind im Anhang dokumentiert.

#figure(
  table(
    columns: 5,
    align: (left, center, center, center, left),
    [*Parameter*], [*MLP*], [*LSTM*], [*Transformer*], [*Begründung*],
    [memory_type], [—], [lstm], [transformer], [konstitutiv: definiert den Vergleichsgegenstand],
    [learning_rate], [3e-4 (linear)], [3e-4 (linear)], [1e-4 (constant)], [Best vs. Best: Transformer-Stabilität],
    [batch_size], [512], [512], [1024], [Best vs. Best],
    [buffer_size], [40960], [40960], [81920], [Best vs. Best],
    [beta], [5e-3 (linear)], [5e-3 (linear)], [5e-4 (constant)], [Best vs. Best],
    [time_horizon], [512], [512], [256], [Best vs. Best],
    [gamma], [0.995], [0.995], [0.997], [Best vs. Best],
    [normalize], [false], [true], [false], [Best vs. Best],
    [Curiosity-Stärke], [0.05], [0.05], [0.02], [Best vs. Best; Curiosity selbst ist in allen drei Behaviors aktiv (Fairness-Kriterium R5)],
  ),
  caption: [Abweichungen der Trainer-Konfigurationen zwischen den Architekturen (model_comparison_final_v3.yaml). Alle übrigen Parameter sind identisch (Abschnitt 5.3.1); vollständige YAMLs im Anhang.],
) <tab:yaml-abweichungen>

Konsequenz dieser Abweichungen ist, dass kein strenger Kausalanspruch erhoben wird: Leistungsunterschiede (F1/F2) sind nicht allein der temporalen Architektur zuzuschreiben. Der Anspruch ist in der Abgrenzung (Kapitel 1) entsprechend abgeschwächt formuliert; die Abweichungen werden in @sec:limitationen als Limitation geführt.
// TODO ALEX: Begründungsspalte je Zeile gegen die YAML-Kommentare schärfen
// (welches konkrete Stabilitäts-/Tuning-Argument steckt hinter jedem Wert?)

== Abweichung in Tuning-Iterationen <sec:tuning-abweichungen>

Nachdem in den vorangegangenen Abschnitten das Vergleichsdesign und die kontrollierten Variablen beschrieben wurden, dokumentiert dieser Abschnitt die im Verlauf der Arbeit durchgeführten Tuning-Iterationen und die dabei aufgetretenen Abweichungen zwischen erwartetem und tatsächlich beobachtetem Trainingsverhalten. Beim Training von Reinforcement-Learning-Agenten sind solche Abweichungen kein Randphänomen, sondern der Regelfall: Die Wechselwirkungen zwischen Belohnungsfunktion, Beobachtungsraum, Netzarchitektur und Hyperparametern sind im Vorfeld nur begrenzt vorhersagbar, sodass sich das tatsächliche Agentenverhalten erst im Experiment zeigt. Die systematische Dokumentation dieser Abweichungen ist daher ein wesentlicher Bestandteil der wissenschaftlichen Nachvollziehbarkeit dieser Arbeit: Sie macht transparent, welche Entwurfsentscheidungen sich bewährt haben, welche verworfen wurden und aus welchen Gründen.

Dabei fällt auf, dass sich der Tuning-Aufwand sehr ungleich auf die drei Architekturen verteilt: der Transformer durchlief deutlich mehr Iterationen als die MLP-Baseline. Diese Asymmetrie ist nicht methodischer Nachlässigkeit geschuldet, sondern strukturell bedingt. Das MLP ist als Standardarchitektur nativ in Unity ML-Agents integriert und läuft mit den dokumentierten PPO-Standardwerten weitgehend ohne Anpassungsbedarf --- es ist die am einfachsten zu implementierende der drei Architekturen. 

=== Vorgehensweise und Bewertungsgrundlage

Jede Tuning-Iteration wurde nach einem einheitlichen Schema durchgeführt und bewertet. Ausgehend von einer Hypothese über eine erwartete Verbesserung wurde eine Konfigurationsänderung vorgenommen, ein Trainingslauf gestartet und dessen Verlauf anhand der über TensorBoard protokollierten Metriken analysiert. Als Bewertungsgrundlage dienten dabei der durchschnittliche kumulierte Episoden-Reward (Environment/Cumulative Reward) als Hauptindikator, dessen Standardabweichung als Maß für die Stabilität der Policy, die mittlere Episodenlänge sowie ergänzend die Verlustgrößen des Trainings (Policy Loss, Value Loss) und die Entropie der Policy als Indikator für den Explorationsgrad. Eine Abweichung liegt im Sinne dieses Abschnitts immer dann vor, wenn das beobachtete Verhalten von der zuvor formulierten Erwartung abweicht, unabhängig davon, ob die Abweichung negativ oder positiv ausfällt.

=== Iterationen der MLP-Baseline

Für die MLP-Baseline des Architekturvergleichs waren keine architekturspezifischen Hyperparameter-Iterationen erforderlich: Es wurde genau ein Trainingslauf durchgeführt, der ohne nennenswerte Komplikationen bis zum Ende des Trainingsbudgets durchlief. Die Konfiguration wurde einmalig aus den dokumentierten PPO-Standardwerten des Frameworks abgeleitet, im Rahmen des Vergleichsdesigns eingefroren und während des Laufs zu keinem Zeitpunkt verändert. Gerade dieser Befund --- dass die Baseline ohne eigenes Tuning und ohne Wiederholungsläufe auskam, während der Transformer eine umfangreiche Iterationshistorie erforderte --- ist der empirische Beleg für die eingangs beschriebene Asymmetrie des Tuning-Aufwands: Sie spiegelt nicht unterschiedliche Sorgfalt wider, sondern den unterschiedlichen Reifegrad der Framework-Integration der drei Architekturen.

Abweichungen im Sinne dieses Abschnitts traten bei der MLP-Baseline dementsprechend nicht auf der Ebene der Hyperparameter oder des Trainingsablaufs auf. Die Abweichungen der Baseline liegen vielmehr auf der Verhaltensebene --- in den strukturellen Grenzen einer gedächtnislosen Policy, wie sie in @sec:mlp-baseline als Erwartung formuliert wurden. Ob und in welchem Ausmaß diese erwarteten Grenzen im Trainingsverlauf tatsächlich beobachtbar sind, wird zusammen mit den finalen Ergebniszahlen in @sec:eval-mlp-baseline dargestellt und eingeordnet.


== Evaluationsprotokoll <sec:evalprotokoll> //FINN kann ich erst schreiben wenn evaluier

// EINZIGE HEIMAT der Metrik-Definitionen (HIERHER GEZOGEN aus 1.5 — dort stehen
// nur noch die Fragen + grober Mess-Hinweis; 5.1 mappt nur Frage->Metrik):
// - Erfolgsrate := Anteil erfolgreich abgeschlossener Episoden (separate
//   Evaluationsläufe im Inference-Modus nach Trainingsabschluss)
// - Konvergenzgeschwindigkeit := Anzahl Trainingsschritte bis zum NACHHALTIGEN
//   Überschreiten einer Erfolgsrate von 80 % im gleitenden Fenster
// - finaler Leistungsscore := mittlerer kumulativer Episoden-Reward in separaten
//   Evaluationsläufen
// - Overfitting-Index := Trainings-Erfolgsrate − Generalisierungs-Erfolgsrate
// - Eval-Set: fixierte, vor Trainingsbeginn eingefrorene Evaluation-Maps, im
//   Training nie verwendet (bisher 3 — s. TODO-Block: ggf. 30-100 je Stufe)
// Diese Definitionen VOR den finalen Läufen fixieren.

=== Primärmetriken //FINN kann ich erst schreiben wenn evaluiert
// - Erfolgsrate, Konvergenzgeschwindigkeit, Kollisionsrate,
//   Mean Episodenlänge, Cumulative Reward
// - PRIMÄRE Erfolgsmessung (F1/F2): separate Evaluationsläufe im
//   Inference-Modus auf einem fixen, für alle drei Architekturen
//   identischen Map-Set. Grund: der Curriculum-Stand am Trainingsende
//   kann zwischen den Architekturen differieren — bleibt z. B. der MLP
//   auf einer früheren Stufe hängen, sind die "letzten 100 Trainings-
//   Episoden" zwischen den Architekturen nicht vergleichbar; nur ein
//   identisches Eval-Set macht die Messung architekturübergreifend gültig
// - Trainings-Erfolgsrate NUR als Verlaufs-/Sekundärmetrik führen — KEINE
//   "Ungesehen"-Interpretation: der Hard-Pool besteht aus 192 eingefrorenen
//   Layouts, die sequenziell zyklisch durchlaufen werden (bei threshold
//   20 000 Episoden wird jedes Layout ~100x wiederholt), und das Curriculum
//   springt nach Hard per loopPhases zurück auf Easy. Der Generalisierungs-
//   Nachweis läuft daher ausschließlich über das separate Inference-Eval-Set
//   (s. o., wie ohnehin vorgesehen)
// - Konvergenzkriterium (F2): NACHHALTIGES Überschreiten der 80-%-
//   Erfolgsrate im gleitenden Fenster, nicht erstmaliges Erreichen
//   -> robust gegen Rauschen
// - Eval-Map-Set und Konvergenzkriterium VOR den finalen Läufen fixieren

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


== MLP-Baseline <sec:eval-mlp-baseline>

Die Aufgabenstellung der vorliegenden Arbeit fordert neben dem Transformer-basierten Entscheidungsmodell explizit den Vergleich mit einer einfachen Basisvariante. Diese Rolle übernimmt die in diesem Abschnitt beschriebene MLP-Baseline: ein Agent, dessen Entscheidungsmodell aus einem einfachen Multilayer-Perzeptron ohne jede Form von Gedächtnis besteht. Im Folgenden werden zunächst die Rolle der Baseline im Untersuchungsdesign und der Aufbau des Netzes erläutert. Anschließend werden Beobachtungsraum, Aktionsraum, Belohnungsstruktur und Episodenlogik spezifiziert und abschließend die Erwartung an die Baseline formuliert. Der Trainingsverlauf und die Ergebniszahlen werden gemäß der Kapitelstruktur dieser Arbeit erst in der Evaluation dargestellt (@sec:eval-mlp-baseline).

=== Rolle der Baseline im Untersuchungsdesign

Die MLP-Baseline erfüllt im Untersuchungsdesign dieser Arbeit zwei Funktionen. Erstens dient sie als unterer Vergleichsanker: Sie beantwortet die Frage, welche Leistung in der entwickelten Labyrinthumgebung bereits ohne Gedächtnis erreichbar ist. Nur vor diesem Hintergrund lässt sich der Mehrwert gedächtnisbehafteter Architekturen --- LSTM und Transformer --- überhaupt quantifizieren. Zweitens diente die Baseline als technischer Nachweis, dass die gesamte Trainingspipeline aus Unity-Umgebung, ML-Agents-Anbindung, Belohnungslogik und Protokollierung funktionsfähig ist, bevor komplexere Modellvarianten untersucht wurden.

Damit der spätere Architekturvergleich wissenschaftlich belastbar ist, wurde vor dem Training ein Grundprinzip festgelegt: Zwischen den zu vergleichenden Agentenvarianten soll sich möglichst nur eine Variable unterscheiden --- die Modellarchitektur beziehungsweise der Gedächtnistyp ---, während alle übrigen Randbedingungen identisch bleiben. Hierzu wurden die Belohnungsstruktur, die Umgebungskonfiguration und die gemeinsamen Trainingsparameter vor dem ersten Vergleichslauf dokumentiert und eingefroren; die wenigen begründeten Abweichungen zwischen den Trainer-Konfigurationen sind in @sec:yaml-abweichungen dokumentiert. Die in den folgenden Teilabschnitten beschriebene Konfiguration der MLP-Baseline definiert damit zugleich die Referenzkonfiguration für alle weiteren Modellvarianten dieser Arbeit.

=== Aufbau des Multilayer-Perzeptrons

Das Multilayer-Perzeptron (MLP) ist die Grundform des vorwärtsgerichteten neuronalen Netzes. Es besteht aus einer Eingabeschicht, einer oder mehreren versteckten Schichten und einer Ausgabeschicht, wobei jede Schicht eine affine Transformation ihrer Eingabe mit anschließender nichtlinearer Aktivierungsfunktion berechnet. @goodfellow_deep_2016

Entscheidend für die Rolle als Baseline ist eine strukturelle Eigenschaft des MLP: Es verarbeitet ausschließlich die Beobachtung des aktuellen Zeitschritts. Es existiert kein interner Zustand, der Informationen über vergangene Beobachtungen speichert --- die Policy ist rein reaktiv. Beobachtet der Agent in zwei unterschiedlichen Situationen denselben Beobachtungsvektor, wählt er zwangsläufig dieselbe Aktionsverteilung, unabhängig davon, wie er in diese Situationen gelangt ist. @goodfellow_deep_2016

In der vorliegenden Arbeit wird das MLP in der Standardkonfiguration des ML-Agents-Frameworks verwendet: Der Beobachtungsvektor wird durch zwei versteckte Schichten mit jeweils 256 Neuronen verarbeitet. Auf diesen gemeinsamen Netzrumpf setzen im PPO-Training zwei Ausgabeköpfe auf: die Policy, welche die Wahrscheinlichkeitsverteilungen über die diskreten Aktionen ausgibt, und der Wertschätzer (Critic), der den erwarteten Gesamtertrag des aktuellen Zustands schätzt. @juliani_unity_2020


=== Erwartung an die Baseline

Aus der Spezifikation lässt sich die Erwartung an die Baseline unmittelbar ableiten. Dank der Zielrichtungs-Observation und der Ray-Sensorik sollte das MLP in der Lage sein, eine reaktive Zielansteuerung mit lokaler Gefahrenvermeidung zu erlernen und die Navigationsaufgabe in der Mehrzahl der Episoden zu lösen. Zugleich markiert die Gedächtnislosigkeit eine strukturelle Obergrenze: In Situationen, deren korrekte Behandlung Wissen über die eigene Vorgeschichte erfordert --- insbesondere das Erkennen bereits erkundeter Bereiche und das systematische Verlassen von Sackgassen ---, kann eine rein reaktive Policy prinzipbedingt keine optimale Entscheidung treffen @hausknecht_deep_2015. Die Baseline wird daher erwartungsgemäß unterhalb der theoretisch möglichen Leistung sättigen. 



== Transformer-Memory (Custom Policy)//FINN

// - d_model 256, nhead 4, num_layers 2; gelerntes Positional Encoding
// - manuelle MultiheadAttention, batch_first = False; ~1,07 Mio. Parameter
// - (Bau-/Debugging-Prozess: siehe 7.6)


== LSTM-Memory (Custom Policy)//ALEX

// - Vergleichs-Config (model_comparison_final_v3.yaml): memory_size 256 ->
//   hidden_size 128 (LSTMMemory: hidden = memory_size/2), num_layers 1;
//   ~198k Parameter. (hidden 64 / ~82k galt nur für die alte
//   labyrinth_lstm.yaml mit memory_size 128)
// - Patch-Strategie: additive elif-Bloecke in mlagents NetworkBody
// - Output-Shape GAE-kompatibel


// ============================================================================
// 7. UMSETZUNG NACH MEILENSTEINEN  (mit Kernabschnitt 7.6)
//Hauptteil ALEX, kleine teile katya und finn ============================================================================
= Umsetzung
// wie das System ENTSTANDEN ist — Kapitel 4 liefert ZUSTAND, Kapitel 7 GENESE.
// PRÜFREGEL je Satz: "Steht das schon in Kapitel 4? -> Verweis statt Wiederholung."
// FILTER je Inhalt: Welche Entscheidung wurde REVIDIERT, welches PROBLEM trat
// auf, was wurde GELERNT? Nur das bleibt — alles andere ist Füllstoff.
// STRUKTURENTSCHEIDUNG (Review): früher 7.1-7.5 zu EINEM verdichteten Abschnitt
// "Aufbauphase (M1-M6)" von 2-4 Seiten zusammengefasst; die Problemklassen-
// Darstellung (Transformer-Integration) ist der HAUPTTEIL des Kapitels.

== Aufbauphase (M1--M6)
// VERDICHTET aus früher 7.1-7.5 — nur Entstehung, kein Endzustand:
//
// - Umgebung (früher 7.1): NICHT das Datenmodell/die Generierung erklären
//   (steht in 4.2) — den ÜBERGANG erzählen: warum von 5 manuellen Layouts auf
//   prozedural (Messbarkeits-/Skalierungsgrund, Rückgriff §1.4); welches
//   konkrete Problem der Custom Editor (Preview) löste.
// - Hindernis-/Terminierungslogik (früher 7.2): nur die Entscheidungsebene —
//   warum tag-basiert, welche Alternative wurde verworfen; welches Problem
//   die KillZone-Mechanik löste.
// - Agent und Wahrnehmung (früher 7.3): Sensor-BESCHREIBUNG GESTRICHEN
//   (steht in @sec:sensorik) — es bleiben Sprungkalibrierung und gescheiterte
//   Zwischenstände.
// - Belohnungsdesign (früher 7.4): Herleitung und WIRKUNG der Reward-Terme
//   (Abgrenzung zu 4.5: dort nur die fixe, gemeinsame Funktion); warum
//   zentrale Reward-Vergabe statt verteilt in den Hindernis-Skripten
//   (Kopplung an die Todeslogik). YAML-Bullet GESTRICHEN (-> 5.3.2/Anhang).
// - Training und Curriculum (früher 7.5): welches Übergangskriterium zwischen
//   den Phasen, was daran revidiert wurde; Multi-Area nur als Entstehungs-
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
Der vierte Meilenstein verwandelt die bisher problemlos begehbare Karte in eine Aufgabe mit Risiko. Das in Meilenstein 1 beschriebene Zellmodell wird um die Hindernisse Lava und Loch erweitert. Getaggte Trigger dieser Hindernisse melden Kontakte über OnTriggerEnter an die Todeslogik des Agenten, welche daraufhin die Episode beendet. Für die Wahrnehmung des Agenten wird der RayPerceptionSensor des Frameworks konfiguriert. Dazu tasten Strahlenbündel die Umgebung ab und klassifizieren Treffer über die in Meilenstein 1 beschriebenen Objekt-Tags. Eine dedizierte Sensor-Testszene sicher die Erkennung von Objekten isoliert ab.

=== Meilenstein 5: Reward-System und erstes Training
Innerhalb des fünften Meilensteins werden die letzten, für ein erstes Training nötigen Schritte umgesetzt. Die Belohnungsfunktion kombiniert eine Zielprämie mit Todesstrafen für die Hindernisse Lava und Loch, sowie einer Timeout-Strafe, einer kleinen Zeitstrafe je Schritt und einem potentialbasierten Distanz-Shaping, welches Annäherungen an das Ziel kontinuierlich belohnt. Vergeben wird diese Prämie zentral im LabyrinthAgent. Mit der LabyrinthAgent.yaml entsteht die erste PPO-Trainerkonfiguration. Unmittelbar darauf folgen die ersten Trainingsläufe der MLP-Baseline, welche parallel zu Meleinstein 5 implementiert wurde.

=== Meilenstein 6: Prozedurale Generierung und Curriculum
Der sechste Meilenstein professionalisiert die Kartenerzeugung und legt somit das Fundament des Curriculum-Lernens. Ein Raum-Korridor-Graph erzeugt die Topologie (Räume, Korridore und Verzweigungen). Ein semantischer Pathfinder validiert jede erzeugte Karte auf deren Lösbarkeit. Unlösbare Kandidatenkarten werden sofort verworfen und anschließend neu generiert. Ein in diesem Meilenstein eingeführtes Schwierigkeits-Enum systematisiert die Karten in Klassen von Trivial über Easy, Medium und Hard bis zu spezialisierten Lernstufen. Ein Objekt-Pool (TilePool) häufiger Kartenwechsel möglichst gering. Da die Generierung seed-basiert und somit deterministisch reproduzierbar ist, lassen sich Kartensätze sauber trennen. Diese Trennung ist die Voraussetzung für die spätere Generalisierungsmessung. Des Weiteren entsteht innerhalb dieses Meilensteins das Curriculum-System. Die CurriculumConfig beschreibt hierbei die Phasen mit Kartenklassen und Aufstiegsschwellen. Der CurriculumTracker steuert den Phasenfortschritt zur Laufzeit. Phasenspezifische Episodenlängen begrenzen Timeout-Episoden je Schwierigkeitsgrad.

Damit ist die Aufbauphase abgeschlossen und bildet somit die Basis für die Integration und Optimierung der Gedächtnisarchitekturen, deren jeweilige Umsetzung in den nachfolgenden Abschnitten näher erläutert wird.



== Transformer-Integration: von V1 bis zum lauffähigen Modell <sec:transformer-integration> //FINN

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

// - PPO-Ratio-Inkonsistenz: Inference (seq=1) != Training (seq=N;
//   historisch seq=8)
// - Lsung: Rolling-Memory-Buffer der letzten seq_len−1 MLP-Encodings
//   (damals seq 8 -> 7 Encodings, aktuelle Configs seq 16 -> 15)
//   -> konsistente Log-Probs, gültige PPO-Ratio

=== Problemklasse C - Reward-/Curriculum-Pathologien

// - Sparse Reward (Goal in 1 Mio. Steps nie gefunden) -> Trivial-Phase + PBRS
//   + Distanz-Observation
// - Wall-Climb (PhysX-Depenetration) -> Guard + maxUpwardVelocity-Cap
//   [EINZIGE HEIMAT der Wall-Climb-Erzählung (Entdeckung, Diagnose, Korrektur
//   V11/V12, vgl. @sec:iterationen) — 4.3.3 nennt nur den Endzustand + Verweis]
// - Eck-Heuristik/Memorierung -> Goal-Variation über den Layout-Pool
//   (Generierungszeit, 100-200 Seeds je Stufe), nicht zur Laufzeit;
//   Laufzeit-Meide-Logik ist nur Fallback
// - PBRS farmbar; Discount-Faktor entscheidend

=== Iterationsübersicht V1-V22 (verdichtete Tabelle) <sec:iterationen>

// - Tabelle: Version | Hypothese/Ã„nderung | Kennzahl-Wirkung (belegt) | Erkenntnis
// - vollständige Tabelle + Einzel-Kennzahlen (TensorBoard-Belege) im Anhang
// - Auszug bekannter Iterationen:
//     V5  kein Causal Mask -> kein Lernen
//     V6  Beta zu hoch, Entropy fällt nicht
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

== MLP-Integration <sec:mlp-integration>

Nachdem in @sec:eval-mlp-baseline die MLP-Baseline auf konzeptioneller Ebene spezifiziert wurde, beschreibt dieser Abschnitt ihre technische Integration: die Anbindung der Unity-Umgebung an die ML-Agents-Trainingspipeline, die Umsetzung des Agenten im Code und im Unity-Inspector, den Aufbau der Trainingsszene sowie die Durchführung und Überwachung des Trainings. Der Trainingsverlauf ist in @sec:tuning-abweichungen dokumentiert; die abschließende Einordnung der Ergebnisse erfolgt in @sec:eval-mlp-baseline.

Vorab ist der Integrationsaufwand einzuordnen, der sich zwischen den drei Architekturen deutlich unterscheidet: Die MLP-Integration ist mit Abstand die einfachste. Das MLP ist die Standardarchitektur des ML-Agents-Frameworks und nativ in dessen Trainingspipeline enthalten --- weder die Netzarchitektur noch der Python-Trainer mussten angepasst werden. Der hier beschriebene Aufwand beschränkt sich daher auf die Anbindung von Umgebung und Agent, die ohnehin die gemeinsame Grundlage aller drei Architekturen bildet. Diese Asymmetrie ist gewollt und dokumentiert (@sec:tuning-abweichungen): Während das LSTM ebenfalls über eine native Framework-Konfiguration einbindbar war, erforderte der Transformer einen Patch der Trainingsumgebung mit entsprechendem Iterationsbedarf (@sec:transformer-integration). Die MLP-Integration diente damit zugleich als Fundament, auf dem die aufwendigeren Integrationen aufsetzen konnten.

=== Systemarchitektur der ML-Agents-Anbindung

Das Training der Baseline basiert auf dem Zusammenspiel zweier Prozesse. Die Unity-Engine simuliert die Spielwelt: Der Agent bewegt sich in der Labyrinthumgebung, sammelt Beobachtungen und erhält Belohnungen gemäß der spezifizierten Struktur. Parallel dazu läuft außerhalb von Unity der Python-Trainingsprozess mlagents-learn, der die Beobachtungen und Belohnungen des Agenten empfängt, das neuronale Netz mit PPO aktualisiert und dem Agenten die Aktionen der aktuellen Policy zurückliefert. Beide Prozesse kommunizieren über eine lokale gRPC-Netzwerkverbindung (Port 5004) und müssen während des Trainings gleichzeitig laufen. Der Lernfortschritt wird kontinuierlich als Ereignisprotokoll geschrieben und kann parallel zum Training mit TensorBoard im Browser visualisiert werden. @juliani_unity_2020

=== Integration des Agenten in Unity

Für die Integration wurde ein durchgängiges Strukturierungsprinzip angewandt: Die Funktionslogik des Agenten liegt vollständig im Code, während der Unity-Inspector ausschließlich der Konfiguration und Verdrahtung von Komponenten dient. Diese Trennung hält die Logik nachvollziehbar und versionierbar, während Parameter wie Sensorreichweiten oder Belohnungswerte ohne Codeänderung angepasst werden können.

Kern der Integration ist die Agentenklasse LabyrinthAgent, die von der Agent-Basisklasse des ML-Agents-Frameworks erbt und deren Lebenszyklus-Methoden überschreibt. @juliani_unity_2020 Beim Episodenstart (OnEpisodeBegin) stößt der Agent das Laden eines neuen Layouts an und wird auf die Spawn-Position versetzt. Zu jedem Entscheidungszeitpunkt sammelt CollectObservations die Beobachtungen. Die vom Modell gewählten Aktionen werden in OnActionReceived entgegengenommen, in physikbasierte Bewegung, Drehung und Sprung übersetzt und mit der Schrittstrafe belegt. Die Terminalereignisse --- Zielerreichung sowie Tod durch Lava oder Loch --- werden über Trigger-Collider erkannt. Die Umgebungsobjekte lösen lediglich das Trigger-Ereignis aus, während die gesamte Belohnungsvergabe und Episodensteuerung zentral in der Agentenklasse erfolgt. Diese Zentralisierung stellt sicher, dass alle Belohnungswerte an einer einzigen, im Inspector konfigurierbaren Stelle liegen und für den Architekturvergleich eingefroren werden können.

Auf dem Agenten-Prefab sind drei Framework-Komponenten konfiguriert. Die Behavior Parameters definieren die Schnittstelle zwischen Agent und Trainer: den Verhaltensnamen MLP_Navigator, die Größe des manuellen Beobachtungsvektors (vgl. @tab:sensorspez) sowie den diskreten Aktionsraum mit drei Zweigen (Bewegung, Drehung, Sprung). Der RayPerceptionSensor3D ist als eigene Sensorkomponente direkt am Agenten angebracht und im Inspector konfiguriert; seine Beobachtungen werden vom Framework automatisch an das Netz übergeben. Der Decision Requester steuert die Entscheidungsfrequenz: Eine Entscheidung wird alle fünf Simulationsschritte angefordert, zwischen zwei Entscheidungen wird die zuletzt gewählte Aktion wiederholt. Diese Entscheidungsfrequenz reduziert den Trainingsaufwand, ohne die Steuerbarkeit in der grid-basierten Umgebung merklich einzuschränken, da sich der Agent zwischen zwei Entscheidungen nur einen Bruchteil einer Zelle weit bewegt.

Ergänzend wurde ein Heuristik-Modus implementiert, in dem der Agent manuell über die Tastatur gesteuert werden kann. Dieser Modus diente der Validierung der gesamten Wirkkette vor dem ersten Training: Bewegung, Sprungmechanik, Sensorwerte, Trigger-Erkennung und Belohnungsvergabe konnten so unabhängig vom Lernverfahren geprüft werden. Zusätzlich wurde eine separate Sensor-Testszene aufgebaut, die alle Hindernistypen enthält und in der die Sensorparameter visuell kalibriert und validiert wurden. Diese Prüfschritte sind methodisch relevant: Fehler in Sensorik oder Belohnungslogik würden sich andernfalls erst indirekt über ausbleibenden Lernfortschritt zeigen und wären dann nur schwer von Konfigurationsproblemen des Lernverfahrens zu unterscheiden.

=== Trainingsszene und Parallelisierung

Das Training erfolgt in einer dedizierten Trainingsszene mit mehreren parallelen Trainingsbereichen (Multi-Area-Setup). Jeder Bereich enthält eine eigene Instanz der Labyrinthumgebung mit eigenem Map-Controller und eigenem Agenten; alle Agenten tragen denselben Verhaltensnamen und werden daher vom Trainer als Instanzen derselben Policy behandelt. Die gesammelten Erfahrungen aller Bereiche fließen in einen gemeinsamen Erfahrungspuffer, wodurch sich die Datensammlung gegenüber einem einzelnen Agenten entsprechend vervielfacht, ohne die Lernaufgabe zu verändern. @juliani_unity_2020 Da jeder Bereich seine Umgebung unabhängig lädt, erhöht die Parallelisierung zugleich die Diversität der Erfahrungen innerhalb eines Puffers: Ein Policy-Update basiert stets auf Episoden aus mehreren, unterschiedlich konfigurierten Labyrinthen.

=== Trainingskonfiguration, Trainingsworkflow, Beobachtbarkeit und Inferenz

Die Trainingskonfiguration ist vollständig in einer versionierten YAML-Datei hinterlegt, die dem Trainer beim Start übergeben wird. Ein Trainingslauf wird über den Kommandozeilenaufruf des Trainers gestartet, wobei die Konfigurationsdatei und eine eindeutige Laufkennung (run-id) übergeben werden. Die Laufkennung bestimmt das Ergebnisverzeichnis, in dem sämtliche Artefakte des Laufs abgelegt werden: die verwendete Konfiguration, die TensorBoard-Ereignisprotokolle, die Laufstatistiken sowie die Modell-Checkpoints. Unterbrochene Läufe können über die Laufkennung fortgesetzt werden; ein Neustart unter derselben Kennung erfordert eine explizite Bestätigung, wodurch ein versehentliches Überschreiben von Ergebnissen verhindert wird. Diese Systematik stellt sicher, dass jeder Trainingslauf eindeutig identifizierbar und mitsamt seiner Konfiguration archiviert ist --- eine Voraussetzung für die in der Aufgabenstellung geforderte Reproduzierbarkeit.

Während des Trainings wurden alle 10.000 Schritte TensorBoard-Zusammenfassungen der protokollierten Metriken geschrieben, was bei vollem Budget eine Lernkurve mit 200 Datenpunkten ergibt. Alle 200.000 Schritte wurde ein Modell-Checkpoint gespeichert, wobei die jeweils letzten fünf Checkpoints vorgehalten wurden; bei instabilem Trainingsverlauf ist damit ein Rückgriff auf frühere Modellstände möglich.

Nach Abschluss des Trainings exportiert der Trainer das finale Modell im ONNX-Format. Für die Inferenz wird das exportierte Modell im Unity-Inspector den Behavior Parameters des Agenten zugewiesen und der Verhaltensmodus auf Inferenz gestellt; der Agent handelt dann ohne laufenden Python-Prozess allein auf Basis der trainierten Policy, ausgeführt über die in Unity integrierte Inferenz-Laufzeitumgebung. Dieser Mechanismus wird sowohl für die Videodemonstrationen der finalen Läufe als auch für die Evaluation der Modellvarianten genutzt.

// ============================================================================
// 8. EVALUATION UND ERGEBNISSE  — nur FINALE Vergleiche (keine Doppelung mit 7.6)
//DAVID ============================================================================
= Evaluation

// HINWEIS: finale vollständige Läufe 
// ggf. noch nicht abgeschlossen -> Zwischenergebnisse kennzeichnen.

== MLP-Baseline

//   — aus §6.1 hierher verschoben; gegen TensorBoard belegen (aus dem Code allein
//   nicht verifizierbar, nur der results-Ordner existiert)

== Architektur-Vergleiche <sec:architekturvergleiche>

// nach metriken vergleichen (keine ahnung trainingsgeschwindigkeit erfolgsrate und so kp)

== Generalisierung auf held-out Maps <sec:generalisierung>

// - 3 unabhängige Eval-Maps; Erfolgs-/Kollisionsrate, Overfitting-Index

== Statistische Auswertung

// - Mann-Whitney U + Bonferroni, Cliff's Delta, Bootstrap-CI, Lernkurven mit CI-Band

== Diskussion

// - Bewertung H1-H3; welche Architektur lernt schneller / generalisiert besser
// - Beobachtetes Verhalten (Wall-Hugging, Lava-Avoidance, PBRS-Artefakte)


// ============================================================================
// 9. ÜBERTRAGBARKEIT UND PRAKTISCHE ANWENDBARKEIT  (verweist zurück auf 1.1/1.2)
//FINN ============================================================================
= Übertragbarkeit und praktische Anwendbarkeit

== Analogie Labyrinth <-> reale Navigationsszenarien

// - Rückgriff auf die Rahmung aus 1.1/1.2 (nicht neu einführen, auswerten)
// - Serviceroboter, Lager-/Indoor-Logistik, Spiele-NPCs

== Hardware- und Software-Anforderungen

// - Ray-only (CPU, niedrige Kosten) / Kamera (GPU) / Multi-Sensor (robust, teuer)
//   ACHTUNG: qualitative Kosten-/Nutzen-Einordnung, KEIN Messergebnis dieser Arbeit —
//   empirisch untersucht wurde nur Ray-only; Kamera/Multi-Sensor klar als
//   Einordnung markieren
//das schreibt uns claude dann
== Bewertungsmatrix

// - Kriterien x Gewichte x Agenten; Empfehlung je Einsatzszenario
// -  Gewichte müssen begründet werden 

== Limitationen der Übertragbarkeit

// - 2D-Abstraktion, statische Hindernisse, Sim-to-Real-Gap, idealisierte Sensorik


// ============================================================================
// 10. FAZIT UND AUSBLICK
//KATYA ============================================================================
= Fazit und Ausblick <sec:fazit>

== Zusammenfassung

// - Gebaut: 3D-Labyrinth, prozedurale Generierung, Curriculum, Custom-LSTM,
//   Custom-Transformer, Multi-Area, vollständige Evaluations-Pipeline

== Beantwortung der Forschungsfragen

// - F1 Mehrwert temporalen Gedächtnisses (LSTM/Transformer vs. MLP, Erfolgsrate)
// - F2 Vergleich LSTM vs. Transformer (Konvergenzgeschwindigkeit, finaler Score)
// - F3 Generalisierung auf ungesehene prozedurale Maps (Overfitting-Index)
// - Zusätzlich, OHNE RQ-Label und OHNE Metrik: praktische Übertragbarkeit als
//   qualitative Diskussion (Rückgriff auf Kap. 9)

== Limitationen und Lessons Learned <sec:limitationen>
// Verweis auf 9.4 (limitation übertragbarkeit) sonst übertragbarkeit nur kurz erwähnen dann verweis.
// - Config-Abweichungen zwischen den Architekturen: NUR VERWEIS auf
//   @sec:yaml-abweichungen (Liste lebt dort, hier nicht wiederholen) + die
//   KONSEQUENZ: Vergleich ohne strengen Kausalanspruch — Unterschiede nicht
//   allein der temporalen Architektur zuschreibbar
// - PPO + Transformer: Inference/Training-Konsistenz nicht trivial
// - PBRS nuetzlich aber farmbar; Discount-Faktor entscheidend
// - Curriculum: Phasenwechsel als Stress-Test; Reward Engineering sensibel

== Ausblick <sec:ausblick>

// - Vollständige Trainingsmatrix
// - CNN-/Multi-Sensor-Pfad (M8-M10): AUSDRÜCKLICH als zurückgestellte Erweiterung
//   benennen — ursprünglich geplanter Sensormodalitäts-Vergleich (Kamera,
//   Sensor-Fusion), bewusst verschoben; Rückverweis auf Abgrenzung 1.6
// - Dynamische Hindernisse, Multi-Agent, Sim-to-Real


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


*TOOOOOOODOOOOOOOOOOOOOOO*:
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
  @sec:ausblick, @sec:fazit, @sec:architekturvergleiche, @sec:generalisierung);
  §-Verweise in Gliederungs-KOMMENTAREN beim Ausformulieren ebenfalls auf
  Labels umstellen.
- "Aufbau der Arbeit" ist nicht optional.

- Belege nachziehen: Dijkstra (nackte URL im Text), Kaelbling 1998 (kein Bib-Key).
- Titelei: Titel-Platzhalter, supervisor leer, eine Matrikelnu

  */

= Sec mlp baseline <sec:mlp-baseline>

