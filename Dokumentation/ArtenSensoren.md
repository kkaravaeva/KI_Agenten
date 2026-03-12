**VectorSensor**
Liefert manuell definierte numerische Zustandswerte des Agents (z. B. Position, Geschwindigkeit, Statusflags).
Use case: klassische RL-Tasks wie **Robotik, Physik-Simulationen oder einfache Game-Agenten**, bei denen der Zustand direkt berechnet werden kann.

**RayPerceptionSensor**
Sendet mehrere Raycasts vom Agent aus und codiert, welches Objekt in welcher Distanz in jeder Richtung getroffen wird.
Use case: **Navigation, Hinderniserkennung oder Gegner-Erkennung** (z. B. Auto fährt Strecke, NPC erkennt Wand oder Ziel).

**CameraSensor**
Liefert ein Kamerabild als Pixel-Tensor, das vom neuronalen Netz wie ein Bild verarbeitet wird.
Use case: **Vision-basierte Aufgaben**, z. B. wenn der Agent aus visuellen Informationen lernen soll (Autonomes Fahren, Spiel-KI mit realistischem Sichtfeld).

**GridSensor**
Unterteilt den Raum um den Agenten in ein diskretes Raster und kodiert, welche Objekttypen sich in jeder Zelle befinden.
Use case: **Strategie- oder Grid-basierte Umgebungen**, z. B. RTS-ähnliche Szenarien oder Spiele mit diskreten Positionsfeldern.

**BufferSensor**
Speichert eine variable Anzahl ähnlicher Objekte als Liste von Feature-Vektoren für das Netzwerk.
Use case: Szenen mit **unbekannter oder wechselnder Anzahl von Entities**, z. B. mehrere Gegner, Items oder Ziele gleichzeitig.
