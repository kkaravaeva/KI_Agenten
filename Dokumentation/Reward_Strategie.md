# Reward-Strategie: Formale RL-Spezifikation

## Reward-Funktion

Der kumulative Reward einer Episode ergibt sich aus:

```
R_gesamt = goalReward · 𝟙[Ziel erreicht]
         + lavaDeathPenalty · 𝟙[Lava-Tod]
         + holeDeathPenalty · 𝟙[Hole-Tod]
         + stepPenalty · T
```

wobei `T` die Anzahl der Steps in der Episode ist (max. `MaxStep = 2500`).

---

## Reward-Tabelle

| Ereignis | Reward-Wert | Inspector-Feld | Vergeben in |
|---|---|---|---|
| Ziel erreicht | `+1.0` | `goalReward` | `LabyrinthAgent.OnTriggerEnter` – Tag `"Goal"` |
| Lava-Tod | `−1.0` | `lavaDeathPenalty` | `LabyrinthAgent.OnTriggerEnter` – Tag `"Lava"` |
| Hole-Tod | `−1.0` | `holeDeathPenalty` | `LabyrinthAgent.OnTriggerEnter` – Tag `"KillZone"` |
| Timeout (MaxStep) | `0` (kein expliziter Reward) | — | ML-Agents beendet Episode automatisch |
| Step-Penalty | `−0.001` pro Step | `stepPenalty` | `LabyrinthAgent.OnActionReceived` |

Alle Werte sind als `[SerializeField]`-Felder am `LabyrinthAgent` konfigurierbar (Inspector, `Assets/Scripts/Agent/LabyrinthAgent.cs`).

### Architekturentscheidung: Zentrale Reward-Vergabe

Alle `AddReward()`- und `EndEpisode()`-Aufrufe liegen ausschließlich in `LabyrinthAgent.cs`. Externe Trigger-Objekte (Lava-Prefab, KillZone-Box) lösen nur `OnTriggerEnter` aus – sie vergeben keine Rewards selbst. Das entspricht dem ML-Agents-Paradigma und hält Konfiguration und Logik am Agent-Objekt zentralisiert.

---

## Timeout-Verhalten

ML-Agents beendet die Episode automatisch, wenn `MaxStep = 2500` erreicht ist. Es wird kein expliziter Timeout-Reward vergeben. Stattdessen übernimmt der `stepPenalty` die Funktion des Zeitdrucks:

```
stepPenalty × MaxStep = −0.001 × 2500 = −2.5
```

Ein Agent, der das Ziel nie erreicht, akkumuliert mindestens `−2.5` Reward pro Timeout-Episode – deutlich schlechter als ein Lava-Tod (`−1.0`) bei frühzeitigem Abbruch. Das verhindert passives Verhalten ohne eigenen Timeout-Term.

---

## Designentscheidung: Kein Reward für Hindernisüberwindung

Lava kann durch einen Sprung überquert werden. Es wird dafür **kein positiver Reward** vergeben.

**Begründung:** Die Projektbeschreibung (v1_Studienarbeit_KI_Agent_Projektbeschreibung.pdf) schreibt vor:
> „Hindernisüberwindung nur neutral oder leicht positiv bewerten"

Ein expliziter Lava-Sprung-Reward würde das Risikoverhalten überinkentivieren: Der Agent könnte lernen, Lava gezielt zu suchen und zu überspringen, statt den direkten Weg zum Ziel zu nehmen. Das Ziel-Reward von `+1.0` motiviert Zielerreichung ausreichend; die Wegführung (inkl. Hindernisüberwindung) ergibt sich als Nebeneffekt der Optimierung.

---

## Reward-Skalierung: Begründung

| Verhältnis | Bedeutung |
|---|---|
| `goalReward (+1.0)` vs. `deathPenalty (−1.0)` | Symmetrie: Tod und Zielerreichung haben gleiche Magnitude. Kein Anreiz, Tode zu "sammeln" um Exploration zu rechtfertigen. |
| `goalReward (+1.0)` vs. `stepPenalty (−0.001)` | Verhältnis 1000:1 – Ziel in unter 1000 Steps → netto-positiver Episode-Reward. Motiviert schnelle Navigation. |
| Kumulativer Step-Penalty bei MaxStep: `−2.5` | Stärker als ein einzelner Tod (`−1.0`). Timeout ist damit die schlechteste Strategie, was passives Verhalten bestraft. |
