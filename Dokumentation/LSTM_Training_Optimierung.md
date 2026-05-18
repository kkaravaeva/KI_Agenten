# LSTM-Training: Optimierungsdokumentation

> Studienarbeit — Optimierung eines LSTM-basierten Reinforcement-Learning-Agenten zur Navigation in prozedural generierten Labyrinthen.  
> Autor: AlexB2812 | Datum: 2026-05-18

---

## 1. Systemübersicht

### 1.1 Aufgabenstellung

Ein Agent navigiert in einem prozedural generierten Labyrinth mit Lava-Fallen und Löchern und soll das Ziel (Goal) möglichst effizient finden. Die Umgebung wird bei jeder Episode neu generiert — der Agent kann sich kein statisches Layout merken, sondern muss generalisierende Navigationskompetenz erlernen.

### 1.2 Algorithmus

**PPO (Proximal Policy Optimization)** mit **LSTM-Speicher** (memory_type: lstm).

Das LSTM ermöglicht dem Agenten, sich über mehrere Zeitschritte an vergangene Beobachtungen zu erinnern — essenziell für Navigation ohne globale Karte.

### 1.3 Netzwerkarchitektur

| Parameter | Wert |
|---|---|
| Trainer | PPO |
| Speicher | LSTM |
| `memory_size` | 256 (hidden_size = 128) |
| `sequence_length` | 64 Schritte (~6 Sekunden Kontext) |
| `hidden_units` | 256 |
| `num_layers` | 2 |
| `batch_size` | 512 (= 8 × sequence_length) |
| `buffer_size` | 40.960 |
| `learning_rate` | 3·10⁻⁴ (linear abnehmend) |
| `beta` (Entropy) | 0.01 (linear → 0) |
| `gamma` (Discount) | 0.99 |
| `max_steps` | 10.000.000 |

### 1.4 Aktionsraum

Diskret — zwei unabhängige Aktionen:
- **Bewegung:** 0=still, 1=vorwärts, 2=zurück, 3=links, 4=rechts
- **Sprung:** 0=nein, 1=ja (nur wenn am Boden)

### 1.5 Observations (Entwicklung über Runs)

| Version | Anzahl | Inhalt |
|---|---|---|
| v1–v3 | **15** | Boden-Sensor (5×2), Geschwindigkeit (3), isGrounded (1), Zieldistanz (1) |
| v4–v5 | **17** | + Zielrichtung als normalisierter 2D-Vektor (dx, dz) |

**Boden-Sensor-Detail:** 5 Raycasts nach unten (Zentrum + N/S/E/W, je 1 Einheit versetzt). Jeder Raycast liefert 2 Werte: Bodentyp (Floor=1.0, Bridge=0.5, Hole=−0.5, Lava=−1.0, kein Boden=−1.5) und normalisierte Distanz.

---

## 2. TensorBoard-Metriken

Alle Runs wurden mit TensorBoard aufgezeichnet (`results/` Verzeichnis).

```
tensorboard --logdir=results --port=6008
```

| Metrik | TensorBoard-Pfad | Bedeutung |
|---|---|---|
| Kumulativer Reward | `Environment/Cumulative Reward` | Durchschnittlicher Episode-Reward — Hauptindikator |
| Episodenlänge | `Environment/Episode Length` | Ø Steps/Episode; sinkt bei besserem Agenten |
| Policy Loss | `Losses/Policy Loss` | Änderungsrate der Policy — sollte sinken |
| Value Loss | `Losses/Value Loss` | Fehler des Wert-Schätzers; hoch bei hoher Reward-Varianz |
| Entropy | `Policy/Entropy` | Explorationsgrad; sinkt durch `beta_schedule: linear` |
| Beta | `Policy/Beta` | Aktueller Entropy-Koeffizient |
| Learning Rate | `Policy/Learning Rate` | Aktuelle Lernrate (linear abnehmend) |

---

## 3. Trainingsläufe

### 3.1 v1 & v2 — Baseline (abgebrochen)

**Konfiguration:** 15 Observations, einfache Rewards (Ziel +5, Tod −1, Step −0.0001)

Beide Runs wurden bei **102.613 Steps** abgebrochen. Der finale Mean Reward betrug **−0.246** — kein erkennbarer Lernfortschritt. Die Runs waren zu kurz für eine auswertbare Lernkurve und werden nicht weiter analysiert.

---

### 3.2 v3_LSTM — Erster vollständiger Run

**Konfiguration:** 15 Observations | Laufzeit: ~30.987 s (~8,6 Stunden) | Abgebrochen bei **4.861.761 Steps**

#### Reward-Verlauf (TensorBoard: `Environment/Cumulative Reward`)

| Steps | Mean Reward | Std of Reward | Interpretation |
|---|---|---|---|
| 10.000 | −0.56 | 0.27 | Exploration, keine Zielerreichung |
| 140.000 | ~−0.5 | ~0.9 | Erste vereinzelte Ziel-Kontakte |
| 500.000 | ~+1.0 | ~2.5 | Agent findet Ziel, aber instabil |
| 800.000 | ~+2.5 | ~4.0 | Klarer Aufwärtstrend |
| 1.310.000 | **+13.25** | 6.19 | Erster stabiler Hochpunkt |
| 1.660.000 | **+17.47** | 0.24 | Nahezu perfekte Episoden |
| 2.560.000 | **+17.87** | 0.37 | Neuer Spitzenwert |
| 4.430.000 | **+18.90** | 0.20 | Eintritt in bimodale Phase |
| **4.460.000** | **+18.93** | **0.12** | **Absoluter Höchstwert** |
| 4.640.000 | +18.91 | 0.09 | Engste Streuung (fast deterministisch) |

#### Phasenanalyse

```
Mean Reward
+19 |                                        ●●● ●●●
+15 |                              ●●●●●●●●●
+10 |                     ●●●●●●●●
 +5 |             ●●●●●●●
  0 |●●●●●●●●●●●
 -1 |
     0    500k   1M    1.5M   2M    2.5M   3M    4M   4.86M  Steps
```

**Phase 1 (0–500k):** Explorations-Phase. Rewards durchgehend negativ, kein stabiler Ziel-Kontakt.  
**Phase 2 (500k–1.5M):** Erster Durchbruch. Agent findet Ziel zunehmend, starker Aufwärtstrend.  
**Phase 3 (1.5M–3.5M):** Plateau mit hoher Varianz. Agent löst einfache Layouts, scheitert an komplexen.  
**Phase 4 (3.5M–4.86M):** Bimodales Verhalten. Wechsel zwischen Reward ~18.9 (std ≈ 0.1) und ~10 (std ≈ 9).

#### Bimodales Problem (TensorBoard-Signatur)

Ab ca. 3.5M Steps zeigt `Environment/Cumulative Reward` ein charakteristisches Zackenmuster: Spitzen bei ~18.9 wechseln mit Einbrüchen auf ~10. Ursache: Das LSTM hat für bestimmte Map-Konfigurationen eine optimale Policy gelernt, scheitert aber bei unbekannten Spawn/Goal-Kombinationen.

TensorBoard-Indikatoren für bimodales Verhalten:
- `Value Loss` bleibt dauerhaft erhöht (Critic sieht abwechselnd Reward 19 und 10)
- `Policy Loss` zeigt Spitzen nach hochvarianten Update-Batches
- `Entropy` sinkt linear — Policy wird deterministisch für die häufigste Konfiguration

**Kernproblem:** Ohne explizite Zielrichtung muss das LSTM die Orientierung aus der Bewegungshistorie rekonstruieren. Das gelingt für bekannte, aber nicht für neue Konfigurationen.

---

### 3.3 v4_LSTM — Zielrichtung als Observation

**Optimierung:** +2 Observations (normalisierter Richtungsvektor dx, dz zum Ziel) → 15 → **17 Observations**  
**Rationale:** Das LSTM gibt explizite Richtungsinformation an den Agenten statt sie aus der Bewegungshistorie ableiten zu müssen, wodurch LSTM-Kapazität für die eigentliche Navigation freigesetzt wird.  
**Abbruch:** Unity-Disconnect bei **1.114.420 Steps**

#### Reward-Verlauf

| Steps | Mean Reward | Std of Reward | Bemerkung |
|---|---|---|---|
| 10.000 | −0.459 | 0.284 | Exploration |
| **50.000** | **−0.004** | **1.663** | **Erster Ziel-Kontakt (v3: erst bei ~140k)** |
| 100.000 | −0.416 | 0.899 | Instabile Durchbrüche |
| 270.000 | **+0.551** | 2.186 | Erster klar positiver Wert |
| 290.000 | +0.427 | 1.994 | Trend bestätigt |
| 680.000 | +0.302 | 1.711 | Langsam wachsend |
| 770.000 | +0.667 | 2.174 | Aufwärtstrend |
| 850.000 | +0.866 | 2.362 | Stärkstes Cluster |
| 900.000 | +1.457 | 2.716 | Klarer Durchbruch |
| 950.000 | +1.737 | 2.734 | Annäherung an 1M-Wert |
| **1.000.000** | **+1.748** | **2.734** | 1M-Meilenstein |
| 1.050.000 | +2.582 | 2.828 | Stärkster Wert im Log |
| **1.114.420** | — | — | **Abbruch (Unity-Disconnect)** |

#### Vergleich v3 vs. v4 bei 1M Steps

| Metrik | v3_LSTM (15 Obs) | v4_LSTM (17 Obs) | Bewertung |
|---|---|---|---|
| Mean Reward bei 1M | +2.671 | +1.748 | v3 absolut höher |
| **Std of Reward bei 1M** | **4.942** | **2.734** | **v4 deutlich stabiler (−45%)** |
| Erster positiver Reward | Step ~140k | **Step ~50k** | v4 deutlich früher |
| Laufzeit bis 1M | ~6.492 s | ~8.161 s | v3 etwas schneller |

**Interpretation:** v4 zeigt bei 1M Steps einen niedrigeren absoluten Reward als v3, jedoch mit signifikant geringerer Varianz. Die Zielrichtungs-Observation macht die Policy konsistenter: Ohne Richtungsinformation hat das LSTM in v3 die Orientierung zufällig aus der Bewegungshistorie abgeleitet — was bei günstigen Konfigurationen gut, bei ungünstigen schlecht funktioniert (hohe Varianz). v4 profitiert von der expliziten Richtungsinformation, braucht aber mehr Steps zur Konvergenz, weil das größere Observation-Space das Netz initial mehr Eingaben verarbeiten muss.

Der steigende Trend bei Abbruch (1.748 → 2.582 in den letzten 100k Steps) deutet darauf hin, dass v4 mit mehr Training v3 übertroffen hätte.

---

### 3.4 v5_LSTM — Reward-Overhaul

**Optimierung:** Vollständige Neugestaltung der Reward-Struktur (Observations unverändert: 17)  
**Abbruch:** Manuell bei **870.000 Steps** (Plateau erkannt)

**Wichtiger Hinweis zur Vergleichbarkeit:** Die Reward-Werte in v5 sind nicht direkt mit v3/v4 vergleichbar. Durch die neuen akkumulierenden Penalty-Terme (Revisit, Distanz-Entfernung, Timeout) liegen typische Episode-Rewards im Bereich −20 bis −200 statt 0 bis +19. Der Fortschritt muss relativ innerhalb des Runs bewertet werden.

#### Reward-Änderungen gegenüber v4

| Parameter | v4 | v5 | Begründung |
|---|---|---|---|
| `stepPenalty` | −0.0001 | **−0.0005** | Effizienz erzwingen |
| `jumpPenalty` | 0.0 | **−0.02** | Pathologisches Sprungverhalten korrigieren (v4: Ø 44.6 Sprünge/Episode) |
| `revisitPenalty` | — | **−0.02 × (n−1), max −0.05** | Kreisen bestrafen |
| `distanceRewardScale` | — | **+0.1 × delta** | Annäherung belohnen |
| `timeoutPenalty` | — | **−2.0** | Timeout ohne Konsequenz vermeiden |

**Bug (früh behoben):** `Mathf.Min(penalty × n, -0.05f)` war invertiert — Mathf.Min liefert das Minimum, nicht das Maximum. Bei 1000 Besuchen einer Zelle ergab sich dadurch penalty = −20 statt −0.05. Fix: `Mathf.Min` → `Mathf.Max`. Der betroffene Trainingsabschnitt (0–60k Steps) wurde verworfen, v5 mit `--force` neugestartet.

#### Reward-Verlauf

| Steps | Mean Reward | Std of Reward | Interpretation |
|---|---|---|---|
| 10.000 | −136.7 | 67.7 | Hohe initiale Strafen |
| 30.000 | **−203.2** | 110.1 | **Tiefpunkt** |
| 50.000 | −88.6 | 90.7 | Erste Adaptation |
| 100.000 | −79.0 | 52.2 | Verbesserung |
| 200.000 | −25.7 | 9.1 | Starker Fortschritt |
| 300.000 | −25.6 | 45.3 | Plateau beginnt |
| 460.000 | −17.0 | 8.0 | Bestwert-Cluster |
| 520.000 | −14.6 | 6.8 | Lokaler Bestwert |
| 710.000 | **−13.6** | **6.4** | **Absoluter Bestwert** |
| 870.000 | −20.4 | 58.0 | Stagnation / Abbruch |

#### Phasenanalyse

```
Mean Reward
   0 |
 -25 |          ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
 -50 |    ●●
 -100|  ●
 -150|●
 -200|  ●(Tiefpunkt 30k)
      0   100k  200k  300k  400k  500k  600k  700k  800k  870k
```

**Phase 1 (0–30k):** Tiefstes Niveau — Agent zahlt viele akkumulierende Strafen.  
**Phase 2 (30k–300k):** Steiler Fortschritt. Reward verbessert sich von −203 auf −25 (+86%).  
**Phase 3 (300k–870k):** Plateau. Reward schwankt zwischen −13 und −27, kein klarer Trend.

#### Episoden-Statistik (4.738 Episoden bei Abbruch)

| Ergebnis | Anzahl | Anteil |
|---|---|---|
| TOD (Lava/Loch) | 4.641 | **97,9%** |
| ZIEL erreicht | 61 | **1,3%** |
| TIMEOUT | 36 | 0,8% |

**Diagnose:** Die 97,9% Todesrate zeigt das Kernproblem: Der Boden-Sensor hat nur 1 Einheit Sichtweite — der Agent sieht Lava erst wenn er direkt darüber steht. Die Todesstrafe (−1.0) war im Verhältnis zu den akkumulierenden Exploration-Rewards zu gering. Das Reward-Overhaul hat die Exploration verbessert (weniger Kreisen), aber die Gefahrenvermeidung nicht gelöst.

---

## 4. Vergleichsanalyse aller Runs

### 4.1 Übersichtstabelle

| Run | Obs | Reward-Design | Steps (Ende) | Bester Reward | Zielrate | Status |
|---|---|---|---|---|---|---|
| v1/v2 | 15 | Basis | 102k | −0.25 | unbekannt | Abgebrochen |
| v3_LSTM | 15 | Basis | 4.862k | **+18.93** | hoch | Abgebrochen (manuell) |
| v4_LSTM | 17 | Basis + Richtung | 1.114k | +2.58 (steigend) | ~14% | Abgebrochen (Disconnect) |
| v5_LSTM | 17 | Reward-Overhaul | 870k | −13.6 | **1,3%** | Abgebrochen (Plateau) |

### 4.2 Zentrale Erkenntnis: Reward-Skala

v3/v4 und v5 arbeiten mit grundlegend verschiedenen Reward-Skalen:
- **v3/v4:** Reward-Bereich ca. −1 bis +19. Positiver Reward möglich, sobald das Ziel gefunden wird.
- **v5:** Reward-Bereich ca. −200 bis −13. Permanente Akkumulation von Strafen dominiert — selbst bei Zielerreichung bleibt der Episode-Reward negativ.

Diese Inkompatibilität erschwert den direkten Vergleich und hat die Trainingseffizienz in v5 gesenkt: Ein Agent, der das Ziel findet, wird nicht mehr klar mit positivem Reward belohnt.

### 4.3 Lerngeschwindigkeit im Vergleich

| Run | Erster positiver Reward | Interpretation |
|---|---|---|
| v3_LSTM | ~Step 140k | Ohne Richtungsinfo dauert es lang bis zur ersten Zielerreichung |
| v4_LSTM | **~Step 50k** | Explizite Zielrichtung beschleunigt ersten Durchbruch um Faktor ~3 |
| v5_LSTM | nie positiv | Akkumulierende Strafen überwiegen den Ziel-Reward (+5) |

### 4.4 Wirkung der einzelnen Optimierungen

| Optimierung | Run | Messbarer Effekt |
|---|---|---|
| LSTM statt MLP | v1→v3 | Stabile Navigation möglich (v3 erreicht +18.93) |
| +Zielrichtung (dx,dz) | v3→v4 | Erster positiver Reward 3× früher; Std −45% bei 1M Steps |
| Jump-Penalty | v4→v5 | Sprungrate reduziert (v4: Ø 44.6 → v5: deutlich weniger) |
| Revisit-Penalty | v4→v5 | Weniger Kreisen — aber höhere Todesrate, da Agent riskantere Pfade nimmt |
| Distanz-Reward | v4→v5 | Agent nähert sich dem Ziel zielgerichteter |
| Höhere Todesstrafe | v5 | Unzureichend (−1.0 zu gering) |

---

## 5. Schlussfolgerungen und nächste Schritte

### 5.1 Was funktioniert hat

1. **LSTM** ist die richtige Architektur für dieses Problem — v3 zeigt mit +18.93 dass das Labyrinth grundsätzlich lösbar ist.
2. **Explizite Zielrichtung** (v4) beschleunigt das Lernen messbar und reduziert Varianz.
3. **Explorations-Rewards** (Revisit-Penalty, neue Zellen) fördern echtes Erkunden.

### 5.2 Was nicht funktioniert hat

1. **Reward-Overhaul in v5** hat die Reward-Skala in den negativen Bereich verschoben — der Agent kann das Ziel finden, wird aber nicht mehr klar positiv belohnt. Das Signal "Ziel gefunden = gut" geht im Rauschen der akkumulierenden Strafen unter.
2. **Gefahrenerkennung** bleibt das Kernproblem: 97.9% Todesrate zeigt, dass 5 Boden-Sensoren nicht ausreichen um Lava zuverlässig zu vermeiden.

### 5.3 Abschluss der LSTM-Versuche

Alle beschriebenen LSTM-Trainingsläufe (v1–v5) fanden ausschließlich **lokal** statt und wurden nicht in die gemeinsame Versionsverwaltung überführt. Sie dienten der explorativen Untersuchung des Optimierungspotenzials von LSTM-basierten Ansätzen für die Labyrinth-Navigation.

Parallel zu diesen Versuchen hat ein **Teamkollege** einen Optimierungsansatz auf Basis der **Transformer-Architektur** verfolgt. Dieser Ansatz erzielte in vergleichbaren Trainingsläufen deutlich bessere Ergebnisse als die hier dokumentierten LSTM-Versuche — sowohl in Bezug auf die Zielerreichungsrate als auch auf die Stabilität der Policy.

Auf Basis dieser Ergebnisse wurde entschieden, die LSTM-Optimierungsversuche **zu verwerfen** und die weitere Entwicklung des Agenten vom Stand des Teamkollegen aus fortzuführen. Die vorliegende Dokumentation dient damit als Nachweis der durchgeführten LSTM-Experimente und der daraus gewonnenen Erkenntnisse über Reward-Design, Observation-Engineering und die Grenzen des LSTM-Ansatzes in dieser Aufgabenstellung.

---

*Dokumentation: AlexB2812 | 2026-05-18*
