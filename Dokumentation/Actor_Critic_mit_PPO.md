# Actor - Critc mit PPO
## Actor - Critic
Aufteilung von Neuronales Netzt in zwei Rollen

1. Actor -> Entscheidet was getan wird (Policy, Handlungswahrscheinlichkeiten)
2. Critic -> bewertet wie gut das war (Value Funtkion, erwarteter zukünftiger Reward)

### Actor - DeepDive

**Ziel**: Aktionen wählen, die langfrisitig viel Reward bringen
**Verfahren**: 
-> Policy Gradient
Vereinfacht:
- gute Aktion -> Wahrscheinlichkeit erhöhen
- schlechte Aktion -> Wahrscheinlichkeit senken

= Pardon zum Mathematischen Gradienten

### Critic - Deepdive
Ziel: Schätzt wie gut ist dieser Zustand

Verfahren:
- liefert Baseline-Signal (verhindert extremes Rauschen) damit Actor stabiler lernt
Advantage = tatsächlicher Reward - erwarteter Reward

### Vorteile von Trennung mit PPO
- schneller
- stabiler
- weniger Varianz

## PPO
### Probleme ohne PPO
- Policy-Updates können zu groß sein
- Agent "vergisst", was vorher funktioniert hat
- Training explodiert
-> PPO löst

### Idee:
Policy darf sich nur wenig ändern 
- Vergleich alte Policy vs. neue Policy
- Änderung wird geclipped wenn sie zu stark ist

-> Verhindert zu große Änderungen

### Ablauf
1. Agent spielt Episoden in der Umgebung
2. Sammelt
- States
- Actions
- Rewards
3. Critc berechnet Advantage
4. Actor wird geupdatet
- nur solange Änderungen innerhalb eines sicheren Bereichs liegen 
5. mehre kleine Updates statt großes