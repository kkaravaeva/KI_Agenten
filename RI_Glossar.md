# Reinforcement Learning – Glossar & Konzeptübersicht

> Dieses Dokument erklärt alle zentralen Begriffe rund um Reinforcement Learning, neuronale Netze und ML-Experimentdesign – kurz, verständlich und im Zusammenhang.

---

## Inhaltsverzeichnis

1. [RL-Grundlagen](#1-reinforcement-learning-grundlagen)
2. [Neuronale Netzarchitekturen](#2-neuronale-netzarchitekturen)
3. [Partial Observability & Gedächtnis](#3-partial-observability--gedächtnis)
4. [Reward Design](#4-reward-design)
5. [Generalisierung & Evaluation](#5-generalisierung--evaluation)
6. [Training & Curriculum](#6-training--curriculum)
7. [Beobachtungsraum & Zustandsdarstellung](#7-beobachtungsraum--zustandsdarstellung)
8. [Robustheit & Rauschen](#8-robustheit--rauschen)
9. [Explorationsstrategien](#9-explorationsstrategien)
10. [Experimentdesign & Ablation](#10-experimentdesign--ablation)
11. [Konzeptlandkarte](#11-konzeptlandkarte)

---

## 1. Reinforcement Learning Grundlagen

### Markov Decision Process (MDP)

Ein MDP ist das mathematische Grundgerüst für RL. Es besteht aus:

| Bestandteil | Bedeutung |
|---|---|
| **S** (States) | Menge aller möglichen Zustände der Umgebung |
| **A** (Actions) | Menge aller möglichen Aktionen des Agenten |
| **T** (Transition) | Übergangswahrscheinlichkeit: Wie wahrscheinlich folgt Zustand s' auf Zustand s bei Aktion a? |
| **R** (Reward) | Belohnung, die der Agent für einen Übergang erhält |
| **γ** (Gamma) | Diskontierungsfaktor: Wie stark werden zukünftige Belohnungen gewichtet? (0–1) |

**Kernannahme (Markov-Eigenschaft):** Der nächste Zustand hängt nur vom aktuellen Zustand und der Aktion ab – nicht von der gesamten Vergangenheit.

### Policy vs. Value Function

```
             ┌─────────────────────────────────────────┐
             │          Entscheidungsfindung            │
             └──────────┬──────────────┬───────────────┘
                        │              │
                        ▼              ▼
                 ┌──────────┐   ┌──────────────┐
                 │  Policy  │   │ Value Function│
                 │  π(s)    │   │   V(s)/Q(s,a)│
                 └──────────┘   └──────────────┘
                 "Was soll      "Wie gut ist
                  ich tun?"      dieser Zustand?"
```

- **Policy π(s):** Bildet Zustände auf Aktionen ab. Kann deterministisch (eine feste Aktion) oder stochastisch (Wahrscheinlichkeitsverteilung über Aktionen) sein.
- **Value Function V(s):** Schätzt, wie viel Belohnung der Agent ab Zustand s insgesamt noch erwarten kann.
- **Q-Function Q(s, a):** Wie V(s), aber zusätzlich abhängig von der gewählten Aktion a.

### Reward Function

Die Reward Function definiert das Ziel des Agenten. Sie liefert nach jedem Schritt einen numerischen Wert (Belohnung oder Bestrafung), der dem Agenten signalisiert, ob sein Verhalten gut oder schlecht war.

Beispiel: Ein Roboter bekommt +1 für das Erreichen eines Ziels, -0.01 für jeden Zeitschritt (damit er sich beeilt).

### Episode

Eine Episode ist ein vollständiger Durchlauf vom Startzustand bis zum Endzustand. Beispiele: ein komplettes Spiel, ein Navigationsversuch vom Start zum Ziel, ein Versuch eine Aufgabe zu lösen.

### Return

Der Return G ist die **kumulierte (aufsummierte), diskontierte Belohnung** einer Episode:

```
G = r₁ + γ·r₂ + γ²·r₃ + γ³·r₄ + ...
```

γ (Gamma) bestimmt, wie stark der Agent in die Zukunft schaut:
- γ = 0 → Agent ist kurzsichtig (nur die nächste Belohnung zählt)
- γ = 1 → Agent gewichtet alle zukünftigen Belohnungen gleich

### Exploration vs. Exploitation

```
         ┌──────────────────────────────────────┐
         │     Exploration vs. Exploitation      │
         └──────────┬───────────────┬────────────┘
                    │               │
                    ▼               ▼
            ┌──────────────┐ ┌──────────────┐
            │ Exploration  │ │ Exploitation │
            │ "Neues       │ │ "Bekanntes   │
            │  ausprobieren│ │  ausnutzen"  │
            └──────────────┘ └──────────────┘
            Entdecke evtl.   Nutze das bisher
            bessere Wege     beste Verhalten
```

Das zentrale Dilemma im RL: Soll der Agent bekannte gute Aktionen wiederholen (Exploitation) oder neue Aktionen ausprobieren, die vielleicht besser sind (Exploration)?

### Proximal Policy Optimization (PPO)

PPO ist ein moderner Policy-Gradient-Algorithmus. Kernideen:

1. **Policy direkt optimieren:** Der Agent lernt eine parametrisierte Policy (z. B. ein neuronales Netz).
2. **Clipping:** PPO begrenzt die Größe der Policy-Updates, damit das Training stabil bleibt. Zu große Änderungen werden „abgeschnitten" (geclippt).
3. **Entropy Bonus:** PPO kann einen Entropy-Bonus hinzufügen, der die Exploration fördert (→ siehe Abschnitt 9).

```
  Alte Policy ──► Erfahrungen sammeln ──► Neue Policy berechnen
       ▲                                         │
       │            Clipping begrenzt             │
       │            die Änderung                  │
       └──────────────────────────────────────────┘
```

---

## 2. Neuronale Netzarchitekturen

Diese Architekturen werden im RL als Funktionsapproximatoren für Policy und/oder Value Function eingesetzt.

### Multilayer Perceptron (MLP)

Das einfachste tiefe neuronale Netz: mehrere vollständig verbundene Schichten (Fully Connected Layers). Jedes Neuron einer Schicht ist mit jedem Neuron der nächsten Schicht verbunden.

```
  Input      Hidden 1     Hidden 2     Output
  [x₁] ──┐
          ├──► [h₁] ──┐
  [x₂] ──┤            ├──► [h₃] ──┐
          ├──► [h₂] ──┤           ├──► [y]
  [x₃] ──┘            └──► [h₄] ──┘
```

**Einsatz im RL:** Gut geeignet, wenn der Agent den vollständigen Zustand auf einmal sieht (z. B. Gelenkwinkel eines Roboters). Kann keine zeitlichen Abhängigkeiten modellieren.

### Recurrent Neural Network (RNN)

RNNs verarbeiten Sequenzen, indem sie einen **Hidden State** h von Zeitschritt zu Zeitschritt weitergeben. Damit hat das Netz eine Art „Gedächtnis".

```
  Zeitschritt:   t-2        t-1         t
                  │          │          │
                  ▼          ▼          ▼
  Input ───►  [RNN] ──h──► [RNN] ──h──► [RNN] ──► Output
```

**Problem:** Bei langen Sequenzen geht Information verloren oder explodiert (Vanishing/Exploding Gradient Problem).

### Long Short-Term Memory (LSTM)

LSTM ist eine spezielle RNN-Variante, die das Vanishing-Gradient-Problem löst. Sie nutzt **Gates** (Tore), die steuern, welche Informationen behalten, vergessen oder weitergegeben werden:

| Gate | Funktion |
|---|---|
| **Forget Gate** | Entscheidet, was aus dem Langzeitgedächtnis vergessen wird |
| **Input Gate** | Entscheidet, welche neuen Informationen gespeichert werden |
| **Output Gate** | Entscheidet, was als Hidden State weitergegeben wird |

**Einsatz im RL:** Wenn der Agent sich an vergangene Beobachtungen erinnern muss (z. B. bei partieller Beobachtbarkeit).

### Transformer

Eine Architektur, die Sequenzen **parallel** statt sequenziell verarbeitet. Basiert komplett auf dem Attention-Mechanismus (kein rekurrentes Weiterreichen von Hidden States).

Vorteile gegenüber RNN/LSTM: paralleles Training, besserer Umgang mit langen Sequenzen.

### Attention Mechanism

Attention erlaubt dem Netz, sich bei der Verarbeitung auf die **relevantesten Teile** der Eingabe zu konzentrieren, statt alles gleich zu gewichten.

```
  Eingabe: [A, B, C, D, E]
                │
         Welche Teile sind
         für die aktuelle
         Ausgabe wichtig?
                │
                ▼
  Gewichte: [0.1, 0.05, 0.7, 0.1, 0.05]
                       ↑
                  C ist am relevantesten
```

### Self-Attention

Eine spezielle Form von Attention, bei der jedes Element einer Sequenz die Relevanz **aller anderen Elemente derselben Sequenz** für sich berechnet. Kernmechanismus des Transformers.

### Sequence Modeling

Oberbegriff für Aufgaben, bei denen die Eingabe eine **geordnete Folge** von Elementen ist (z. B. Zeitreihen, Textfolgen, Beobachtungsfolgen im RL). RNN, LSTM und Transformer sind alles Sequence-Modeling-Architekturen.

### Temporal Dependencies (Zeitliche Abhängigkeiten)

Wenn ein aktuelles Ergebnis von **früheren Eingaben/Ereignissen** abhängt. Beispiel im RL: Der Agent muss sich erinnern, dass er vor 10 Schritten einen Schlüssel aufgehoben hat, um jetzt eine Tür öffnen zu können.

```
  Zusammenhang der Architekturen:

  Temporal Dependencies (das Problem)
       │
       ▼
  Sequence Modeling (die Aufgabenklasse)
       │
       ├──► RNN (einfachste Lösung, aber Gedächtnisprobleme)
       │      │
       │      └──► LSTM (löst Gedächtnisprobleme von RNN)
       │
       └──► Transformer + Self-Attention (parallele Alternative)

  MLP hat KEIN Gedächtnis → kann Temporal Dependencies nicht verarbeiten
```

---

## 3. Partial Observability & Gedächtnis

### Partial Observability (Partielle Beobachtbarkeit)

Der Agent sieht **nicht den vollständigen Zustand** der Umgebung, sondern nur eine eingeschränkte Beobachtung. Beispiel: Ein Roboter sieht nur was vor ihm liegt, nicht was hinter ihm ist.

### Partially Observable MDP (POMDP)

Erweiterung des MDP für partielle Beobachtbarkeit. Zusätzlich zu S, A, T, R kommt hinzu:

- **O** (Observations): Menge der möglichen Beobachtungen
- **Ω** (Observation Function): Wahrscheinlichkeit, Beobachtung o im Zustand s zu erhalten

```
  MDP:    Agent sieht Zustand direkt    →  s ──► π(s) ──► a
  POMDP:  Agent sieht nur Beobachtung   →  o ──► ??? ──► a
                                              ↑
                                         Zustand s ist
                                         verborgen!
```

### State vs. Observation

| | State (Zustand) | Observation (Beobachtung) |
|---|---|---|
| **Inhalt** | Vollständige Information über die Umgebung | Eingeschränkte/verrauschte Information |
| **Beispiel** | Position aller Objekte im Raum | Nur Kamerabild aus einer Perspektive |
| **MDP-Typ** | MDP (vollständig beobachtbar) | POMDP (partiell beobachtbar) |

### Memory in Reinforcement Learning

Da der Agent bei POMDPs den wahren Zustand nicht kennt, braucht er ein **Gedächtnis**, um aus vergangenen Beobachtungen den Zustand zu rekonstruieren. Technische Umsetzungen: RNN, LSTM, Transformer oder explizite Beobachtungshistorien als Eingabe.

### Temporal Credit Assignment

Das Problem, herauszufinden, **welche vergangene Aktion** für eine aktuelle Belohnung verantwortlich war. Eng verwandt mit dem allgemeinen Credit Assignment Problem (→ Abschnitt 4). Besonders schwierig bei partieller Beobachtbarkeit, da der Agent nicht mal sicher weiß, in welchem Zustand er war.

```
  Zusammenhang:

  Partial Observability (das Problem)
       │
       ├──► POMDP (das formale Modell)
       │
       ├──► State vs. Observation (die Lücke)
       │
       ├──► Memory (die Lösung → LSTM, Transformer)
       │
       └──► Temporal Credit Assignment (erschwert durch Unvollständigkeit)
```

---

## 4. Reward Design

### Reward Shaping

Das gezielte Gestalten der Belohnungsfunktion, um das Lernen zu erleichtern. Man gibt dem Agenten **Zwischenbelohnungen** (z. B. für Annäherung an ein Ziel), damit er schneller lernt.

### Sparse vs. Dense Reward

```
  Dense Reward:    ──●──●──●──●──●──●──●──●──► Ziel (+1)
                   (+0.1 für jeden Schritt näher am Ziel)

  Sparse Reward:   ──○──○──○──○──○──○──○──○──► Ziel (+1)
                   (keine Zwischenbelohnungen)
```

| | Sparse Reward | Dense Reward |
|---|---|---|
| **Signal** | Nur am Ende (z. B. Gewinn/Verlust) | Bei jedem Schritt |
| **Lernen** | Sehr schwierig, langsam | Einfacher, schneller |
| **Risiko** | Agent findet kaum ein Signal | Reward Hacking (siehe unten) |

### Reward Hacking

Der Agent findet **Schlupflöcher** in der Belohnungsfunktion und maximiert die Belohnung auf unbeabsichtigte Weise. Beispiel: Ein Roboter, der für Vorwärtsbewegung belohnt wird, legt sich hin und „rutscht" statt zu laufen, weil das mehr Belohnung gibt.

### Credit Assignment Problem

Die fundamentale Frage: **Welche Aktion war für den erhaltenen Reward verantwortlich?** Wenn der Agent nach 100 Schritten eine Belohnung bekommt, welcher der 100 Schritte war entscheidend? (Temporal Credit Assignment ist die zeitliche Variante dieses Problems.)

```
  Zusammenhang Reward Design:

  Reward Function (Grundlage)
       │
       ├──► Reward Shaping (gezieltes Designen)
       │        │
       │        └──► Dense vs. Sparse (Granularität)
       │
       ├──► Reward Hacking (Risiko bei schlechtem Design)
       │
       └──► Credit Assignment Problem (fundamentale Herausforderung)
```

---

## 5. Generalisierung & Evaluation

### Generalisierung in RL

Die Fähigkeit des Agenten, in **neuen, ungesehenen** Situationen/Umgebungen gute Leistung zu zeigen – nicht nur in der Trainingsumgebung.

### Overfitting in RL

Der Agent lernt die Trainingsumgebung „auswendig" und versagt in neuen Situationen. Beispiel: Der Agent lernt exakt, wo Hindernisse stehen, statt zu lernen, Hindernissen generell auszuweichen.

### Train/Test Split in RL

Analog zu Supervised Learning: Trainings- und Testumgebungen werden getrennt. Der Agent trainiert auf einer Menge von Umgebungen und wird auf einer anderen Menge evaluiert, um Generalisierung zu prüfen.

### Evaluationsmetriken in RL

| Metrik | Was sie misst |
|---|---|
| **Success Rate** | Anteil der Episoden, in denen das Ziel erreicht wird (z. B. 85 von 100) |
| **Episode Length** | Wie viele Schritte der Agent pro Episode braucht (kürzer = effizienter) |
| **Cumulative Reward** | Gesamtbelohnung pro Episode (der Return) |

### Domain Randomization

Trainingstechnik: Die Umgebungsparameter (Farben, Größen, Physik, Positionen) werden bei jedem Trainingsdurchlauf **zufällig variiert**. Dadurch lernt der Agent, mit Variation umzugehen, und generalisiert besser – besonders nützlich für den Transfer von Simulation zur realen Welt (Sim-to-Real).

```
  Zusammenhang Generalisierung:

  Overfitting (das Problem)
       │
       ├──► Train/Test Split (Erkennung)
       │
       ├──► Domain Randomization (Gegenmaßnahme im Training)
       │
       └──► Evaluationsmetriken (Messung der Leistung)
                 │
                 ├──► Success Rate
                 ├──► Episode Length
                 └──► Cumulative Reward
```

---

## 6. Training & Curriculum

### Curriculum Learning

Trainingsstrategie, bei der der Agent mit **einfachen Aufgaben** beginnt und die Schwierigkeit schrittweise gesteigert wird. Analog zum menschlichen Lernen: erst Grundlagen, dann Fortgeschrittenes.

```
  Phase 1           Phase 2           Phase 3
  ┌─────────┐      ┌─────────┐      ┌─────────┐
  │ Einfach  │ ──► │ Mittel   │ ──► │ Schwer   │
  │ z.B. kurze│     │ z.B. mehr│     │ z.B. volle│
  │ Distanz  │     │ Hindern. │     │ Komplexität│
  └─────────┘      └─────────┘      └─────────┘
```

### Sample Efficiency

Wie viele **Erfahrungen** (Umgebungsinteraktionen) der Agent braucht, um gute Leistung zu erzielen. Ein sample-effizienter Algorithmus lernt mit weniger Daten. Besonders wichtig, wenn Umgebungsinteraktionen teuer sind (z. B. echte Roboter).

### Training Stability (Trainingsstabilität)

Wie gleichmäßig und vorhersagbar der Lernfortschritt verläuft. Instabiles Training zeigt sich durch starke Schwankungen der Leistung oder plötzliche Einbrüche. PPO wurde speziell für hohe Trainingsstabilität entwickelt (durch Clipping).

```
  Stabil:     ──────/────/──────/──────── (gleichmäßiger Anstieg)
  Instabil:   ──/\──\/──/\──\──/\/\──── (starke Schwankungen)
```

---

## 7. Beobachtungsraum & Zustandsdarstellung

### Observation Space

Die formale Definition, **welche Daten** der Agent als Eingabe erhält. Beschreibt Dimensionalität, Datentypen und Wertebereiche der Beobachtungen (z. B. ein Vektor mit 12 Fließkommazahlen oder ein 84×84-Pixel-Bild).

### State Representation

Wie der Zustand der Umgebung **für den Agenten codiert** wird. Gute Repräsentationen enthalten alle relevanten Informationen in kompakter Form. Schlechte Repräsentationen erschweren das Lernen.

### Feature Engineering

Der manuelle Prozess, aus Rohdaten **informative Merkmale** (Features) zu berechnen, die dem Agenten das Lernen erleichtern. Beispiel: Statt Rohpixel den Abstand zum nächsten Hindernis als Feature verwenden.

### Unity ML-Agents

Ein Framework von Unity, das es ermöglicht, RL-Agenten in Unity-Spielumgebungen zu trainieren. Bietet vorgefertigte Sensoren, Trainingsalgorithmen (u. a. PPO) und eine Python-Schnittstelle.

### Ray Perception Sensor

Ein spezieller Sensor in Unity ML-Agents. Er sendet **Strahlen** (Rays) von einem Objekt aus und misst, was diese treffen (z. B. Wand, Ziel, Hindernis) und in welcher Entfernung. Erzeugt einen strukturierten Beobachtungsvektor.

```
  Draufsicht:
                    Ray 2
                   /
           Ray 1 /
                /
  Agent  ●──────────── Ray 0 (gerade aus)
                \
           Ray 4 \
                   \
                    Ray 3

  Jeder Ray liefert: [Hat getroffen? | Was? | Distanz]
```

```
  Zusammenhang:

  Observation Space (was der Agent sieht)
       │
       ├──► State Representation (wie es codiert ist)
       │        │
       │        └──► Feature Engineering (manuelles Optimieren)
       │
       └──► Ray Perception Sensor (konkreter Sensor in Unity ML-Agents)
```

---

## 8. Robustheit & Rauschen

### Noise Injection (Rauschinjizierung)

Absichtliches Hinzufügen von **zufälligen Störungen** zu Beobachtungen, Aktionen oder Umgebungsparametern während des Trainings. Ziel: Der Agent lernt, mit Ungenauigkeiten umzugehen.

### Robustheit in RL

Die Fähigkeit des Agenten, auch unter **veränderten Bedingungen** (Rauschen, neue Umgebungen, unerwartete Situationen) gut zu funktionieren. Eng verknüpft mit Generalisierung, aber mit Fokus auf Störungsresistenz.

```
  Maßnahmen für Robustheit:

  ├──► Noise Injection (Störungen im Training)
  ├──► Domain Randomization (Varianz in der Umgebung)
  └──► Diverse Trainingsszenarien
```

---

## 9. Explorationsstrategien

### Epsilon-Greedy

Einfachste Explorationsstrategie:
- Mit Wahrscheinlichkeit **1-ε**: Wähle die beste bekannte Aktion (Exploitation)
- Mit Wahrscheinlichkeit **ε**: Wähle eine zufällige Aktion (Exploration)

ε wird typischerweise über das Training hinweg reduziert (anfangs viel erkunden, später ausnutzen).

### Entropy Bonus (in PPO)

PPO kann der Belohnung einen **Entropy-Bonus** hinzufügen. Entropie misst, wie „gleichverteilt" die Aktionswahrscheinlichkeiten sind. Hoher Bonus → Agent probiert vielfältigere Aktionen aus (mehr Exploration). Wird über den Koeffizienten gesteuert.

### Lokale Optima in RL

Ein lokales Optimum ist eine Lösung, die **lokal besser** ist als alle Nachbarlösungen, aber nicht die beste insgesamt (globales Optimum). Ohne ausreichende Exploration bleibt der Agent in einem lokalen Optimum hängen.

```
  Belohnung
  ▲
  │    ╱╲          ╱╲
  │   ╱  ╲        ╱  ╲
  │  ╱    ╲  ╱╲  ╱    ╲
  │ ╱      ╲╱  ╲╱      ╲
  └────────────────────────►  Policy-Raum
       ↑              ↑
    Lokales         Globales
    Optimum         Optimum
```

```
  Zusammenhang Exploration:

  Exploration vs. Exploitation (das Dilemma)
       │
       ├──► Epsilon-Greedy (einfache Strategie)
       │
       ├──► Entropy Bonus in PPO (softer Ansatz)
       │
       └──► Lokale Optima (Risiko bei zu wenig Exploration)
```

---

## 10. Experimentdesign & Ablation

### Ablation Study

Man entfernt oder deaktiviert systematisch **einzelne Komponenten** eines Systems, um deren Beitrag zur Gesamtleistung zu messen. Beispiel: Modell mit LSTM vs. ohne LSTM trainieren → Effekt von LSTM messen.

### Controlled Experiment Design

Grundprinzip: **Nur eine Variable** gleichzeitig verändern, alles andere konstant halten. Damit lässt sich der Effekt genau dieser Variable isolieren und messen.

### Hyperparameter Sensitivity

Analyse, wie stark die Leistung des Modells auf **Änderungen einzelner Hyperparameter** reagiert (z. B. Lernrate, Clipping-Bereich bei PPO, Netzwerkgröße). Hohe Sensitivität = kleine Änderung führt zu großem Leistungsunterschied.

### Baseline Model

Ein **Referenzmodell**, gegen das neue Ansätze verglichen werden. Kann ein einfaches Modell (z. B. Zufalls-Agent) oder ein bekannter Stand der Technik sein. Ohne Baseline lässt sich nicht sagen, ob ein Ergebnis gut ist.

### Statistische Signifikanz

Prüft, ob ein beobachteter Leistungsunterschied **tatsächlich real** ist oder nur durch Zufall entstanden sein könnte. In ML typischerweise über mehrere Trainingsläufe mit verschiedenen Seeds gemessen. Ohne Signifikanzprüfung kann man nicht sicher sein, ob Ergebnis A wirklich besser ist als Ergebnis B.

```
  Zusammenhang Experimentdesign:

  Controlled Experiment Design (Grundprinzip)
       │
       ├──► Ablation Study (Variante: Komponenten entfernen)
       │
       ├──► Hyperparameter Sensitivity (Variante: Werte variieren)
       │
       ├──► Baseline Model (Referenz zum Vergleichen)
       │
       └──► Statistische Signifikanz (Ergebnisse absichern)
```

---

## 11. Konzeptlandkarte

Die folgende Übersicht zeigt, wie alle Konzepte zusammenhängen:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         UMGEBUNG (Environment)                         │
│                                                                        │
│  ┌──────────────────┐        ┌──────────────────────────┐              │
│  │ MDP / POMDP      │        │ Reward Design            │              │
│  │ (Formales Modell) │        │ ├ Reward Function        │              │
│  │ ├ State / Obs.   │        │ ├ Sparse vs. Dense       │              │
│  │ ├ Actions        │        │ ├ Reward Shaping         │              │
│  │ └ Transitions    │        │ ├ Reward Hacking         │              │
│  └──────────────────┘        │ └ Credit Assignment      │              │
│                              └──────────────────────────┘              │
└──────────────────────────────────┬──────────────────────────────────────┘
                                   │
                          Beobachtung / Reward
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           AGENT                                        │
│                                                                        │
│  ┌──────────────────┐   ┌───────────────────────┐                      │
│  │ Wahrnehmung      │   │ Entscheidung          │                      │
│  │ ├ Obs. Space     │   │ ├ Policy (π)          │                      │
│  │ ├ State Repr.    │──►│ ├ Value Function      │                      │
│  │ ├ Feature Eng.   │   │ └ Exploration vs.     │                      │
│  │ └ Ray Percept.   │   │   Exploitation        │                      │
│  └──────────────────┘   │   ├ Epsilon-Greedy    │                      │
│                         │   └ Entropy Bonus     │                      │
│                         └───────────────────────┘                      │
│                                                                        │
│  ┌──────────────────────────────────────────────┐                      │
│  │ Neuronales Netz (Funktionsapproximator)      │                      │
│  │ ├ MLP (kein Gedächtnis)                      │                      │
│  │ ├ RNN → LSTM (sequenzielles Gedächtnis)      │                      │
│  │ └ Transformer + Self-Attention (parallell)   │                      │
│  └──────────────────────────────────────────────┘                      │
│                                                                        │
│  Algorithmus: PPO (Policy + Clipping + Entropy Bonus)                  │
└──────────────────────────────────────┬──────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         TRAINING                                       │
│                                                                        │
│  ├ Episoden durchlaufen → Return berechnen → Policy updaten            │
│  ├ Curriculum Learning (Schwierigkeit steigern)                        │
│  ├ Domain Randomization (Umgebung variieren)                           │
│  ├ Noise Injection (Robustheit erhöhen)                                │
│  ├ Sample Efficiency (möglichst wenig Daten)                           │
│  └ Training Stability (gleichmäßig lernen)                             │
└──────────────────────────────────────┬──────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       EVALUATION & EXPERIMENT                          │
│                                                                        │
│  ├ Train/Test Split (Generalisierung prüfen)                           │
│  ├ Metriken: Success Rate, Episode Length, Cumulative Reward           │
│  ├ Ablation Study (Komponentenbeitrag messen)                          │
│  ├ Baseline Model (Referenzvergleich)                                  │
│  ├ Hyperparameter Sensitivity (Empfindlichkeit testen)                 │
│  └ Statistische Signifikanz (Ergebnisse absichern)                     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

*Erstellt als Lernhilfe – alle Konzepte sind vereinfacht dargestellt.*