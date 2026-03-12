**Strukturierungsprinzip für ML-Agents-Projekte**

**1. Logik im Code umsetzen**

Die eigentliche Funktionslogik des Agents wird in Scripts geschrieben. Dazu gehören das Sammeln der Observations, die Verarbeitung der vom Modell ausgegebenen Actions, die Vergabe von Rewards sowie der Ablauf einer Episode (z. B. Reset der Umgebung oder zufällige Startpositionen). Typischerweise passiert das in Methoden wie `CollectObservations()`, `OnActionReceived()` und `OnEpisodeBegin()`. Dadurch bleibt klar nachvollziehbar, wie der Agent funktioniert, und Änderungen lassen sich sauber im Code verwalten.

**2. GUI/Inspector für Konfiguration nutzen**

Der Unity-Inspector wird vor allem verwendet, um Komponenten zu konfigurieren und miteinander zu verbinden. Dazu zählen z. B. `Behavior Parameters`, der `Decision Requester`, verschiedene Sensor-Komponenten oder Referenzen auf Kameras und RenderTextures. Auch Parameter wie Ray-Länge, Layer-Masken oder Observation-Stacks werden hier eingestellt. Der Inspector dient damit hauptsächlich dazu, vorhandene Bausteine zusammenzustellen und Parameter anzupassen, ohne die eigentliche Logik zu verändern.

**3. Klare Aufgabentrennung im Projekt**

Ein übersichtliches Projekt trennt die Verantwortlichkeiten zwischen den verschiedenen Teilen des Systems. Das Agent-Script kümmert sich um Entscheidungen und Observations. Ein Environment- oder World-Script übernimmt Aufgaben wie das Aufbauen und Zurücksetzen der Umgebung. Der Inspector wird genutzt, um Komponenten zu konfigurieren und Parameter zu tunen. Diese Aufteilung sorgt dafür, dass das Projekt übersichtlich bleibt und sowohl Code als auch Einstellungen leichter gewartet und angepasst werden können.


**Platzierung und Einrichtung von Sensoren**

Sensoren werden in ML-Agents in der Regel direkt am Agent oder an einem Child-Objekt des Agents angebracht. Sie gehören damit strukturell zum Agent, weil sie dessen Wahrnehmung der Umgebung bereitstellen. Der Agent sammelt die von den Sensoren erzeugten Observations und nutzt sie als Eingabe für die Entscheidungsfindung.

Für den sauberen Aufbau bedeutet das: Sensoren werden nicht in ein allgemeines World- oder Environment-Script eingebaut, sondern als eigene `SensorComponent` an das Agent-Objekt oder an passend positionierte Unterobjekte gehängt. Dadurch bleibt klar, welche Informationen der Agent wahrnimmt und aus welcher Perspektive diese erfasst werden. Gerade bei Ray- oder Camera-Sensoren ist es sinnvoll, Child-Objekte zu verwenden, damit Position und Ausrichtung des Sensors gezielt eingestellt werden können.

Die korrekte Einrichtung erfolgt also in drei Schritten: Zuerst wird der Sensor als passende Komponente ausgewählt, zum Beispiel als Ray-, Camera- oder anderer Sensor. Danach wird er am Agent oder an einem Child-Objekt platziert. Anschließend werden die relevanten Parameter im Inspector gesetzt, etwa Reichweite, Winkel, erkennbare Tags, Kamera-Referenzen oder Stacking-Einstellungen. Der Sensor ist damit Teil des deklarativen Setups, während die Auswertung der Observations und die Reaktion darauf in der Agent-Logik verbleiben.

Kurz gesagt: **Sensoren gehören an den Agent oder an dessen Child-Objekte, werden über `SensorComponent`s im Inspector konfiguriert und liefern die Wahrnehmung, die der Agent in seinem Code weiterverarbeitet.**
