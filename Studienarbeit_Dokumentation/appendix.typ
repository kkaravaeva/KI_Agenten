#import "dhbw.typ": dhbwCite
#let appendix = [
  
#show figure.where(kind: table): set block(breakable: true)
  // ---- Verdichtete Iterationstabelle -------------------------------------
#figure(
  table(
    columns: (auto, 1fr, 1.2fr, 1fr),
    align: left,
    table.header(
      [*Version*], [*Hypothese/Änderung*], [*Kennzahl-Wirkung*], [*Erkenntnis*],
    ),
    [V1], [Proof of Concept des Transformer-Stacks], [50 917 Steps ohne Absturz, Reward von -2,6 auf -1,5 (Run transformer_test_v1)], [Pipeline technisch lauffähig],
    [V2], [Langzeitlauf ohne weitere Änderung], [1,69 Mio. Steps ohne Lernfortschritt, Endstand 1,79 Mio.], [Doppeldiagnose PPO-Ratio-Bug und Sparse Reward (Problemklassen B und C)],
    [V3/V4], [Rolling-Buffer-Fix und triviale Korrekturen], [Verifikationsläufe mit 304 000 bzw. 379 000 Steps], [Korrekturen bestätigt, keine eigene Analyse erforderlich],
    [V5], [Lauf ohne Causal Mask], [Entropie 2,27 bzw. 2,30 nach 680 000 Steps, Policy Loss steigt statt zu fallen], [ohne Causal Mask kein Lernen],
    [V6], [Causal Mask, Dropout von 0,1 auf 0,0, Lernrate 1e-4], [Entropie-Minimum 1,94 mit sofortigem Rebound], [Beta 5e-3 zu hoch],
    [V7], [Beta 1e-3], [Entropie-Minimum 1,60, Reward-Maximum +1,14, Value Loss kollabiert auf ca. 0,001], [Buffer 10 240 zu klein für stabile Advantage-Schätzung],
    [V8], [Buffer 40 960, Time Horizon von 64 auf 256], [kein Value-Kollaps mehr, Entropie pro Step langsamer, pro Update stabiler], [Buffer-Dimensionierung stabilisiert das Value-Training],
    [V9], [Langzeitlauf auf dem V8-Stand], [Plateau bei Ø-Reward 8,9 und Episodenlänge 1199 nach 8,77 Mio. Steps], [hoher Reward als Shaping-Artefakt entlarvt (Timeout-Stagnation)],
    [V10], [goalReward 10, stepPenalty -0,005, pbrsGamma 1,0], [SuccessRate-Logging etabliert], [Erfolgsquote löst Reward als Leitmetrik ab],
    [V11], [agent-relative Bewegung, Dreh-Action (Action-Space 3,3,2), Sequenzlänge von 8 auf 16], [Easy-Phasen 72 bis 82 %, Lava-Übergang Erfolgsquote 0,000], [Totalkollaps am Lava-Übergang],
    [V12], [timeoutPenalty -2, degressiver Lava-Adrenalin-Reward, wallClimbMaxY von 3 auf 5], [Overnight-Run mit 96 parallelen Agents über 29,5 Mio. Steps], [TrivialHazard-Wand sichtbar],
    [V13], [Gamma 0,997, goalReward 30, Curiosity-Modul, curriculum-abhängiges MaxStep], [17,5 Mio. Steps verworfen, Lauf real ein Mock-v13], [Prefab-Drift (Problemklasse D), Verifikation vor Laufstart verpflichtend],
    [V14], [sauberer v13-Stack], [31 Mio. Steps, Phasen 0 bis 3 bei 62 bis 79 % (Phase 0 zuletzt 100 %), Phase 4 bei 0,2 % nach 30 000 Episoden, Lava-Sprung-Todesrate 99 %, Hard 21 % durch Umgehung], [Curriculum-Cliff, drei Crash-Recovery-Zyklen mit Forgetting-Verdacht],
    [V15], [Sub-Phasen (JumpWarmup, LavaSurround, LavaCrossable) mit SuccessRate-Gate], [0 Sprungversuche in 8,5 Mio. Steps, BFS liefert -1, normalisiert 1,0], [Pfad-PBRS ohne Gradient, Step-Penalty dominiert bei MaxStep 15 000],
    [V16], [Jump-aware-BFS, JumpWarmup-Phase, MaxStep 1500, Timeout-Strafe -10], [Policy bei 82 % Zufallsverhalten, Phase 1 bei Erfolgsquote ca. 0,50], [Beta 5e-3 verhindert Konvergenz],
    [V17], [Beta 1e-3, max_steps 10 Mio., SR-Threshold 0,55], [P0/P1 gelöst, Plateau in P2 bei ca. 0,48, EMA P0/P1 über 4 Mio. Steps oberhalb 0,70], [Beta-Decay kollabiert die Exploration, kein Forgetting],
    [V18], [Beta 5e-4 konstant, max_steps 20 Mio., Threshold 0,5, Pfad- und Branch-Diagnosemetriken], [alle Phasen durchlaufen, Advances bei EMA ca. 0,5], [durchgereicht statt gemeistert, Umgehen-Können ist nicht Springen-Können (Bruch Phase 5 zu 6)],
    [V19], [Macro-Jump (dreiwertiger Sprung-Branch), maxUpwardVelocity 4,5], [Lava-Sprung scheitert weiterhin], [Sprungproblem besteht trotz erweitertem Action-Space fort],
    [V20], [Korrektur des Prefab-Overrides der Sprungwerte], [Sprung funktioniert], [erneut Problemklasse D, Wegfindung bleibt schwach],
    [V21], [Wegfindungs-Belohnung erhöht], [Fortschritt bis Hard, Agent überspringt 2×2-Lücken und sucht Sprünge aktiv], [Über-Anreiz des Springens erkannt],
    [V22], [ObservationSize von 14 auf 21, airControl von 1 auf 0,5], [sieben zuvor stillschweigend abgeschnittene Beobachtungswerte wiederhergestellt, Sprungweite auf Ein-Feld-Lücken begrenzt], [Neutraining erforderlich, Endpunkt der dokumentierten Iterationskette],
  ),
  caption: [Verdichtete Übersicht der Iterationen V1 bis V22],
) <tab:iterationen>
// ---- Ende Tabelle -------------------------------------------------------

]
