# Multilayer Perceptron (MLP),(Neuronales Netz)
-> Feedforward-neuronales Netz
## Aufbau: 
- Input Layer: Nimmt Beobachtung aus Umgebung
- Hidden Layer(s): verarbeiten Infos
- Output Layer: gibt Werte aus

## Lernt was?
-> MLP ist Funktionsapproximator (Funktionsanäherung)
-> Kein Lernverfahren, sonder Modeltyp

Typische Zuordnung:
- Actor-Netz = MLP
    - Input: State
    - Output: Action-Wahrscheinlichkeiten

- Critic-Netz = MLP
    - Input: State
    - Output: Value V(s)