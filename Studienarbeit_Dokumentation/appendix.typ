#import "dhbw.typ": dhbwCite
#let appendix = [

  == Big Data Definitionen 
  aus #dhbwCite("gupta_study_2019", page: "325") Tabelle I "Popular big data Definitions."" , Spalte 4 "References" aus #dhbwCite("gupta_study_2019")
  #figure([], caption: [Popular big data Definitions.], kind: table, supplement: [Tabelle]) <tab:gupta-2019-Big-Data-Definitions>
#table(
  columns: (1.2fr, 0.6fr, 3fr, 0.6fr),
  align: (left, center, left, center),
  table.header(
    [*Author*], [*Year*], [*Definition*], [*Reference*],
  ),
  [McKinsey Global Institute], [2011],
  ["Big data refers to a dataset whose size is beyond the ability of typical database software tools to capture, store, manage, and analyze."],
  [\[17\]],

  [Gartner], [2012],
  ["Big Data is high-volume, high-velocity and/or high-variety information assets that demand cost-effective, innovative forms of information processing that enable enhanced insight, decision making, and process automation."],
  [\[18\]],

  [Mayer-Schönberger and Cukier], [2013],
  ["Big data refers to things one can do at a large scale that cannot be done at a smaller one, to extract new insights or create new forms of value, in ways that change markets, organizations, the relationship between citizens and governments, and more."],
  [\[19\]],

  [National Institute of Standards and Technology (NIST)], [2015],
  ["Big data consists of extensive datasets — primarily in the characteristics of volume, variety, velocity, and/or variability — that require a scalable architecture for efficient storage, manipulation, and analysis."],
  [\[15\]],

  [International Data Corporation (IDC)], [2017],
  ["Big data software is described as a new generation of software and architectures designed to economically extract value from very large volumes of a wide variety of data by enabling high-velocity capture, discovery, and/or analysis."],
  [\[20\]],
)

== Evolution Data Products
aus #dhbwCite("hasan_understanding", page:"3") Table I "Definitions of information product(s) and data product(s) in the literature"

#figure([], caption: [Definitions of information product(s) and data product(s) in the literature.], kind: table, supplement: [Tabelle]) <tab:hasanlegner-2023-Evolution-Data-Products>

#table(
  columns: (1.2fr, 3fr, 1.5fr),
  align: (left, left, left),
  table.header(
    [*Source*], [*Definition*], [*Examples*],
  ),

  table.cell(colspan: 3)[*Phase 1: Information products (1990s and 2000s)*],

  [Wang (1998)],
  [Information products are defined as the result of activities that take place within the information supply chain.],
  [Client account data],

  [Shankaranarayanan et al. (2000)],
  [Data items that are required to fulfill consumer needs and can range from raw data and semi-processed information to final information products.],
  [Certificates, bills, transcripts, bank statements],

  [Cai and Ziad (2003)],
  [An information product is a specific deliverable that aligns with end user requirements.],
  [Invoices, business reports, prescriptions],

  [Davidson et al. (2004)],
  [Information products are a collection of data elements aimed at a specific purpose.],
  [Birth certificate],

  [Wang et al. (2005)],
  [An information product is identified in terms of data items that comprise it, and it is the quality of each data item that is of importance to the consumer.],
  [Certificates, mailing labels, sales orders],

  [Nam and Lamb (2006)],
  [An information product is any valuable information for which users are willing to pay.],
  [News products],

  table.cell(colspan: 3)[*Phase 2: Data products (since 2010)*],

  [Loukides (2011)],
  [Data products are not about data, but about enabling users to do what they want to do. Data products should deliver results rather than data, and data is invisible in the product.],
  [Spreadsheets, recommendations, self-driving cars],

  [Bengfort and Kim (2016)],
  [Data products are self-adapting, broadly applicable economic engines that derive their value from data and generate more data by influencing human behavior or by making inferences or predictions upon new data.],
  [Nest thermostat, autonomous vehicles, quantified self],

  [Davenport and Kudyba (2016)],
  [Data products (which can mostly be described as services) are not generally sold separately to customers but are used to attract customers for advertising, draw attention to unknown products in large product pools, and enhance revenue through cross-selling and upselling.],
  [Predictive maintenance, property price predictions, matching algorithms],

  [Meierhofer et al. (2019)],
  [A data product is defined as the application of a unique blend of skills from analytics, engineering and communication aimed at generating value from the data itself to provide benefit to another entity.],
  [Customer analytics insight],

  [Si et al. (2020)],
  [Data products result from data resources after desensitization, encapsulation, and right identification. They have the dual characteristics of data and product.],
  [Monetizable datasets],

  [Fruhwirth et al. (2020)],
  [Data products help their users to make better decisions and formulate customer benefit. The users can be internal or external customers.],
  [Reports, dashboards, APIs],

  [Machado et al. (2021)],
  [Data products can be understood as a set of data that instantiate the domain.],
  [Domain sales data, online profit data],

  [Chen et al. (2022)],
  [Data products may be datasets packaged and designed as products or services by developers for data owners or stakeholders. They have potential applications and values for data buyers or new users to pay.],
  [Personal data, financial data, pharmaceutical data],
)

== Motivation, Definition und Kategorien von Data Products in Unternehmen

aus #dhbwCite("hasan_understanding", page:"11") Table 5 "Motivation, definition, and categories of data products in the companies."

#figure([], caption: [Motivation, definition, and categories of data products in the companies.], kind: table, supplement: [Tabelle]) <tab:hasanlegner-2023-dataproducts-companies>
#v(-0.5em)
#table(
  columns: (1fr, 2fr, 2fr, 2fr),
  stroke: 0.5pt,

  [*Company*], [*Motivation for data products*], [*Data product definition and characteristics*], [*Categories and examples of data products*],

  [PackF],
  [
    • Scaling analytics  
    • Share insights with different customers  
    • Find new revenue stream
  ],
  [
    *Definition:* A product that facilitates an end goal using data  
    *Characteristics:* C3, C4
  ],
  [
    *Data and insights:* HR data, accounts and hierarchy data, analytics report, composite data  
    *Value-add:* Predictive maintenance algorithm  
    *Data exchange:* APIs
  ],

  [ManufO],
  [
    • Reduce the time to market  
    • Increase data sharing across domains  
    • Improve governance to enhance consumability and data quality
  ],
  [
    *Definition:* Autonomous, read-optimized and standardized data unit containing at least one dataset (domain dataset) created to satisfy user needs  
    *Characteristics:* C1, C2, C4, C5
  ],
  [
    *Source-aligned:* Master data objects, finance data  
    *Consumer-aligned:* Lists/tables of analytical data, analytics algorithm, HR dashboards, KPIs, metrics, APIs
  ],

  [TeleC],
  [
    • Provide data to consumers quickly  
    • Enhance user experience  
    • Develop a data-driven culture  
    • Improve compliance
  ],
  [
    *Definition:* Packaging of data and code at various level of preparedness and refinement for reusability to support multiple business usage scenarios  
    *Characteristics:* C3, C4, C5
  ],
  [
    *Foundational:* Customer data, aggregated data  
    *Insight:* Supply chain dashboard  
    *Data delivery:* Algorithms, ML model
  ],

  [FoodM],
  [
    • Harmonize fragmented data pipelines  
    • Grasp consumption mechanisms of end users  
    • Improve governance and data quality
  ],
  [
    *Definition:* Mash of the correct delivery mechanism, compliance, access control, quality and security of the data to be provided to the organization  
    *Characteristics:* C2, C5
  ],
  [
    *Source-aligned:* Master data objects, transactional data, cross-functional data  
    *Consumer-aligned:* BI dashboards, corporate reporting
  ],
)


== Data Products Arten
#show figure: set block(breakable: true)

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    stroke: 0.5pt,
    inset: 8pt,

    // Header
    table.header(
      [*Quellenbasis*],
      [*Produktarten*],
      [*Eigenschaften der Produktarten*],
    ),

    // --- Pessi 2025 ---
    table.cell(rowspan: 3)[
      #dhbwCite("pessi_turning", page: "36")
    ],
    [Source-aligned Products],
    [Nahe am ursprünglichen Rohdatenformat. Unabhängig von konkreten Use Cases und dienen als Grundlage für weitere Data Products. Ermöglichen die Wiederverwendung und Erweiterung zu anderen Data Products.],

    [Consumer-aligned Products],
    [Werden gezielt erstellt, um eine konkrete Anforderung oder einen spezifischen Use Case zu erfüllen. Daten sind bereits entsprechend der Bedürfnisse einer bestimmten Nutzergruppe aufbereitet.],

    [Intermediate Products],
    [Liegen zwischen Rohdaten und nutzerorientierten Data Products. Enthalten teilweise aufbereitete Logik, sind jedoch zu generisch, um direkt konkrete Nutzeranforderungen zu erfüllen.],

    // --- Hasan & Legner 2023 ---
    table.cell(rowspan: 3)[
      #dhbwCite("hasan_understanding", page: "12")
    ],
    [Basic Data Products],
    [Stellen grundlegende Datensätze bereit, die zur Exploration und Analyse eines bestimmten Fachbereichs genutzt werden können. Dienen vor allem dem Aufbau von Basiswissen über eine Domäne.],

    [Analytical Data Products],
    [Entstehen durch Anwendung einfacher analytischer Methoden auf Basic Data Products. Liefern verdichtete Erkenntnisse über aktuelle und vergangene Trends für operative und strategische Entscheidungen.],

    [Advanced Analytical Data Products],
    [Basieren auf fortgeschrittenen analytischen Verfahren (z.~B. Machine Learning). Ermöglichen Prognosen und Handlungsempfehlungen und können automatisierte Entscheidungen unterstützen.],

    // --- Nizamis 2025 ---
    table.cell(rowspan: 1)[
      #dhbwCite("nizamis_data-as-a-product_2025", page: "795–797")
    ],
    [Architekturbausteine von Data Products],
    [Data Products bestehen aus mehreren Komponenten: Data Containers (Sammeln und Vereinheitlichen von Daten aus verschiedenen Quellen), Data Transformation Services (Zusammenführen und Aufbereiten von Rohdaten), Identity & Access Management (Verwaltung von Nutzern und Zugriffsrechten), Data Provenance & Traceability (Nachverfolgbarkeit der Herkunft und Änderungen von Daten) sowie Data Space & Marketplace (Plattform zur Auffindbarkeit und kontrollierten Bereitstellung von Daten).],

    // --- Dehghani 2022 ---
    table.cell(rowspan: 1)[
      #dhbwCite("dehghani_data_2022", page: "20–21")
    ],
    [Domänenbasierte Datenarten],
    [Source-aligned, Aggregate und Consumer-aligned domain data: Dehghani unterscheidet drei Datenarten nach Herkunft und Ausrichtung: Source-aligned data (operative Rohdaten einer Domäne), Aggregate data (domänenübergreifend zusammengeführte Daten) und Consumer-aligned data (use-case-spezifisch aufbereitete Daten). Anmerkung: Es handelt sich hierbei um eine Klassifikation von Datenarten, nicht von Data Product-Typen im Produktsinne – alle drei Kategorien beschreiben letztlich Datensätze #dhbwCite("niinikoski_defining", page: "14").],
  ),
  caption: [Übersicht der Produktarten und ihrer Eigenschaften],
) <tab:produktarten>


== Literaturanalyse & -bewertung


#figure(
  image("assets/matrix1_scatter.png", width: 80%),
  caption: [Matrix 1 – Verteilung der Literatur nach konzeptionellen Reifegraden]
) <fig-m1-scatter>

#figure(
  image("assets/matrix2_scatter.png", width: 80%),
  caption: [Matrix 2 – Verteilung der Literatur nach operativen Reifegraden]
) <fig-m2-scatter>

#figure(
  image("assets/annex_matrix1_axis1_time.png", width: 80%),
  caption: [Matrix 1 – Zeitliche Entwicklung der konzeptionellen Ausarbeitung]
) <fig-annex-m1-a1>

#figure(
  image("assets/annex_matrix1_axis2_time.png", width: 80%),
  caption: [Matrix 1 – Zeitliche Entwicklung der Umsetzungsorientierung]
) <fig-annex-m1-a2>

#figure(
  image("assets/annex_matrix2_axis1_time.png", width: 80%),
  caption: [Matrix 2 – Zeitliche Entwicklung der Nutzenorientierung]
) <fig-annex-m2-a1>

#figure(
  image("assets/annex_matrix2_axis2_time.png", width: 80%),
  caption: [Matrix 2 – Zeitliche Entwicklung der Betriebsreife]
) <fig-annex-m2-a2>

#figure(
  image("assets/matrix1_avg_over_time.png", width: 80%),
  caption: [Matrix 1 – Durchschnittliche konzeptionelle Reife im Zeitverlauf]
) <fig-m1-avg>

#figure(
  image("assets/matrix2_avg_over_time.png", width: 80%),
  caption: [Matrix 2 – Durchschnittliche operative Reife im Zeitverlauf]
) <fig-m2-avg>



#figure(
  table(
    columns: 5,
    align: (left, center, center, center, center),
    table.header(
      [*Quelle*],
      [*Matrix1 – Konzeptuelle Konkretisierung des Data-Product-Gedankens*],
      [*Matrix1 – Implementierungsnähe des vorgeschlagenen Designs*],
      [*Matrix2 – Wie stark ist es ein Produkt für Nutzer und Nutzen*],
      [*Matrix2 – Wie gut es technisch und organisatorisch betrieben werden kann*],
    ),
    [2025_Niinikoski], [3], [2], [2], [2],
    [2025_Nizamis], [2], [3], [3], [3],
    [2025_Pessi], [3], [3], [2], [2],
    [1991_Wang], [1], [1], [0], [0],
    [2003_Cai], [1], [1], [0], [1],
    [2019_Dehghani], [3], [3], [1], [0],
    [2018_Meierhofer-et-al], [2], [2], [1], [1],
    [2016_Davenport], [1], [2], [1], [0],
    [2006_Nam], [1], [0], [0], [0],
    [2004_Davidson], [1], [0], [1], [2],
    [2000_Shankaranarayanan], [1], [1], [1], [1],
    [1996_Wang], [0], [0], [0], [0],
    [2023_Hasan-Legner], [3], [3], [3], [2],
    [2024_Blohm], [3], [2], [2], [0],
    [2024_Hasan-Legner], [3], [2], [2], [1],
    [2003_Ballou], [1], [1], [1], [0],
    [1995_Wang], [1], [0], [0], [0],
    [2009_Madnick], [2], [1], [1], [0],
    [2015_Huang], [2], [2], [2], [1],
  ),
  caption: [Bewertungsmatrix der Literaturquellen]
) <tab-bewertungsmatrix>
#dhbwCite("niinikoski_defining"),
#dhbwCite("nizamis_data-as-a-product_2025"),
#dhbwCite("pessi_turning"),
#dhbwCite("wang_manage"),
#dhbwCite("cai_evaluating"),
#dhbwCite("Dehghani2019_DataMesh"),
#dhbwCite("meierhofer_data_2018"),
#dhbwCite("davenport_designing_2016"),
#dhbwCite("nam_news_2006"),
#dhbwCite("davidson_developing_2004"),
#dhbwCite("shankaranarayanan_ip-map_2000"),
#dhbwCite("wang_beyond_1996"),
#dhbwCite("hasan_understanding"),
#dhbwCite("blohm_data_2024"),
#dhbwCite("hasan_improving_2024"),
#dhbwCite("ballou_modeling_1998"),
#dhbwCite("wang_framework_1995"),
#dhbwCite("madnick_overview_2009"),
#dhbwCite("huang_data_2015")

  Matrix 1 bewertet die konzeptionelle Reife des Data-Product-Gedankens innerhalb einer Quelle. Untersucht wird, ob und in welcher Form das Konzept eines Data Products theoretisch ausgearbeitet wird. Maßgeblich sind dabei Aussagen zu Begriffen, strukturellen Bausteinen oder organisatorischen Betriebsmodellen von Data Products. Technische Beschreibungen von Datenverarbeitungssystemen oder Datensätzen allein gelten nicht als Ausarbeitung eines Data-Product-Ansatzes.
Matrix 2 bewertet dagegen die Produkt- und Betriebsreife des tatsächlich beschriebenen Datenangebots. Hier wird analysiert, inwieweit die bereitgestellten Daten als nutzungsorientiertes Produkt ausgestaltet sind und ob ein geregelter technischer oder organisatorischer Betrieb erkennbar ist. Also die tatsächlich mögliche konkrete operative umsetzung des vorgeschlagenem modells. Weniger strategisch betrachtet sondern use case bezogen. es geht darum ob das operationalisierte konzept geht also ob etwas konkret an einem use case oder beispiel umsetztbar gemacht wurde. bsp ein konzept für einen konkreten use case oder es wurde tatsächlich ein data produkt gebaut.

Matrix 1:
1.	Konzeptuelle Konkretisierung des Data-Product-Gedankens
-	Stufe 1
Die Quelle verwendet den Begriff Data Product oder beschreibt Datenangebote allgemein.
Begriffe werden erläutert oder bestehende Ansätze zusammengefasst.
Ein eigenes konzeptionelles Modell entsteht nicht.
-	Stufe 2
Die Quelle beschreibt zentrale Bausteine eines Data Products.
Elemente wie Nutzer, Nutzen, Qualität, Ownership, Schnittstellen oder Architektur werden systematisch dargestellt.
-	Stufe 3
Die Quelle beschreibt, wie Data Products organisatorisch betrieben werden sollen.
Rollen, Prozesse, Governance oder Wertschöpfung werden zusammenhängend dargestellt.
2.	Konkretisierung der Umsetzung eines Data-Product-Ansatzes
-	Stufe 1
Der Data-Product-Gedanke bleibt konzeptionell.
Es werden keine konkreten organisatorischen oder technischen Umsetzungsmechanismen beschrieben.
-	Stufe 2
Die Quelle beschreibt, wie ein Data-Product-Ansatz umgesetzt werden könnte.
Architektur, Rollen, Prozesse oder Plattformkomponenten sind erkennbar, bleiben jedoch allgemein.
-	Stufe 3
Die Umsetzung eines Data-Product-Ansatzes wird konkret beschrieben.
Strukturen, Prozesse oder technische Komponenten sind so ausgearbeitet, dass eine direkte Implementierung möglich erscheint.
Matrix 2:
1.	Wie stark ist es ein Produkt für Nutzer und Nutzen
-	Bewertungstufe 1:
Es werden Daten oder Informationen bereitgestellt.
Ein möglicher Zweck wird höchstens allgemein erwähnt.
-	Bewertungstufe 2:
Eine Zielgruppe oder ein wiederkehrender Bedarf ist erkennbar.
Die Daten sind bewusst zur Nutzung aufbereitet und unterstützen Analysen oder Entscheidungen.
-	Bewertungstufe 3:
Das Data Product erzeugt aktiv Mehrwert für Nutzer.
Es liefert Ergebnisse, Vorhersagen oder kontinuierliche Erkenntnisse und funktioniert wie ein Service.
2.	Wie gut es technisch und organisatorisch betrieben werden kann
-	Bewertungstufe 1:
Daten werden erzeugt oder verarbeitet, aber ohne geregelten Betrieb.
-	Bewertungstufe 2:
Technische Verarbeitung existiert.
Qualität, Zugriff oder Verantwortlichkeiten sind teilweise geregelt.
-	Bewertungstufe 3:
Das Data Product ist dauerhaft betreibbar.
Verantwortlichkeiten, Qualität, Zugriff und Lifecycle sind klar geregelt oder automatisiert.

#dhbwCite("niinikoski_defining")
- Wertorientiert: analysiert literatur, auch in historischer betrachtung auf Werte von Data Products, viel im Data Mesh kontext, extrahiert auch Werte durch befragung von verschiedene Unternehmen

Matrix 1: 
Achse Konzeptuelle Konkretisierung des Data-Product-Gedankens = 3 
Stufe 1,2,3: Chapter 2 stellt komplette Literaturanalyse sowie extrahiert eigenschaften (wie ownership, qualität, etc.) als merkmale 
Stufe 4: Figure 16 S. 61 “An example of data products structure in case company”
Warum nicht 5: Rollen, Verantwortlichkeiten, Strutkur für daten access plattlform (wertschöpfung) nicht genau beschrieben, sondern nur als to do gekennzeichnet in Figure 17 S. 63 „Suggested actions for the case companie“
	Achse entierungsnähe des vorgeschlagenen Designs = 2
Prozesse allgemein beschrieben, sowie ein plan zur direkten umsetzung wurde ausgearbeitet. Der plan der umsetzung beinhaltet allerdings die das definieren ´von apsekten wie ziele, rolen, reponsiblities, governance models, Die beschreibung könnte operationalisiert werden ja aber es muss noch viel definiert werden s. Figure 17
Matrix 2: S. 65
	Wie stark ist es ein Produkt für Nutzer und Nutzen = 2 Die Quelle definiert Data Products explizit als produktisierte Einheiten zur Erfüllung konkreter analytischer Kundenbedarfe. Es werden Value, Nutzerzahl, strategische Ausrichtung und Portfolio-Management genannt. Damit ist eine klare Zielgruppe und Nutzenorientierung vorhanden.
Es wird jedoch kein real betriebenes Data Product mit nachweislichem kontinuierlichem Mehrwert beschrieben. Daher keine 3.
	Wie gut es technisch und organisatorisch betrieben werden kann = 2 Ownership, Lifecycle, Governance, Self-Serve-Plattform und Portfolio-Manager werden klar beschrieben. Es existieren Kriterien für Einführung und Steuerung (Need, Value, Feasibility, Strategy Fit).
Es fehlt jedoch eine konkrete, technisch implementierte oder operational nachgewiesene Umsetzung eines Data Products im Unternehmen. Daher keine 3.


#dhbwCite("nizamis_data-as-a-product_2025")
-> technische Perspektive (Implementierung)
-> Architektur (Baut Architektur mit Komponenten auf)
-> wertorientiert (anwendung, Eigenschaften messbar gemacht)
-> organisatorisch (wenig, keine ownership modelle etc.)


Matrix 1: 
Achse Konzeptuelle Konkretisierung des Data-Product-Gedankens = 2
-	Stufe 1: erfüllt
S. 794-795: DaaP klar definiert/abgegrenzt („packaged … as products“, „standalone products“).
-	Stufe 2: erfüllt (kurzer Überblick, keine saubere Systematik)
S. 794-795: mehrere Definitionen/Varianten und verwandte Ansätze werden genannt (IBM, DaaS, AI-Model+Dataset etc.).
-	Stufe 3: teilweise erfüllt
S. 794: Merkmalsliste/Prinzipien (discoverable, interoperable, secure, self-describing; FAIR).
-	Stufe 4: erfüllt
S. 795-797: Referenzarchitektur + Building Blocks (Figure 1, Section 2).
-	Warum nicht 5:
Kein ganzheitliches Operating Model (Rollen/Prozesse/Wertschöpfung/Monetization nur angerissen bzw. „under development“). (S. 797)
Achse Implementierungsnähe des vorgeschlagenen Designs = 3
-	Stufe 1: erfüllt
Konkrete Komponenten statt Vision (Section 2). (S. 795-797)
-	Stufe 2: erfüllt
Architektur klar skizziert (Core + Data Space + Marketplace). (S. 795-796)
-	Stufe 3: erfüllt
Konkretes Design inkl. Tech/Mechanismen (NiFi/Spark/REST, Keycloak+ABAC, eIDAS, Hyperledger Fabric, Connector/Marketplace). (S. 796-797)
-	Stufe 4: erfüllt (Pilot-Operationalisierung)
Reales Experiment + End-to-End-Flow + frühe Evaluation (Figure 2/3). (S. 797-799)
-	Warum nicht 5:
Blueprint-/Skalierungsreife fehlt; Scalability/near real-time explizit nicht adressiert (Future Work). (S. 799)

Matrix 2:
Achse Produkt-/Nutzenorientierung = 3
-	Stufe 1:
erfüllt
S. 797: „the need of SSF to monitor and analyze the energy consumption in the production line“
-> klarer Anwendungskontext vorhanden.
-	Stufe 2:
Erfüllt, da ein konkreter betrieblicher Zweck beschrieben wird.
S. 797: „The experiment’s data analysis will allow the optimization of the factory and making better business decisions.“
-> Daten dienen explizit Entscheidungsunterstützung.
-	Stufe 3:
Erfüllt, da konkrete Nutzer und Data Consumer definiert sind.
S. 797: „data can be provided as-a-product to customers for further experimentation“
S. 797: „Uninova institute made use of the presented DaaP implementation to provide data analytics services to SSF“
-> bewusste Bereitstellung für identifizierbare Nutzergruppen.
-	Stufe 4:
Erfüllt, da Nutzen messbar bewertet wird.
S. 798: „DaaP has boosted Data Integration and Security procedures“
S. 799: „significant improvement regarding data pre-processing time“
-> nachweisbare operative Verbesserungen.
-	Warum nicht 5:
Das Data Product fungiert nicht als dauerhaft autonomer Service mit kontinuierlicher Vorhersage oder eigener Wertgenerierung.
Das Szenario bleibt ein „experimental scenario“ (S. 797) zur Validierung des Ansatzes.

Achse Technisch-organisatorische Betriebsfähigkeit = 3
-	Stufe 1:
erfüllt, da kein einmalig erzeugtes Artefakt vorliegt.
-	Stufe 2:
Erfüllt durch vorhandene technische Datenpipeline.
S. 798: „data from SSF were made available through a Sovity Data Space connector“
-	Stufe 3:
Erfüllt durch integrierte Qualitätssicherung und Evaluation.
S. 798: „quality assurance mechanisms“
S. 798: „An early evaluation of this experiment was performed“
-	Stufe 4:
Erfüllt durch Governance-, Security- und Transformationsregeln innerhalb des Data Products.
S. 798: „data transformation, pre-processing, security and governance were covered by DaaP“
-	Stufe 5:
Erfüllt durch plattformbasierten Betrieb mit Discoverability und automatisierter Nutzung.
S. 798: „published on the Marketplace to make them discoverable by potential data consumers“
S. 798: „create and automate optimization tasks“

#dhbwCite("pessi_turning", page: "41")
- Architektur (beschreibt architektur)
- Setzt technische architektur um 
- Wertorientierung (beschreibt nutzen, gründe un dvorteile von data products)
- organisatorisch (beschreibt das ohne entsprechende kommunikation, koordination ein dezentraler ansatz wie ein data mesh auf grundlage von data products in verteilten unerreichbaren silos enden könnte,)
Matrix 1:
Achse 1: 3 - Figure 14 S. 38
Achse 2: 3 Figure 14 Figure 15 S.38 - 40
Matrix 2: Achse 1 = 2, Achse 2 = 2 es wird kein konkretes Data Product mit realen Daten umgesetzt oder Betrieben
Es wird diskutiert in 4.2:
- Was ein Data Product ist (Purpose, Ownership, Metadata).
- Welche Bestandteile es hat (Input/Output Ports, Internal Logic, Product Wrapper).
- Wie es kategorisiert werden kann (source-aligned, consumer-aligned, intermediate).
- Welche Governance-Anforderungen gelten (Owner, Lifecycle, Katalogeintrag).
In 4.3 geht es einen Schritt weiter in Richtung technische Architektur. Dort wird beschrieben:
- Git-Repositories
- Deployment-Automatisierung
- Compute-Orchestrator
- Lakehouse-Plattform
- IaC-Bausteine
- Self-Serve-Umgebungen
	Architekturvorschlag bzw Zielbild
2,2 ist angemessen, weil die Quelle sowohl einen klar definierten Produktzweck mit identifizierter Zielgruppe als auch eine konkret ausgearbeitete technische und organisatorische Architektur beschreibt, jedoch keinen real implementierten oder betriebenen Data-Product-Betrieb nachweist.

#dhbwCite("Masuoka1998")
Matrix 1:
Achse 1 = 0
Das Paper nutzt „data products“ im MODIS/EOSDIS-Processing-Level-Sinn (Level 1/2/3/4), erklärt Formate/Volumen/Geometrie und Bestellhinweise. Es entsteht kein allgemeines Data-Product-Konzept (Nutzer/Nutzen/Ownership/Governance als Modell) und kein Literaturvergleich zum Begriff.
Achse 2 = 1
-	Es strukturiert Daten als klar definierte Produkte (Level 1/2/3/4).
-	Es beschreibt Produktmerkmale (Formate, Volumen, Granules, Tiles, Grids).
-	Es adressiert Nutzbarkeit („welches Level ist am einfachsten zu verwenden?“).
-	Es organisiert Produktion, Archivierung, Distribution (DAACs, PGE, EOSDIS).
-	Es trennt Produktvarianten nach Zielgruppen (Land/Ocean/Atmosphere, Climate Grid etc.).
Das ist ein starkes produktorientiertes Datenverständnis - aber technisch-wissenschaftlich.
Was fehlt im Sinne eines DaaP-Modells:
-	Kein explizites Ownership-Modell (Data Product Owner etc.).
-	Kein Governance-Framework.
-	Kein Lifecycle-Management im Produktmanagement-Sinn.
-	Kein Wertschöpfungsmodell.
-	Keine ökonomische oder organisatorische Einbettung als „Produktstrategie“.
Matrix 2:
Achse 1 = 2 
Klare Zielgruppe (Scientific Community), wiederkehrender Bedarf, Daten sind bewusst nutzbar aufbereitet (earth-located Level 3, Level 2G als nutzerfreundlicher), inklusive Empfehlungen für „easiest to use“. Kein Service/Forecasting im Sinne von Stufe 3.
Achse 2 = 2 
Betrieb ist geplant/strukturiert (DAACs, Archiv/Distribution, definierte Prozesse, Toolkits/Libs, Subsetting-Roadmap, Qualitäts-/Bias-Korrektur bei Geolocation). Aber kein explizites Lifecycle-/Governance-Modell im DaaP-Sinn (Produktverantwortung, SLAs, Deprecation etc.) → daher nicht 3.

#dhbwCite("Luhmann2008")
Matrix 1:
Aches 1 = 0 
der Begriff „data products“ lediglich als Bezeichnung für Datensätze bzw. Datenlevel verwendet (Level 0-3, Beacon). Es findet weder eine Begriffsdefinition noch eine konzeptionelle Diskussion des Data-Product-Gedankens statt.
Achse 2 = 1 
Der Text beschreibt technische Datenverarbeitung und Datenbereitstellung innerhalb einer wissenschaftlichen Mission (Processing Levels, Datenformate, Portale, Zugriffsmöglichkeiten). Es wird jedoch kein Data-Product-Ansatz als organisatorisches oder konzeptionelles Modell implementiert oder operationalisiert. Aber man erkennt an, dass Daten bewusst als klar definierte Produkte mit Struktur, Inhalt und Nutzungskontext organisiert werden. Auch wenn kein theoretisches Modell entwickelt wird, wird zumindest ein Datenangebot in produktähnlicher Form beschrieben.
Matrix 2:
Achse 1 = 2
Eine klare Nutzungsperspektive ist erkennbar: Level 2 „key parameter“ sind als kalibrierte, verifizierte und „publishable“ Produkte für breite Nutzung, statistische Studien und Validierungen gedacht; Beacon-Daten sind explizit für Near-Realtime Space-Weather/Prediction relevant. Es bleibt jedoch bei Datenbereitstellung und Analyseunterstützung, ohne dass das Angebot als Service aktiv neue Ergebnisse/Vorhersagen als eigenes Produkt erzeugt.
Achse 2 = 2
Technische Verarbeitung und Bereitstellung sind klar organisiert (Processing Levels, Validierung durch Instrumentteams, Datenportale und APIs). Verantwortlichkeiten und Zugriffswege sind erkennbar, jedoch wird kein vollständiges Betriebsmodell eines dauerhaft gemanagten Data Products beschrieben.

#dhbwCite("meierhofer_data_2018")
Matrix 1:
Achse 1 = 2
Der Text entwickelt eine konzeptionelle Definition des Begriffs „data product“ und ordnet ihn in einen Service-Design-Kontext ein. Data Products werden als Anwendung von Data-Science-Kompetenzen beschrieben, die Nutzen für Nutzer erzeugen und dafür einen Wert zurückerhalten. Darüber hinaus werden zentrale Bausteine wie Nutzerperspektive, Nutzenorientierung sowie der Zusammenhang von Analytics und Service Design systematisch erläutert. Ein organisatorisches Betriebsmodell mit Rollen, Governance oder Wertschöpfungslogik wird jedoch nicht zusammenhängend ausgearbeitet.
Achse 2 = 2
Die Quelle beschreibt einen methodischen Ansatz zur Entwicklung von Data Products, der Service-Design-Phasen mit Data-Analytics-Methoden kombiniert. Dazu gehören beispielsweise ein Framework zur Verbindung von Nutzeranalyse und analytischen Methoden sowie Prozessschritte wie Zieldefinition, Datensammlung, Modellierung und iterative Verbesserung. Diese Darstellung zeigt grundsätzlich, wie ein Data-Product-Ansatz umgesetzt werden kann. Die Beschreibung bleibt jedoch auf einer abstrakten methodischen Ebene und liefert keine konkrete Architektur oder organisatorische Struktur, die eine direkte Implementierung ermöglichen würde.
Matrix 2:
Achse 1 = 1
Der Text beschreibt kein konkretes Datenangebot, das als nutzbares Produkt bereitgestellt wird. Stattdessen wird konzeptionell diskutiert, wie Data Products gestaltet werden können und wie Datenanalysen in nutzerorientierte Services integriert werden sollen. Zwar wird die Bedeutung von Nutzerbedürfnissen und Nutzen mehrfach hervorgehoben, jedoch werden keine Daten explizit als aufbereitete Analyse- oder Entscheidungsressource bereitgestellt. Damit bleibt der Ausschnitt auf der Ebene allgemeiner Daten- und Analyseverwendung.
Achse 2 = 1
Technische Datenverarbeitung wird im Text grundsätzlich erwähnt, etwa durch Beispiele wie Data Mining, Natural Language Processing oder analytische Modellierungsschritte. Diese werden jedoch ausschließlich als mögliche Komponenten eines Data-Product-Designs beschrieben und nicht als Teil eines konkreten operativen Systems. Es fehlen Angaben zu organisatorischen Verantwortlichkeiten, Qualitätssicherung, Zugriffskontrolle oder Lifecycle-Management. Somit wird lediglich die Existenz technischer Verarbeitung thematisiert, ohne dass ein geregelter technischer oder organisatorischer Betrieb eines Data Products erkennbar ist.

#dhbwCite("Dehghani2019_DataMesh")
Matrix 1:
Achse 1 = 3
Die Quelle beschreibt Data Products nicht nur begrifflich, sondern entwickelt ein umfassendes konzeptionelles Modell. Es werden systematisch zentrale Bausteine wie Discoverability, Addressability, Trustworthiness, Semantics, Interoperability und Security dargestellt sowie Rollen wie Data Product Owner und Data Engineers definiert. Zusätzlich wird der organisatorische Rahmen eines Data-Mesh-Ansatzes mit Governance, Domain-Ownership und Plattformstruktur erläutert.
Achse 2 = 3
Die Quelle beschreibt die Umsetzung eines Data-Product-Ansatzes sehr konkret. Es werden technische und organisatorische Mechanismen genannt, etwa Data Catalogs, SLOs für Datenqualität, globale Standards für Interoperabilität, Zugriffskontrolle über RBAC sowie eine Self-Service-Data-Infrastructure-Plattform mit konkreten Funktionen wie Data Product Versioning, Monitoring oder Pipeline Orchestration. Die Kombination aus Rollen, Plattformkomponenten und Prozessen macht eine direkte Implementierung grundsätzlich nachvollziehbar.

Matrix 2:
Achse 1 = 1
Der Text beschreibt zumindest einen möglichen Zweck von Datenangeboten und nennt konkrete potenzielle Nutzergruppen wie Data Scientists, ML Engineers und Data Engineers. Zudem wird anhand des Beispiels der „play events“-Domain gezeigt, dass Daten für unterschiedliche Analysebedarfe bereitgestellt werden könnten (z. B. Echtzeit-Events oder aggregierte historische Daten). Diese Beschreibung bleibt jedoch rein illustrativ und zeigt kein tatsächlich bereitgestelltes Datenprodukt.
Achse 2 = 0
Der Text beschreibt keinen tatsächlichen Betrieb eines konkreten Data Products. Rollen, Infrastrukturkomponenten und Governance-Mechanismen werden ausschließlich auf konzeptioneller Ebene diskutiert und nicht an einem real implementierten Datenangebot gezeigt. Eine operative Umsetzung oder ein konkret betriebenes Datenprodukt ist im Ausschnitt daher nicht erkennbar.
#dhbwCite("wang_manage")
Matrix 1
1.	Konzeptuelle Konkretisierung des Data-Product-Gedankens
Stufe 1
Der Text führt die Idee ein, Information als „product“ zu betrachten und formuliert mit dem „information product approach“ vier grundlegende Prinzipien (Nutzerbedürfnisse verstehen, Produktionsprozess managen, Lifecycle managen, Information Product Manager einsetzen). Nutzer, Qualität und organisatorische Verantwortung werden erwähnt, jedoch nur auf allgemeiner Managementebene. Eine systematische Beschreibung struktureller Bausteine eines Data Products - etwa Produktstruktur, Schnittstellen, Datenkomponenten oder Architektur - erfolgt nicht.
Für Stufe 2 müsste die Quelle zentrale Bausteine eines Data Products systematisch darstellen, etwa wie ein Data Product aus Elementen wie Datensatz, Metadaten, Schnittstellen, Ownership oder Architektur aufgebaut ist. Der Text beschreibt jedoch nur Managementprinzipien für Informationsqualität und Organisationsverantwortung. Es fehlt eine strukturelle Modellierung dessen, was ein Data Product konkret ist oder aus welchen Komponenten es besteht. Daher bleibt der konzeptionelle Beitrag auf der Ebene einer grundlegenden Perspektive („Information als Produkt“) und erreicht nicht die systematische Bausteinbeschreibung von Stufe 2.
2.	Konkretisierung der Umsetzung eines Data-Product-Ansatzes
Stufe 1
Die Quelle beschreibt organisatorische Prinzipien wie Lifecycle-Management, Qualitätsdimensionen, Prozesskontrollen und die Rolle eines Information Product Managers. Diese Elemente zeigen, dass Information bewusst gemanagt werden soll. Die Darstellung bleibt jedoch normativ und konzeptionell; konkrete Umsetzungsstrukturen eines Data-Product-Ansatzes werden nicht ausgearbeitet.
Für Stufe 2 müsste erkennbar sein, wie ein Data-Product-Ansatz organisatorisch oder technisch umgesetzt werden könnte, etwa durch erkennbare Architektur, Plattformkomponenten, Datenpipelines oder klar strukturierte Produktorganisation. Der Text beschreibt jedoch lediglich Managementprinzipien für Informationsqualität und organisatorische Verantwortung. Es wird weder eine technische Architektur noch eine konkrete Organisationsstruktur für den Betrieb von Data Products dargestellt. Deshalb bleibt die Operationalisierung auf einer allgemeinen Empfehlungsebene und erreicht nicht die Umsetzungsnähe von Stufe 2.
Matrix 2:
1.	Wie stark ist es ein Produkt für Nutzer und Nutzen
Bewertungstufe 0
Der Text diskutiert Informationen grundsätzlich als organisationales Gut und betont deren Bedeutung für Entscheidungen und Prozesse. Die beschriebenen Beispiele (z. B. Kontoinformationen, Produktionsspezifikationen oder Sicherheitsdatenblätter) dienen lediglich zur Illustration von Informationsqualitätsproblemen. Ein konkret ausgestaltetes Datenprodukt mit klar definierter Nutzung oder Produktstruktur wird im Ausschnitt nicht beschrieben.
2.	Wie gut es technisch und organisatorisch betrieben werden kann
Bewertungstufe 0
Der Artikel beschreibt kein operatives Datenangebot und keinen realen Betrieb eines Datenprodukts. Es werden lediglich generelle Managementprinzipien für Informationsqualität diskutiert. Technische Infrastruktur, konkrete Betriebsprozesse oder ein implementiertes Produktmodell sind im Text nicht erkennbar.
#dhbwCite("cai_evaluating")
Matrix 1:
1.	Konzeptuelle Konkretisierung des Data-Product-Gedankens
•	Stufe 1
Die Quelle entwickelt ein Konzept rund um „Information Products“ (IP) und argumentiert „Information as Product“, aber sie definiert nicht „Data Products“ als organisationales Produktkonzept mit typischen Bausteinen wie Ownership/Governance/Value-Logik. „Ownership“ im Sinne eines Data Product Owners oder klarer Verantwortungsmodelle wird im Ausschnitt nicht als Bestandteil eines Data Products definiert; der Nutzen wird eher über „Decision-Maker brauchen Quality-Assessment“ motiviert, nicht als Value Proposition eines Data Products systematisch ausgearbeitet.
2.	Konkretisierung der Umsetzung eines Data-Product-Ansatzes
•	Stufe 1
Es gibt Formeln und ein Bewertungsverfahren zur Messung von Completeness auf IP-Ebene (Dj, Ei, C, wi) und ein Modell (IPMAP) zur Abbildung der Herstellung eines IP. Aber es wird keine Umsetzung eines Data-Product-Ansatzes beschrieben (keine Plattform-/Produktarchitektur, keine Rollen-/Prozesslandschaft für Data Products, kein Lifecycle-Betrieb), sondern „nur“ ein theoretisch anwendbares Messframework.
Matrix 2:
1.	Wie stark ist es ein Produkt für Nutzer und Nutzen
•	Stufe 0
Im Ausschnitt wird kein konkretes Data Product gebaut oder als nutzungsfertiges Artefakt beschrieben; es geht um ein Bewertungsmodell für Vollständigkeit von Information Products. Das Beispiel (Widget Inc.) zeigt lediglich, wie man die Kennzahl rechnerisch auf einen Report/Forecast anwenden könnte - das ist eher „Messung für Entscheidungen“ als ein operationalisiertes Nutzerprodukt.
2.	Wie gut es technisch und organisatorisch betrieben werden kann
•	Stufe 1
Es gibt keinen geregelten Betrieb eines konkreten Datenangebots: keine Ownership-Struktur, keine Zugriffs-/Bereitstellungsprozesse, keine Qualitäts-SLOs/Monitoring, kein Lifecycle. Im Gegenteil: die Quelle weist sogar darauf hin, dass subjektive Gewichte missbraucht werden könnten und dass dafür erst ein Incentive-System „müsste“ geschaffen werden - das unterstreicht, dass der Betrieb nicht konkret operationalisiert ist.

#dhbwCite("davenport_designing_2016")
Matrix 1:
1.	Konzeptuelle Konkretisierung des Data-Product-Gedankens
•	Stufe 1
Der Ausschnitt nutzt „data products“ als Begriff und grenzt sie grob als Kombination aus Daten + Analytics ein, plus Markt-/Bedarfslogik („marketplace need“). Aber zentrale Data-Product-Bausteine, die du erwartest (Ownership/Data Owner, verbindliches Nutzenversprechen als Produktverantwortung, Lifecycle/Governance als Produktlogik), werden im Ausschnitt nicht systematisch ausgearbeitet.
2.	Konkretisierung der Umsetzung eines Data-Product-Ansatzes
•	Stufe 2 (schwach)
Es wird ein konkretes Vorgehensmodell skizziert (7 Schritte von Conceptualize bis Market Feedback) und mit iterativem MVP/Lean-Startup-Denken sowie Feedbackmechaniken (Usage-Metriken, A/B-Tests) verknüpft. Das bleibt generisch und ist kein direkt implementierbares Operating Model, aber es beschreibt plausibel, wie man einen Data-Product-Ansatz organisatorisch/prozessual angehen könnte.
Matrix 2:
1.	Wie stark ist es ein Produkt für Nutzer und Nutzen
•	Bewertungstufe 1
Es werden Daten/Informationen mit Analytics als wertstiftend beschrieben und Beispiele genannt, aber kein einzelnes Data Product als konkret ausgestaltetes Produkt mit definiertem Output/Service und klarer Zielgruppe „durchdekliniert“. Damit bleibt es eher Nutzenargumentation auf Meta-Ebene als ein operationalisiertes Produkt.
2.	Wie gut es technisch und organisatorisch betrieben werden kann
•	Bewertungstufe 0
Im Ausschnitt ist kein konkretes Datenangebot beschrieben, für das Verantwortlichkeiten, Zugriff, Qualität oder Lifecycle als Betriebssystematik festgelegt wären. Es gibt nur allgemeine Hinweise (z.B. Cloud/Distribution/Feedback), aber keinen geregelten Betrieb eines spezifischen Data Products, daher „nicht vorhanden“ im Sinne deiner Achse.

#dhbwCite("davidson_developing_2004")
Matrix 1 - Achse 1 (Konzeptuelle Konkretisierung des Data-Product-Gedankens): 1
Die Quelle bezeichnet den halbjährlichen Patient-Discharge-Datensatz zwar als „Information Product“ und nennt Qualitätsanforderungen sowie organisatorische Zuständigkeiten. Eine konzeptionelle Ausarbeitung eines modernen Data-Product-Ansatzes (z. B. systematische Produktbausteine wie Nutzenlogik, Schnittstellen/Architektur, Produktmanagement/Lifecycle) erfolgt jedoch nicht; der Fokus bleibt auf Datenqualitäts- und Compliance-Logik.
Matrix 1 - Achse 2 (Konkretisierung der Umsetzung eines Data-Product-Ansatzes): 0
Die Quelle beschreibt operative DQ-Umsetzungsschritte (DPG → DQMWG, Production Maps, Vorab-Audits, Testläufe) zur Sicherstellung einer korrekten Submission. Diese Mechanismen operationalisieren jedoch primär einen Datenqualitäts-/Submission-Prozess und nicht die Umsetzung eines modernen Data-Product-Ansatzes (keine definierte Bereitstellung/Consumability, keine Contracts/Schnittstellen, keine Plattform- oder Produktbetriebslogik).
Matrix 2 - Achse 1 (Wie stark ist es ein Produkt für Nutzer und Nutzen): 1
Es werden Daten/Informationen als Submission-Dataset bereitgestellt; der Zweck ist primär die Erfüllung externer Vorgaben, mit höchstens implizitem Nutzen über Compliance (Vermeidung von Rework/Strafen). Eine nutzungsorientierte Ausgestaltung als konsumierbares Produkt (z. B. klare Bereitstellungsform, Nutzungsszenarien über die Abgabe hinaus) wird nicht beschrieben.
Matrix 2 - Achse 2 (Wie gut es technisch und organisatorisch betrieben werden kann): 2
Der Ablauf ist wiederholbar organisiert (Halbjahreszyklus) und es existieren klare Verantwortungs- und Qualitätsmechanismen (DPG/DQMWG, Owner-Departments, Production Maps, Audits/Testläufe). Für eine 3 fehlen jedoch produktrelevante Betriebsdetails wie definierte Zugriffs-/Bereitstellungsmechanismen, explizite Schnittstellen/Contracts sowie ein umfassender Lifecycle-/Automatisierungsrahmen über den reinen Submission-Prozess hinaus.

#dhbwCite("shankaranarayanan_ip-map_2000")
Matrix 1 - Achse 1 (Konzeptuelle Konkretisierung des Data-Product-Gedankens): 1
Die Quelle arbeitet ein „Information Product“-Konzept aus, aber funktional als Herstellprozess- und Qualitätslogik (IP-MAP) statt als modernes Data Product mit klarer Bereitstell-/Nutzungsschnittstelle, Produktlogik und Betriebsmodell. Moderne Produktmerkmale (Contracts/Interfaces, Publishing/Distribution, Lifecycle als Produkt) werden im Ausschnitt nicht konzeptionell als Data-Product-Ansatz entwickelt.
Matrix 1 - Achse 2 (Konkretisierung der Umsetzung eines Data-Product-Ansatzes): 1
Es werden zwar konkrete Mechaniken (Blocktypen, Metadaten, Quality Gates, Boundaries, Traceability) beschrieben, diese operationalisieren aber die Modellierung und Kontrolle der Datenherstellung, nicht die Umsetzung eines Data-Product-Ansatzes im heutigen Sinn. Architektur/Rollen/Prozesse erscheinen daher nicht als Data-Product-Implementierung (Serving, Zugriff, Contracts, Betrieb), sondern als DQ-/Manufacturing-Engineering.
Matrix 2 - Achse 1 (Wie stark ist es ein Produkt für Nutzer und Nutzen): 1
Die Outputs (Reports/Bills/externes Reporting) werden an benannte Empfänger geliefert, aber der Ausschnitt rahmt sie als Informationsartefakte aus internen Systemen, nicht als wiederverwendbares, konsumierbares Datenangebot mit explizitem Mehrwertversprechen. Ein klarer Produktnutzen über „Information bereitstellen“ hinaus wird nicht ausgearbeitet.
Matrix 2 - Achse 2 (Wie gut es technisch und organisatorisch betrieben werden kann): 1
Es gibt Prozessverantwortlichkeiten und Qualitätsprüfungen im Herstellfluss, aber kein geregelter Betrieb eines Datenangebots als Service (z. B. Zugriffskontrolle als Produktzugang, Monitoring/Feedback auf Produktebene, Lifecycle/Change/Versionierung). Damit ist „dauerhaft betreibbar“ im Data-Product-Sinn im Ausschnitt nicht erkennbar.

#dhbwCite("wang_beyond_1996")
Matrix 1, Achse 1: Stufe 0
Die Quelle ist eine empirische Studie zur Taxonomie von Datenqualitätsattributen. Der Data-Product-Begriff wird nicht verwendet, kein Konzept beschrieben - die Produktanalogie ist eine methodologische Fußnote ohne inhaltliche Ausarbeitung.
Matrix 1, Achse 2: Stufe 0
Es gibt keinen Ansatz, der auch nur entfernt als Umsetzung eines Data-Product-Konzepts gelesen werden könnte. Die Quelle endet mit einem Bewertungsframework für Qualitätsattribute.
Matrix 2, Achse 1: Stufe 0
Es wird kein Datenangebot für eine Nutzergruppe beschrieben. Die befragten „Data Consumer" sind Forschungssubjekte zur Ableitung von Qualitätsdimensionen, kein adressierter Nutzerkreis eines Produkts.
Matrix 2, Achse 2: Stufe 0
Es existiert kein betreibbares Datenangebot. Die Quelle ist reine Grundlagenforschung zur Datenqualitätswahrnehmung ohne jeden Produkt- oder Betriebsbezug.

Diese quelle handelt sich um Datenqualität.  Wang & Strong verwenden den Begriff „data product" explizit, wenn auch nur als methodologische Analogie: „an information system can be viewed as a data manufacturing system acting on raw data input to produce output data or data products." Der Begriff taucht im Text auf, wird aber nicht inhaltlich ausgearbeitet. Die quelle soll als Beleg dafür dienen, dass Qualitätsanforderungen historisch vor dem Produktgedanken existierten und erst später in Data-Product-Frameworks integriert wurden. 

#dhbwCite("hasan_understanding")
Matrix 1, Achse 1: Stufe 3
Die Quelle entwickelt eine überarbeitete, theoretisch fundierte Definition von Data Products, erarbeitet deren Charakteristika und Kategorien systematisch und bettet den Begriff explizit in die Produktmanagement-Literatur ein - als vierter Produkttyp neben physischen, Software- und digitalen Produkten. Der socio-technical lens wird als zentrales konzeptionelles Argument eingeführt: Data Products sind nicht rein technische Objekte, sondern von Organisationsstruktur, Strategie und Wirtschaftlichkeit geprägte Artefakte. Die konzeptionelle Ausarbeitung ist damit vollständig und eigenständig.
Matrix 1, Achse 2: Stufe 3
Der Data Product Canvas (Essays 3 & 4) ist ein konkretes, methodisch ausgearbeitetes Gestaltungswerkzeug entlang der Dimensionen Desirability, Feasibility und Viability. Er wurde mittels Design-Science-Methodik entwickelt und in einem Fortune-500-Unternehmen in realen Designprozessen angewendet. Damit liegt auf der konzeptuell-methodischen Ebene eine echte Implementierungskonkretisierung vor - nicht als technische Spezifikation, sondern als erprobtes Designartefakt.
Matrix 2, Achse 1: Stufe 3
Die Nutzerperspektive ist strukturbildend für die gesamte Dissertation. Die Fragen „why-to-build", „what-to-build" und „for/by whom" werden als zentrale Antecedents des Produktbaus positioniert. Consumer-Provider-Interaktion wird als eigenständiges Forschungsfeld behandelt (Essay 6). Rollen wie Data Product Owner und Data Product Manager sowie Mechanismen wie Data Catalog & Marketplace werden als wertschöpfende Strukturen für definierte Nutzergruppen konzeptualisiert.
Matrix 2, Achse 2: Stufe 2
Die Quelle beschreibt organisatorische Betriebsmechanismen - Data Contract, Data Product Lifecycle, Ownership, Governance-Einbettung und Work System Theory - zusammenhängend und kohärent. Rollen, Prozesse und Governance werden als aufeinander bezogenes Set dargestellt, das als Orientierungsrahmen für eine organisatorische Umsetzung dienen kann. Eine direkte technische Implementierung auf Basis dieser Quelle allein ist jedoch nicht möglich, da Schnittstellenspezifikationen, Architekturvorgaben und konkrete Qualitätsmechanismen fehlen.

#dhbwCite("blohm_data_2024")
Matrix 1 - Konzeptuelle Konkretisierung des Data-Product-Gedankens: 3
Die Quelle beschreibt Data Products nicht nur definitorisch, sondern bettet sie in ein organisatorisches Gesamtbild aus Rollen, Wertlogik und Governance ein. Data Products werden als wertorientierte Artefakte für definierte Nutzergruppen dargestellt und im Zusammenhang mit organisatorischen Verantwortlichkeiten wie Domain Ownership und Data-Product-Management diskutiert. Dadurch entsteht eine zusammenhängende Darstellung, wie Data Products organisatorisch gedacht und betrieben werden sollen.
Matrix 1 - Konkretisierung der Umsetzung eines Data-Product-Ansatzes: 2
Die Quelle beschreibt mehrere Elemente, wie ein Data-Product-Ansatz umgesetzt werden könnte, etwa Domain-orientierte Ownership, Self-Service-Data-Plattformen, föderierte Governance sowie Metadaten- und Katalogmechanismen. Architektur, Rollen und Plattformkomponenten sind damit klar erkennbar. Die Darstellung bleibt jedoch auf einem allgemeinen konzeptionellen Niveau ohne konkrete Implementierungsstrukturen.
Matrix 2 - Produktorientierung für Nutzer und Nutzen: 2
Data Products werden als Artefakte definiert, die wiederkehrende Informationsbedürfnisse bestimmter Nutzergruppen adressieren und Daten in konsumierbarer Form bereitstellen. Der Fokus liegt auf Nutzung, Wiederverwendbarkeit und Unterstützung von Analysen oder Anwendungen. Ein konkretes Data Product mit aktiv erzeugten Ergebnissen oder kontinuierlichen Services wird jedoch nicht beschrieben.
Matrix 2 - Technischer und organisatorischer Betrieb: 0
Die Quelle beschreibt kein konkretes Data Product mit geregeltem Betrieb. Aspekte wie Lifecycle, Monitoring, konkrete Qualitätsmetriken oder Schnittstellen eines spezifischen Produkts werden nicht ausgearbeitet. Stattdessen werden nur allgemeine Architektur- und Governanceprinzipien diskutiert.

#dhbwCite("hasan_improving_2024")
Matrix 1 - Achse 1: 3
Die Quelle entwickelt ein zusammenhängendes Verständnis von Data Products als organisatorisch betriebenen Artefakten zur Bereitstellung wiederverwendbarer Datenangebote. Dabei werden zentrale Elemente eines Data-Product-Betriebs systematisch dargestellt, darunter Rollen (Data Product Owner, Data Product Manager), Governance-Mechanismen sowie ein Data-Product-Lifecycle. Dadurch geht die Darstellung über eine reine Begriffsdefinition hinaus und beschreibt, wie Data Products organisatorisch betrieben werden sollen.
Matrix 1 - Achse 2: 2
Die Quelle beschreibt mehrere Mechanismen, mit denen ein Data-Product-Ansatz umgesetzt werden kann, etwa Data Contracts, Data Catalogs beziehungsweise Marketplaces, Rollenstrukturen sowie Lifecycle-Prozesse. Diese Elemente zeigen, wie Organisationen Data Products strukturell organisieren und bereitstellen könnten. Die Darstellung bleibt jedoch auf einem allgemeinen Organisations- und Governance-Level und enthält keine konkrete Architektur oder Implementierungsbeschreibung eines spezifischen Data Products.
Matrix 2 - Achse 1: 2
Data Products werden als Datenangebote beschrieben, die wiederkehrende Informationsbedürfnisse von Nutzern adressieren und Daten in eine konsumierbare Form überführen. Ein Beispiel ist ein „Sales 360° data product“, das verschiedene Datensätze kombiniert, um unterschiedliche analytische Anwendungsfälle zu unterstützen. Damit ist eine klare Zielgruppe und ein wiederkehrender Nutzungskontext erkennbar, auch wenn der Fokus primär auf der Bereitstellung analysierbarer Daten liegt und nicht auf einem eigenständigen Service mit kontinuierlichen Ergebnissen oder Vorhersagen.
Matrix 2 - Achse 2: 1
Die Quelle beschreibt keine konkrete Implementierung eines spezifischen Data Products. Stattdessen werden organisatorische Mechanismen und Fallbeispiele aus Unternehmen dargestellt, etwa Rollen, Plattformen oder Lifecycle-Phasen. Diese zeigen, wie ein Data-Product-Ansatz strukturiert werden kann, liefern jedoch keine operative Umsetzung eines einzelnen Data Products mit konkreten Datenpipelines, Architektur oder Betriebsprozessen. Es existiert keine operative tatsächliche Umsetzung aber das Betriebsmodell wird skizziert.
2003-Ballou- Modeling-Information-Manufacturing-Systems-to-Dete (1).pdf
Matrix 1 - Achse 1 (Konzeptuelle Konkretisierung des Data-Product-Gedankens): 1
Die Quelle nutzt zwar den Begriff „Information Product“ und rahmt Informationsentstehung als Manufacturing-Prozess, aber sie arbeitet den Data-Product-Gedanken im heutigen Sinn nicht aus (kein expliziter Purpose/Use-Case als Produktlogik, keine Ownership/Produktverantwortung, keine Schnittstellen-/Contract-Perspektive). Damit bleibt es konzeptionell primär Information-Manufacturing/Data-Quality und nicht ein Data-Product-Modell.
Matrix 1 - Achse 2 (Konkretisierung der Umsetzung eines Data-Product-Ansatzes): 1
Die Quelle konkretisiert eine Methode zur Modellierung und Analyse der Informationsherstellung (Bausteine, Metriken, Rechenbeispiel), aber nicht die Umsetzung eines Data-Product-Ansatzes als betreibbares Produkt. Es fehlen erkennbare Umsetzungsmechanismen für Bereitstellung/Plattform, Zugriff/Discovery, Rollen/Operating Model oder Lifecycle/Change, die eine Implementierung als Data Product nahelegen würden.
Matrix 2 - Achse 1 (Wie stark ist es ein Produkt für Nutzer und Nutzen): 1
Ein „Customer“-Bezug und eine Value-/Trade-off-Diskussion sind vorhanden, aber es wird kein klar abgegrenztes, konsumierbares Datenangebot für eine definierte Zielgruppe mit wiederkehrendem Bedarf beschrieben. Der Nutzen bleibt indirekt über Prozessoptimierung (Quality/Timeliness/Cost) statt über ein konkretes nutzungsorientiertes Data Product.
Matrix 2 - Achse 2 (Wie gut es technisch und organisatorisch betrieben werden kann): 0
Als modernes Data Product ist keine betreibbare Einheit beschrieben: kein definiertes Interface/Contract, keine Zugriffskontrolle/IAM, kein Monitoring/Feedback im Betrieb, kein Lifecycle/Change und keine explizite Produktverantwortung. Das Paper liefert ein Framework zur Analyse/Optimierung der Informationsproduktion, nicht eine operativ betreibbare Produktbereitstellung

1995-Wang- SURVEYIEEEKDEAug95.pdf
Matrix 1 - Konzeptuelle Konkretisierung des Data-Product-Gedankens: 1
Die Quelle verwendet den Begriff „data product“ und beschreibt Informationssysteme als „data manufacturing systems“, bei denen Rohdaten verarbeitet werden und als Output Datenprodukte entstehen.
Der Begriff dient jedoch hauptsächlich zur Erklärung von Datenqualität und Produktionsprozessen; ein eigenständiges konzeptionelles Modell für Data Products mit Rollen, Governance oder Betriebslogik wird nicht ausgearbeitet.
Matrix 1 - Konkretisierung der Umsetzung eines Data-Product-Ansatzes: 0
Das Paper entwickelt ein Framework zur Analyse von Data-Quality-Forschung mit Bereichen wie Management Responsibilities, Production und Distribution.
Diese Struktur dient der Einordnung von Forschung zu Datenqualität, enthält jedoch keine organisatorischen oder technischen Mechanismen zur Umsetzung eines Data-Product-Ansatzes.
Matrix 2 - Wie stark ist es ein Produkt für Nutzer und Nutzen: 0
„Data products“ werden lediglich als generischer Output eines Informationssystems beschrieben, etwa erzeugte oder korrigierte Datensätze.
Ein konkretes Datenangebot für eine definierte Nutzergruppe oder einen klaren Use Case wird im Text nicht ausgearbeitet.
Matrix 2 - Wie gut es technisch und organisatorisch betrieben werden kann: 0
Der Text behandelt Qualitätsmanagement, Fehlerkosten und Datenproduktionsprozesse, jedoch nicht den Betrieb eines konkreten Datenprodukts.
Elemente wie definierte Bereitstellung, Zugriff, Ownership, Monitoring oder Lifecycle eines nutzbaren Datenangebots sind im Ausschnitt nicht erkennbar.
2009-Madnick-1515693.1516680.pdf
Matrix 1 – Konzeptionelle Reife des Data-Product-Gedankens
1. Konzeptuelle Konkretisierung: Stufe 2 Die Quelle verwendet den Begriff „information product" explizit und beschreibt zentrale Bausteine systematisch: Der TDQM-Zyklus (Define, Measure, Analyze, Improve) strukturiert Qualität als Produkteigenschaft, und die Dimensionen von Wang & Strong (1996) liefern ein Rahmenwerk für Qualitätsanforderungen aus Nutzersicht. Elemente wie Nutzerrollen (Collector, Custodian, Consumer), Qualitätsmessung und konzeptuelle Modellierung (Quality ER, IPMap) werden als zusammenhängende Bausteine dargestellt. Ein vollständiges Betriebsmodell mit Governance, Lifecycle und Wertschöpfungslogik wird jedoch nicht geschlossen ausgearbeitet, weshalb Stufe 3 nicht erreicht wird.
2. Konkretisierung der Umsetzung: Stufe 1 Das Paper ist ein Überblicksartikel, der existierende Forschung kategorisiert und ein Klassifikationsframework vorschlägt. Konkrete Umsetzungsmechanismen wie Architekturen, Prozesse oder Plattformkomponenten werden zwar als Forschungsthemen benannt (COIN, IPMap, ETL-Frameworks), aber nur referenziert und nicht selbst ausgearbeitet. Es entsteht kein erkennbarer Umsetzungspfad für einen Data-Product-Ansatz — der Beitrag bleibt auf der konzeptionellen Ebene der Forschungslandkarte.

Matrix 2 – Produkt- und Betriebsreife des beschriebenen Datenangebots
1. Produkt für Nutzer und Nutzen: Stufe 1 Die Quelle postuliert zwar grundsätzlich, dass Daten als Produkt aus Konsumentensicht betrachtet werden sollten („fitness for use"), und benennt Rollen. Allerdings wird kein konkretes Datenangebot an einem Use Case beschrieben, bei dem eine Zielgruppe, ein wiederkehrender Bedarf oder eine bewusste Aufbereitung zur Nutzung operativ erkennbar wären. Die Aussagen bleiben auf der Ebene allgemeiner Forschungspostulate, nicht auf der Ebene eines tatsächlich ausgestalteten Produkts.
2. Technischer und organisatorischer Betrieb: Stufe 0 Es wird kein konkretes Datenangebot beschrieben, das in irgendeiner Form betrieben wird. Themen wie Monitoring, Cleansing, Lineage, Privacy und Security werden als Forschungsfelder kartiert, aber es gibt keinen Fall, in dem auch nur eine rudimentäre Betriebsstruktur für ein spezifisches Data Product dargestellt wird. Das Paper bewegt sich vollständig auf der Metaebene der Forschungsklassifikation.
Huang-2015- A-Data-as-a-Product-Model-for-Future-Consumption-of-Big-Stream-Data-in-Clouds.pdf
Matrix 1 – Konzeptionelle Reife des Data-Product-Gedankens
1. Konzeptuelle Konkretisierung: Stufe 2 Die Quelle definiert den Begriff Data-as-a-Product explizit und beschreibt strukturelle Bausteine systematisch. Das Modell unterscheidet drei Ebenen: Refine Modules zur Transformation von Rohdaten, die daraus entstehenden Data Products sowie ein DaaP Interface zur Bereitstellung an Anwendungen. Elemente wie Nutzerbezug, Qualitätsmessung, Schnittstellen und eine klare Abgrenzung zu Data-as-a-Service werden dargestellt. Eine Ausarbeitung organisatorischer Aspekte wie Ownership, Rollen, Governance oder Lifecycle fehlt jedoch, weshalb Stufe 3 nicht erreicht wird.
2. Konkretisierung der Umsetzung: Stufe 2 Das Paper bleibt nicht rein konzeptionell, sondern zeigt an drei Use Cases, wie Refine Modules Rohdaten in Data Products transformieren und wie anwendungsorientierte Mining-Module darauf arbeiten. Die Verarbeitungsketten werden für medizinische Sensordaten, Textdaten und GPS-Trajektorien jeweils konkret beschrieben. Architektur und Prozessschritte sind erkennbar und nachvollziehbar. Allerdings bleibt die Interface-Spezifikation vage, da zwar Standards gefordert, aber keine konkreten Definitionen oder Contracts geliefert werden. Eine direkte Implementierung des Gesamtmodells erscheint daraus noch nicht vollständig ableitbar.
Matrix 2 – Produkt- und Betriebsreife des beschriebenen Datenangebots
1. Produkt für Nutzer und Nutzen: Stufe 2 Die Data Products adressieren erkennbare Zielgruppen mit wiederkehrendem Bedarf. Ärzte nutzen Period Deviation Distributions zur Krankheitsdiagnose, Analysten nutzen Topic-Hotness-Kurven zur Ereigniserkennung, und Routenmuster werden aus GPS-Daten für Nutzerabfragen bereitgestellt. Die Daten sind bewusst zur Nutzung aufbereitet und auf etwa ein bis zwei Prozent der Originalgröße reduziert. Sie unterstützen konkrete Analysen und Entscheidungen. Allerdings funktionieren die Data Products nicht als eigenständiger Service mit kontinuierlicher Bereitstellung, sondern als Ergebnisse experimenteller Batch-Verarbeitungen.
2. Technischer und organisatorischer Betrieb: Stufe 1 Daten werden erzeugt und verarbeitet, aber ein geregelter Betrieb ist nicht erkennbar. Die drei Use Cases sind experimentelle Demonstrationen mit evaluierten Precision-Werten, nicht dauerhaft betriebene Systeme. Zugriffskontrolle, Monitoring, Verantwortlichkeiten, Lifecycle-Management oder Feedback-Mechanismen werden nicht beschrieben. Die Quelle postuliert zwar, dass Standards für Datenqualität und Interfaces nötig seien, liefert diese aber nicht. Der Betriebsaspekt bleibt eine Zukunftsvision für Cloud-Datacenter.

Matrix 1 bewertet die konzeptionelle Reife des Data-Product-Gedankens innerhalb einer Quelle. Untersucht wird, ob und in welcher Form das Konzept eines Data Products theoretisch ausgearbeitet wird. Maßgeblich sind dabei Aussagen zu Begriffen, strukturellen Bausteinen oder organisatorischen Betriebsmodellen von Data Products. Technische Beschreibungen von Datenverarbeitungssystemen oder Datensätzen allein gelten nicht als Ausarbeitung eines Data-Product-Ansatzes.
Matrix 2 bewertet dagegen die Produkt- und Betriebsreife des tatsächlich beschriebenen Datenangebots. Hier wird analysiert, inwieweit die bereitgestellten Daten als nutzungsorientiertes Produkt ausgestaltet sind und ob ein geregelter technischer oder organisatorischer Betrieb erkennbar ist. Also die tatsächlich mögliche konkrete operative umsetzung des vorgeschlagenem modells. Weniger strategisch betrachtet sondern use case bezogen. es geht darum ob das operationalisierte konzept geht also ob etwas konkret an einem use case oder beispiel umsetztbar gemacht wurde. bsp ein konzept für einen konkreten use case oder es wurde tatsächlich ein data produkt gebaut.

Matrix 1:
1.	Konzeptuelle Konkretisierung des Data-Product-Gedankens
-	Stufe 1
Die Quelle verwendet den Begriff Data Product oder beschreibt Datenangebote allgemein.
Begriffe werden erläutert oder bestehende Ansätze zusammengefasst.
Ein eigenes konzeptionelles Modell entsteht nicht.
-	Stufe 2
Die Quelle beschreibt zentrale Bausteine eines Data Products.
Elemente wie Nutzer, Nutzen, Qualität, Ownership, Schnittstellen oder Architektur werden systematisch dargestellt.
-	Stufe 3
Die Quelle beschreibt, wie Data Products organisatorisch betrieben werden sollen.
Rollen, Prozesse, Governance oder Wertschöpfung werden zusammenhängend dargestellt.
2.	Konkretisierung der Umsetzung eines Data-Product-Ansatzes
-	Stufe 1
Der Data-Product-Gedanke bleibt konzeptionell.
Es werden keine konkreten organisatorischen oder technischen Umsetzungsmechanismen beschrieben.
-	Stufe 2
Die Quelle beschreibt, wie ein Data-Product-Ansatz umgesetzt werden könnte.
Architektur, Rollen, Prozesse oder Plattformkomponenten sind erkennbar, bleiben jedoch allgemein.
-	Stufe 3
Die Umsetzung eines Data-Product-Ansatzes wird konkret beschrieben.
Strukturen, Prozesse oder technische Komponenten sind so ausgearbeitet, dass eine direkte Implementierung möglich erscheint.
Matrix 2:
1.	Wie stark ist es ein Produkt für Nutzer und Nutzen
-	Bewertungstufe 1:
Es werden Daten oder Informationen bereitgestellt.
Ein möglicher Zweck wird höchstens allgemein erwähnt.
-	Bewertungstufe 2:
Eine Zielgruppe oder ein wiederkehrender Bedarf ist erkennbar.
Die Daten sind bewusst zur Nutzung aufbereitet und unterstützen Analysen oder Entscheidungen.
-	Bewertungstufe 3:
Das Data Product erzeugt aktiv Mehrwert für Nutzer.
Es liefert Ergebnisse, Vorhersagen oder kontinuierliche Erkenntnisse und funktioniert wie ein Service.
2.	Wie gut es technisch und organisatorisch betrieben werden kann
-	Bewertungstufe 1:
Daten werden erzeugt oder verarbeitet, aber ohne geregelten Betrieb.
-	Bewertungstufe 2:
Technische Verarbeitung existiert.
Qualität, Zugriff oder Verantwortlichkeiten sind teilweise geregelt.
-	Bewertungstufe 3:
Das Data Product ist dauerhaft betreibbar.
Verantwortlichkeiten, Qualität, Zugriff und Lifecycle sind klar geregelt oder automatisiert.

2025-Niinikoski-Data-Products-in-Platform-Ecosystems-Theseus-Data-Products.pdf
- Wertorientiert: analysiert literatur, auch in historischer betrachtung auf Werte von Data Products, viel im Data Mesh kontext, extrahiert auch Werte durch befragung von verschiedene Unternehmen

Matrix 1: 
	Achse Konzeptuelle Konkretisierung des Data-Product-Gedankens = 3 
Stufe 1,2,3: Chapter 2 stellt komplette Literaturanalyse sowie extrahiert eigenschaften (wie ownership, qualität, etc.) als merkmale 
Stufe 4: Figure 16 S. 61 “An example of data products structure in case company”
Warum nicht 5: Rollen, Verantwortlichkeiten, Strutkur für daten access plattlform (wertschöpfung) nicht genau beschrieben, sondern nur als to do gekennzeichnet in Figure 17 S. 63 „Suggested actions for the case companie“
	Achse entierungsnähe des vorgeschlagenen Designs = 2
Prozesse allgemein beschrieben, sowie ein plan zur direkten umsetzung wurde ausgearbeitet. Der plan der umsetzung beinhaltet allerdings die das definieren ´von apsekten wie ziele, rolen, reponsiblities, governance models, Die beschreibung könnte operationalisiert werden ja aber es muss noch viel definiert werden s. Figure 17
Matrix 2: S. 65
	Wie stark ist es ein Produkt für Nutzer und Nutzen = 2 Die Quelle definiert Data Products explizit als produktisierte Einheiten zur Erfüllung konkreter analytischer Kundenbedarfe. Es werden Value, Nutzerzahl, strategische Ausrichtung und Portfolio-Management genannt. Damit ist eine klare Zielgruppe und Nutzenorientierung vorhanden.
Es wird jedoch kein real betriebenes Data Product mit nachweislichem kontinuierlichem Mehrwert beschrieben. Daher keine 3.
	Wie gut es technisch und organisatorisch betrieben werden kann = 2 Ownership, Lifecycle, Governance, Self-Serve-Plattform und Portfolio-Manager werden klar beschrieben. Es existieren Kriterien für Einführung und Steuerung (Need, Value, Feasibility, Strategy Fit).
Es fehlt jedoch eine konkrete, technisch implementierte oder operational nachgewiesene Umsetzung eines Data Products im Unternehmen. Daher keine 3.


2025-Nizamis-Data-As-A-Product-Swiss-Smart-Factory-Elsevier-DataProducts.pdf 
-> technische Perspektive (Implementierung)
-> Architektur (Baut Architektur mit Komponenten auf)
-> wertorientiert (anwendung, Eigenschaften messbar gemacht)
-> organisatorisch (wenig, keine ownership modelle etc.)


Matrix 1: 
Achse Konzeptuelle Konkretisierung des Data-Product-Gedankens = 2
-	Stufe 1: erfüllt
S. 794-795: DaaP klar definiert/abgegrenzt („packaged … as products“, „standalone products“).
-	Stufe 2: erfüllt (kurzer Überblick, keine saubere Systematik)
S. 794-795: mehrere Definitionen/Varianten und verwandte Ansätze werden genannt (IBM, DaaS, AI-Model+Dataset etc.).
-	Stufe 3: teilweise erfüllt
S. 794: Merkmalsliste/Prinzipien (discoverable, interoperable, secure, self-describing; FAIR).
-	Stufe 4: erfüllt
S. 795-797: Referenzarchitektur + Building Blocks (Figure 1, Section 2).
-	Warum nicht 5:
Kein ganzheitliches Operating Model (Rollen/Prozesse/Wertschöpfung/Monetization nur angerissen bzw. „under development“). (S. 797)
Achse Implementierungsnähe des vorgeschlagenen Designs = 3
-	Stufe 1: erfüllt
Konkrete Komponenten statt Vision (Section 2). (S. 795-797)
-	Stufe 2: erfüllt
Architektur klar skizziert (Core + Data Space + Marketplace). (S. 795-796)
-	Stufe 3: erfüllt
Konkretes Design inkl. Tech/Mechanismen (NiFi/Spark/REST, Keycloak+ABAC, eIDAS, Hyperledger Fabric, Connector/Marketplace). (S. 796-797)
-	Stufe 4: erfüllt (Pilot-Operationalisierung)
Reales Experiment + End-to-End-Flow + frühe Evaluation (Figure 2/3). (S. 797-799)
-	Warum nicht 5:
Blueprint-/Skalierungsreife fehlt; Scalability/near real-time explizit nicht adressiert (Future Work). (S. 799)

Matrix 2:
Achse Produkt-/Nutzenorientierung = 3
-	Stufe 1:
erfüllt
S. 797: „the need of SSF to monitor and analyze the energy consumption in the production line“
-> klarer Anwendungskontext vorhanden.
-	Stufe 2:
Erfüllt, da ein konkreter betrieblicher Zweck beschrieben wird.
S. 797: „The experiment’s data analysis will allow the optimization of the factory and making better business decisions.“
-> Daten dienen explizit Entscheidungsunterstützung.
-	Stufe 3:
Erfüllt, da konkrete Nutzer und Data Consumer definiert sind.
S. 797: „data can be provided as-a-product to customers for further experimentation“
S. 797: „Uninova institute made use of the presented DaaP implementation to provide data analytics services to SSF“
-> bewusste Bereitstellung für identifizierbare Nutzergruppen.
-	Stufe 4:
Erfüllt, da Nutzen messbar bewertet wird.
S. 798: „DaaP has boosted Data Integration and Security procedures“
S. 799: „significant improvement regarding data pre-processing time“
-> nachweisbare operative Verbesserungen.
-	Warum nicht 5:
Das Data Product fungiert nicht als dauerhaft autonomer Service mit kontinuierlicher Vorhersage oder eigener Wertgenerierung.
Das Szenario bleibt ein „experimental scenario“ (S. 797) zur Validierung des Ansatzes.

Achse Technisch-organisatorische Betriebsfähigkeit = 3
-	Stufe 1:
erfüllt, da kein einmalig erzeugtes Artefakt vorliegt.
-	Stufe 2:
Erfüllt durch vorhandene technische Datenpipeline.
S. 798: „data from SSF were made available through a Sovity Data Space connector“
-	Stufe 3:
Erfüllt durch integrierte Qualitätssicherung und Evaluation.
S. 798: „quality assurance mechanisms“
S. 798: „An early evaluation of this experiment was performed“
-	Stufe 4:
Erfüllt durch Governance-, Security- und Transformationsregeln innerhalb des Data Products.
S. 798: „data transformation, pre-processing, security and governance were covered by DaaP“
-	Stufe 5:
Erfüllt durch plattformbasierten Betrieb mit Discoverability und automatisierter Nutzung.
S. 798: „published on the Marketplace to make them discoverable by potential data consumers“
S. 798: „create and automate optimization tasks“

2025-Pessi-Data-Products-as-Business-Assets-Theseus-Data-Products.pdfS. 41
- Architektur (beschreibt architektur)
- Setzt technische architektur um 
- Wertorientierung (beschreibt nutzen, gründe un dvorteile von data products)
- organisatorisch (beschreibt das ohne entsprechende kommunikation, koordination ein dezentraler ansatz wie ein data mesh auf grundlage von data products in verteilten unerreichbaren silos enden könnte,)
Matrix 1:
Achse 1: 3 - Figure 14 S. 38
Achse 2: 3 Figure 14 Figure 15 S.38 - 40
Matrix 2: Achse 1 = 2, Achse 2 = 2 es wird kein konkretes Data Product mit realen Daten umgesetzt oder Betrieben
Es wird diskutiert in 4.2:
- Was ein Data Product ist (Purpose, Ownership, Metadata).
- Welche Bestandteile es hat (Input/Output Ports, Internal Logic, Product Wrapper).
- Wie es kategorisiert werden kann (source-aligned, consumer-aligned, intermediate).
- Welche Governance-Anforderungen gelten (Owner, Lifecycle, Katalogeintrag).
In 4.3 geht es einen Schritt weiter in Richtung technische Architektur. Dort wird beschrieben:
- Git-Repositories
- Deployment-Automatisierung
- Compute-Orchestrator
- Lakehouse-Plattform
- IaC-Bausteine
- Self-Serve-Umgebungen
	Architekturvorschlag bzw Zielbild
2,2 ist angemessen, weil die Quelle sowohl einen klar definierten Produktzweck mit identifizierter Zielgruppe als auch eine konkret ausgearbeitete technische und organisatorische Architektur beschreibt, jedoch keinen real implementierten oder betriebenen Data-Product-Betrieb nachweist.

1998-Masuoka-et-al-Key-Characteristics-of-MODIS-Data-Products-IEEE-Transactions-on-Geoscience-and-Remote-Sensing-Remote-Sensing.pdf
Matrix 1:
Achse 1 = 0
Das Paper nutzt „data products“ im MODIS/EOSDIS-Processing-Level-Sinn (Level 1/2/3/4), erklärt Formate/Volumen/Geometrie und Bestellhinweise. Es entsteht kein allgemeines Data-Product-Konzept (Nutzer/Nutzen/Ownership/Governance als Modell) und kein Literaturvergleich zum Begriff.
Achse 2 = 1
-	Es strukturiert Daten als klar definierte Produkte (Level 1/2/3/4).
-	Es beschreibt Produktmerkmale (Formate, Volumen, Granules, Tiles, Grids).
-	Es adressiert Nutzbarkeit („welches Level ist am einfachsten zu verwenden?“).
-	Es organisiert Produktion, Archivierung, Distribution (DAACs, PGE, EOSDIS).
-	Es trennt Produktvarianten nach Zielgruppen (Land/Ocean/Atmosphere, Climate Grid etc.).
Das ist ein starkes produktorientiertes Datenverständnis - aber technisch-wissenschaftlich.
Was fehlt im Sinne eines DaaP-Modells:
-	Kein explizites Ownership-Modell (Data Product Owner etc.).
-	Kein Governance-Framework.
-	Kein Lifecycle-Management im Produktmanagement-Sinn.
-	Kein Wertschöpfungsmodell.
-	Keine ökonomische oder organisatorische Einbettung als „Produktstrategie“.
Matrix 2:
Achse 1 = 2 
Klare Zielgruppe (Scientific Community), wiederkehrender Bedarf, Daten sind bewusst nutzbar aufbereitet (earth-located Level 3, Level 2G als nutzerfreundlicher), inklusive Empfehlungen für „easiest to use“. Kein Service/Forecasting im Sinne von Stufe 3.
Achse 2 = 2 
Betrieb ist geplant/strukturiert (DAACs, Archiv/Distribution, definierte Prozesse, Toolkits/Libs, Subsetting-Roadmap, Qualitäts-/Bias-Korrektur bei Geolocation). Aber kein explizites Lifecycle-/Governance-Modell im DaaP-Sinn (Produktverantwortung, SLAs, Deprecation etc.) → daher nicht 3.
2007-Quinn-et-al-The-Virtual-Observatory-Data-Model-Space-Science-Reviews-Data-Products.pdf
Matrix 1:
Aches 1 = 0 
der Begriff „data products“ lediglich als Bezeichnung für Datensätze bzw. Datenlevel verwendet (Level 0-3, Beacon). Es findet weder eine Begriffsdefinition noch eine konzeptionelle Diskussion des Data-Product-Gedankens statt.
Achse 2 = 1 
Der Text beschreibt technische Datenverarbeitung und Datenbereitstellung innerhalb einer wissenschaftlichen Mission (Processing Levels, Datenformate, Portale, Zugriffsmöglichkeiten). Es wird jedoch kein Data-Product-Ansatz als organisatorisches oder konzeptionelles Modell implementiert oder operationalisiert. Aber man erkennt an, dass Daten bewusst als klar definierte Produkte mit Struktur, Inhalt und Nutzungskontext organisiert werden. Auch wenn kein theoretisches Modell entwickelt wird, wird zumindest ein Datenangebot in produktähnlicher Form beschrieben.
Matrix 2:
Achse 1 = 2
Eine klare Nutzungsperspektive ist erkennbar: Level 2 „key parameter“ sind als kalibrierte, verifizierte und „publishable“ Produkte für breite Nutzung, statistische Studien und Validierungen gedacht; Beacon-Daten sind explizit für Near-Realtime Space-Weather/Prediction relevant. Es bleibt jedoch bei Datenbereitstellung und Analyseunterstützung, ohne dass das Angebot als Service aktiv neue Ergebnisse/Vorhersagen als eigenes Produkt erzeugt.
Achse 2 = 2
Technische Verarbeitung und Bereitstellung sind klar organisiert (Processing Levels, Validierung durch Instrumentteams, Datenportale und APIs). Verantwortlichkeiten und Zugriffswege sind erkennbar, jedoch wird kein vollständiges Betriebsmodell eines dauerhaft gemanagten Data Products beschrieben.
2018-Meierhofer-et-al-Data-Products-Service-Design-Framework-Springer-Data-Products.pdf
Matrix 1:
Achse 1 = 2
Der Text entwickelt eine konzeptionelle Definition des Begriffs „data product“ und ordnet ihn in einen Service-Design-Kontext ein. Data Products werden als Anwendung von Data-Science-Kompetenzen beschrieben, die Nutzen für Nutzer erzeugen und dafür einen Wert zurückerhalten. Darüber hinaus werden zentrale Bausteine wie Nutzerperspektive, Nutzenorientierung sowie der Zusammenhang von Analytics und Service Design systematisch erläutert. Ein organisatorisches Betriebsmodell mit Rollen, Governance oder Wertschöpfungslogik wird jedoch nicht zusammenhängend ausgearbeitet.
Achse 2 = 2
Die Quelle beschreibt einen methodischen Ansatz zur Entwicklung von Data Products, der Service-Design-Phasen mit Data-Analytics-Methoden kombiniert. Dazu gehören beispielsweise ein Framework zur Verbindung von Nutzeranalyse und analytischen Methoden sowie Prozessschritte wie Zieldefinition, Datensammlung, Modellierung und iterative Verbesserung. Diese Darstellung zeigt grundsätzlich, wie ein Data-Product-Ansatz umgesetzt werden kann. Die Beschreibung bleibt jedoch auf einer abstrakten methodischen Ebene und liefert keine konkrete Architektur oder organisatorische Struktur, die eine direkte Implementierung ermöglichen würde.
Matrix 2:
Achse 1 = 1
Der Text beschreibt kein konkretes Datenangebot, das als nutzbares Produkt bereitgestellt wird. Stattdessen wird konzeptionell diskutiert, wie Data Products gestaltet werden können und wie Datenanalysen in nutzerorientierte Services integriert werden sollen. Zwar wird die Bedeutung von Nutzerbedürfnissen und Nutzen mehrfach hervorgehoben, jedoch werden keine Daten explizit als aufbereitete Analyse- oder Entscheidungsressource bereitgestellt. Damit bleibt der Ausschnitt auf der Ebene allgemeiner Daten- und Analyseverwendung.
Achse 2 = 1
Technische Datenverarbeitung wird im Text grundsätzlich erwähnt, etwa durch Beispiele wie Data Mining, Natural Language Processing oder analytische Modellierungsschritte. Diese werden jedoch ausschließlich als mögliche Komponenten eines Data-Product-Designs beschrieben und nicht als Teil eines konkreten operativen Systems. Es fehlen Angaben zu organisatorischen Verantwortlichkeiten, Qualitätssicherung, Zugriffskontrolle oder Lifecycle-Management. Somit wird lediglich die Existenz technischer Verarbeitung thematisiert, ohne dass ein geregelter technischer oder organisatorischer Betrieb eines Data Products erkennbar ist.
2019-Dehghani-How-to-Move-Beyond-a-Monolithic-Data-Lake-to-a-Distributed-Data-Mesh-Martin-Fowler-Data-Mesh.pdf
Matrix 1:
Achse 1 = 3
Die Quelle beschreibt Data Products nicht nur begrifflich, sondern entwickelt ein umfassendes konzeptionelles Modell. Es werden systematisch zentrale Bausteine wie Discoverability, Addressability, Trustworthiness, Semantics, Interoperability und Security dargestellt sowie Rollen wie Data Product Owner und Data Engineers definiert. Zusätzlich wird der organisatorische Rahmen eines Data-Mesh-Ansatzes mit Governance, Domain-Ownership und Plattformstruktur erläutert.
Achse 2 = 3
Die Quelle beschreibt die Umsetzung eines Data-Product-Ansatzes sehr konkret. Es werden technische und organisatorische Mechanismen genannt, etwa Data Catalogs, SLOs für Datenqualität, globale Standards für Interoperabilität, Zugriffskontrolle über RBAC sowie eine Self-Service-Data-Infrastructure-Plattform mit konkreten Funktionen wie Data Product Versioning, Monitoring oder Pipeline Orchestration. Die Kombination aus Rollen, Plattformkomponenten und Prozessen macht eine direkte Implementierung grundsätzlich nachvollziehbar.

Matrix 2:
Achse 1 = 1
Der Text beschreibt zumindest einen möglichen Zweck von Datenangeboten und nennt konkrete potenzielle Nutzergruppen wie Data Scientists, ML Engineers und Data Engineers. Zudem wird anhand des Beispiels der „play events“-Domain gezeigt, dass Daten für unterschiedliche Analysebedarfe bereitgestellt werden könnten (z. B. Echtzeit-Events oder aggregierte historische Daten). Diese Beschreibung bleibt jedoch rein illustrativ und zeigt kein tatsächlich bereitgestelltes Datenprodukt.
Achse 2 = 0
Der Text beschreibt keinen tatsächlichen Betrieb eines konkreten Data Products. Rollen, Infrastrukturkomponenten und Governance-Mechanismen werden ausschließlich auf konzeptioneller Ebene diskutiert und nicht an einem real implementierten Datenangebot gezeigt. Eine operative Umsetzung oder ein konkret betriebenes Datenprodukt ist im Ausschnitt daher nicht erkennbar.
1991-Wang-Manage Your Information as a Product.pdf
Matrix 1
1.	Konzeptuelle Konkretisierung des Data-Product-Gedankens
Stufe 1
Der Text führt die Idee ein, Information als „product“ zu betrachten und formuliert mit dem „information product approach“ vier grundlegende Prinzipien (Nutzerbedürfnisse verstehen, Produktionsprozess managen, Lifecycle managen, Information Product Manager einsetzen). Nutzer, Qualität und organisatorische Verantwortung werden erwähnt, jedoch nur auf allgemeiner Managementebene. Eine systematische Beschreibung struktureller Bausteine eines Data Products - etwa Produktstruktur, Schnittstellen, Datenkomponenten oder Architektur - erfolgt nicht.
Für Stufe 2 müsste die Quelle zentrale Bausteine eines Data Products systematisch darstellen, etwa wie ein Data Product aus Elementen wie Datensatz, Metadaten, Schnittstellen, Ownership oder Architektur aufgebaut ist. Der Text beschreibt jedoch nur Managementprinzipien für Informationsqualität und Organisationsverantwortung. Es fehlt eine strukturelle Modellierung dessen, was ein Data Product konkret ist oder aus welchen Komponenten es besteht. Daher bleibt der konzeptionelle Beitrag auf der Ebene einer grundlegenden Perspektive („Information als Produkt“) und erreicht nicht die systematische Bausteinbeschreibung von Stufe 2.
2.	Konkretisierung der Umsetzung eines Data-Product-Ansatzes
Stufe 1
Die Quelle beschreibt organisatorische Prinzipien wie Lifecycle-Management, Qualitätsdimensionen, Prozesskontrollen und die Rolle eines Information Product Managers. Diese Elemente zeigen, dass Information bewusst gemanagt werden soll. Die Darstellung bleibt jedoch normativ und konzeptionell; konkrete Umsetzungsstrukturen eines Data-Product-Ansatzes werden nicht ausgearbeitet.
Für Stufe 2 müsste erkennbar sein, wie ein Data-Product-Ansatz organisatorisch oder technisch umgesetzt werden könnte, etwa durch erkennbare Architektur, Plattformkomponenten, Datenpipelines oder klar strukturierte Produktorganisation. Der Text beschreibt jedoch lediglich Managementprinzipien für Informationsqualität und organisatorische Verantwortung. Es wird weder eine technische Architektur noch eine konkrete Organisationsstruktur für den Betrieb von Data Products dargestellt. Deshalb bleibt die Operationalisierung auf einer allgemeinen Empfehlungsebene und erreicht nicht die Umsetzungsnähe von Stufe 2.
Matrix 2:
1.	Wie stark ist es ein Produkt für Nutzer und Nutzen
Bewertungstufe 0
Der Text diskutiert Informationen grundsätzlich als organisationales Gut und betont deren Bedeutung für Entscheidungen und Prozesse. Die beschriebenen Beispiele (z. B. Kontoinformationen, Produktionsspezifikationen oder Sicherheitsdatenblätter) dienen lediglich zur Illustration von Informationsqualitätsproblemen. Ein konkret ausgestaltetes Datenprodukt mit klar definierter Nutzung oder Produktstruktur wird im Ausschnitt nicht beschrieben.
2.	Wie gut es technisch und organisatorisch betrieben werden kann
Bewertungstufe 0
Der Artikel beschreibt kein operatives Datenangebot und keinen realen Betrieb eines Datenprodukts. Es werden lediglich generelle Managementprinzipien für Informationsqualität diskutiert. Technische Infrastruktur, konkrete Betriebsprozesse oder ein implementiertes Produktmodell sind im Text nicht erkennbar.
2003-Cai-Evaluating Completeness of an Information Product.pdf
Matrix 1:
1.	Konzeptuelle Konkretisierung des Data-Product-Gedankens
•	Stufe 1
Die Quelle entwickelt ein Konzept rund um „Information Products“ (IP) und argumentiert „Information as Product“, aber sie definiert nicht „Data Products“ als organisationales Produktkonzept mit typischen Bausteinen wie Ownership/Governance/Value-Logik. „Ownership“ im Sinne eines Data Product Owners oder klarer Verantwortungsmodelle wird im Ausschnitt nicht als Bestandteil eines Data Products definiert; der Nutzen wird eher über „Decision-Maker brauchen Quality-Assessment“ motiviert, nicht als Value Proposition eines Data Products systematisch ausgearbeitet.
2.	Konkretisierung der Umsetzung eines Data-Product-Ansatzes
•	Stufe 1
Es gibt Formeln und ein Bewertungsverfahren zur Messung von Completeness auf IP-Ebene (Dj, Ei, C, wi) und ein Modell (IPMAP) zur Abbildung der Herstellung eines IP. Aber es wird keine Umsetzung eines Data-Product-Ansatzes beschrieben (keine Plattform-/Produktarchitektur, keine Rollen-/Prozesslandschaft für Data Products, kein Lifecycle-Betrieb), sondern „nur“ ein theoretisch anwendbares Messframework.
Matrix 2:
1.	Wie stark ist es ein Produkt für Nutzer und Nutzen
•	Stufe 0
Im Ausschnitt wird kein konkretes Data Product gebaut oder als nutzungsfertiges Artefakt beschrieben; es geht um ein Bewertungsmodell für Vollständigkeit von Information Products. Das Beispiel (Widget Inc.) zeigt lediglich, wie man die Kennzahl rechnerisch auf einen Report/Forecast anwenden könnte - das ist eher „Messung für Entscheidungen“ als ein operationalisiertes Nutzerprodukt.
2.	Wie gut es technisch und organisatorisch betrieben werden kann
•	Stufe 1
Es gibt keinen geregelten Betrieb eines konkreten Datenangebots: keine Ownership-Struktur, keine Zugriffs-/Bereitstellungsprozesse, keine Qualitäts-SLOs/Monitoring, kein Lifecycle. Im Gegenteil: die Quelle weist sogar darauf hin, dass subjektive Gewichte missbraucht werden könnten und dass dafür erst ein Incentive-System „müsste“ geschaffen werden - das unterstreicht, dass der Betrieb nicht konkret operationalisiert ist.
2016-Davenport-Designing and Developing Analytics-Based Data Products.pdf
Matrix 1:
1.	Konzeptuelle Konkretisierung des Data-Product-Gedankens
•	Stufe 1
Der Ausschnitt nutzt „data products“ als Begriff und grenzt sie grob als Kombination aus Daten + Analytics ein, plus Markt-/Bedarfslogik („marketplace need“). Aber zentrale Data-Product-Bausteine, die du erwartest (Ownership/Data Owner, verbindliches Nutzenversprechen als Produktverantwortung, Lifecycle/Governance als Produktlogik), werden im Ausschnitt nicht systematisch ausgearbeitet.
2.	Konkretisierung der Umsetzung eines Data-Product-Ansatzes
•	Stufe 2 (schwach)
Es wird ein konkretes Vorgehensmodell skizziert (7 Schritte von Conceptualize bis Market Feedback) und mit iterativem MVP/Lean-Startup-Denken sowie Feedbackmechaniken (Usage-Metriken, A/B-Tests) verknüpft. Das bleibt generisch und ist kein direkt implementierbares Operating Model, aber es beschreibt plausibel, wie man einen Data-Product-Ansatz organisatorisch/prozessual angehen könnte.
Matrix 2:
1.	Wie stark ist es ein Produkt für Nutzer und Nutzen
•	Bewertungstufe 1
Es werden Daten/Informationen mit Analytics als wertstiftend beschrieben und Beispiele genannt, aber kein einzelnes Data Product als konkret ausgestaltetes Produkt mit definiertem Output/Service und klarer Zielgruppe „durchdekliniert“. Damit bleibt es eher Nutzenargumentation auf Meta-Ebene als ein operationalisiertes Produkt.
2.	Wie gut es technisch und organisatorisch betrieben werden kann
•	Bewertungstufe 0
Im Ausschnitt ist kein konkretes Datenangebot beschrieben, für das Verantwortlichkeiten, Zugriff, Qualität oder Lifecycle als Betriebssystematik festgelegt wären. Es gibt nur allgemeine Hinweise (z.B. Cloud/Distribution/Feedback), aber keinen geregelten Betrieb eines spezifischen Data Products, daher „nicht vorhanden“ im Sinne deiner Achse.
2004-Davidson-Developing Data Production Maps.pdf
Matrix 1 - Achse 1 (Konzeptuelle Konkretisierung des Data-Product-Gedankens): 1
Die Quelle bezeichnet den halbjährlichen Patient-Discharge-Datensatz zwar als „Information Product“ und nennt Qualitätsanforderungen sowie organisatorische Zuständigkeiten. Eine konzeptionelle Ausarbeitung eines modernen Data-Product-Ansatzes (z. B. systematische Produktbausteine wie Nutzenlogik, Schnittstellen/Architektur, Produktmanagement/Lifecycle) erfolgt jedoch nicht; der Fokus bleibt auf Datenqualitäts- und Compliance-Logik.
Matrix 1 - Achse 2 (Konkretisierung der Umsetzung eines Data-Product-Ansatzes): 0
Die Quelle beschreibt operative DQ-Umsetzungsschritte (DPG → DQMWG, Production Maps, Vorab-Audits, Testläufe) zur Sicherstellung einer korrekten Submission. Diese Mechanismen operationalisieren jedoch primär einen Datenqualitäts-/Submission-Prozess und nicht die Umsetzung eines modernen Data-Product-Ansatzes (keine definierte Bereitstellung/Consumability, keine Contracts/Schnittstellen, keine Plattform- oder Produktbetriebslogik).
Matrix 2 - Achse 1 (Wie stark ist es ein Produkt für Nutzer und Nutzen): 1
Es werden Daten/Informationen als Submission-Dataset bereitgestellt; der Zweck ist primär die Erfüllung externer Vorgaben, mit höchstens implizitem Nutzen über Compliance (Vermeidung von Rework/Strafen). Eine nutzungsorientierte Ausgestaltung als konsumierbares Produkt (z. B. klare Bereitstellungsform, Nutzungsszenarien über die Abgabe hinaus) wird nicht beschrieben.
Matrix 2 - Achse 2 (Wie gut es technisch und organisatorisch betrieben werden kann): 2
Der Ablauf ist wiederholbar organisiert (Halbjahreszyklus) und es existieren klare Verantwortungs- und Qualitätsmechanismen (DPG/DQMWG, Owner-Departments, Production Maps, Audits/Testläufe). Für eine 3 fehlen jedoch produktrelevante Betriebsdetails wie definierte Zugriffs-/Bereitstellungsmechanismen, explizite Schnittstellen/Contracts sowie ein umfassender Lifecycle-/Automatisierungsrahmen über den reinen Submission-Prozess hinaus.

#dhbwCite("shankaranarayanan_ip-map_2000")
Matrix 1 - Achse 1 (Konzeptuelle Konkretisierung des Data-Product-Gedankens): 1
Die Quelle arbeitet ein „Information Product“-Konzept aus, aber funktional als Herstellprozess- und Qualitätslogik (IP-MAP) statt als modernes Data Product mit klarer Bereitstell-/Nutzungsschnittstelle, Produktlogik und Betriebsmodell. Moderne Produktmerkmale (Contracts/Interfaces, Publishing/Distribution, Lifecycle als Produkt) werden im Ausschnitt nicht konzeptionell als Data-Product-Ansatz entwickelt.
Matrix 1 - Achse 2 (Konkretisierung der Umsetzung eines Data-Product-Ansatzes): 1
Es werden zwar konkrete Mechaniken (Blocktypen, Metadaten, Quality Gates, Boundaries, Traceability) beschrieben, diese operationalisieren aber die Modellierung und Kontrolle der Datenherstellung, nicht die Umsetzung eines Data-Product-Ansatzes im heutigen Sinn. Architektur/Rollen/Prozesse erscheinen daher nicht als Data-Product-Implementierung (Serving, Zugriff, Contracts, Betrieb), sondern als DQ-/Manufacturing-Engineering.
Matrix 2 - Achse 1 (Wie stark ist es ein Produkt für Nutzer und Nutzen): 1
Die Outputs (Reports/Bills/externes Reporting) werden an benannte Empfänger geliefert, aber der Ausschnitt rahmt sie als Informationsartefakte aus internen Systemen, nicht als wiederverwendbares, konsumierbares Datenangebot mit explizitem Mehrwertversprechen. Ein klarer Produktnutzen über „Information bereitstellen“ hinaus wird nicht ausgearbeitet.
Matrix 2 - Achse 2 (Wie gut es technisch und organisatorisch betrieben werden kann): 1
Es gibt Prozessverantwortlichkeiten und Qualitätsprüfungen im Herstellfluss, aber kein geregelter Betrieb eines Datenangebots als Service (z. B. Zugriffskontrolle als Produktzugang, Monitoring/Feedback auf Produktebene, Lifecycle/Change/Versionierung). Damit ist „dauerhaft betreibbar“ im Data-Product-Sinn im Ausschnitt nicht erkennbar.
1996-Wang- 14-Beyond-Accuracy.pdf
Matrix 1, Achse 1: Stufe 0
Die Quelle ist eine empirische Studie zur Taxonomie von Datenqualitätsattributen. Der Data-Product-Begriff wird nicht verwendet, kein Konzept beschrieben - die Produktanalogie ist eine methodologische Fußnote ohne inhaltliche Ausarbeitung.
Matrix 1, Achse 2: Stufe 0
Es gibt keinen Ansatz, der auch nur entfernt als Umsetzung eines Data-Product-Konzepts gelesen werden könnte. Die Quelle endet mit einem Bewertungsframework für Qualitätsattribute.
Matrix 2, Achse 1: Stufe 0
Es wird kein Datenangebot für eine Nutzergruppe beschrieben. Die befragten „Data Consumer" sind Forschungssubjekte zur Ableitung von Qualitätsdimensionen, kein adressierter Nutzerkreis eines Produkts.
Matrix 2, Achse 2: Stufe 0
Es existiert kein betreibbares Datenangebot. Die Quelle ist reine Grundlagenforschung zur Datenqualitätswahrnehmung ohne jeden Produkt- oder Betriebsbezug.

Diese quelle handelt sich um Datenqualität.  Wang & Strong verwenden den Begriff „data product" explizit, wenn auch nur als methodologische Analogie: „an information system can be viewed as a data manufacturing system acting on raw data input to produce output data or data products." Der Begriff taucht im Text auf, wird aber nicht inhaltlich ausgearbeitet. Die quelle soll als Beleg dafür dienen, dass Qualitätsanforderungen historisch vor dem Produktgedanken existierten und erst später in Data-Product-Frameworks integriert wurden. 

#dhbwCite("hasan_understanding")
Matrix 1, Achse 1: Stufe 3
Die Quelle entwickelt eine überarbeitete, theoretisch fundierte Definition von Data Products, erarbeitet deren Charakteristika und Kategorien systematisch und bettet den Begriff explizit in die Produktmanagement-Literatur ein - als vierter Produkttyp neben physischen, Software- und digitalen Produkten. Der socio-technical lens wird als zentrales konzeptionelles Argument eingeführt: Data Products sind nicht rein technische Objekte, sondern von Organisationsstruktur, Strategie und Wirtschaftlichkeit geprägte Artefakte. Die konzeptionelle Ausarbeitung ist damit vollständig und eigenständig.
Matrix 1, Achse 2: Stufe 3
Der Data Product Canvas (Essays 3 & 4) ist ein konkretes, methodisch ausgearbeitetes Gestaltungswerkzeug entlang der Dimensionen Desirability, Feasibility und Viability. Er wurde mittels Design-Science-Methodik entwickelt und in einem Fortune-500-Unternehmen in realen Designprozessen angewendet. Damit liegt auf der konzeptuell-methodischen Ebene eine echte Implementierungskonkretisierung vor - nicht als technische Spezifikation, sondern als erprobtes Designartefakt.
Matrix 2, Achse 1: Stufe 3
Die Nutzerperspektive ist strukturbildend für die gesamte Dissertation. Die Fragen „why-to-build", „what-to-build" und „for/by whom" werden als zentrale Antecedents des Produktbaus positioniert. Consumer-Provider-Interaktion wird als eigenständiges Forschungsfeld behandelt (Essay 6). Rollen wie Data Product Owner und Data Product Manager sowie Mechanismen wie Data Catalog & Marketplace werden als wertschöpfende Strukturen für definierte Nutzergruppen konzeptualisiert.
Matrix 2, Achse 2: Stufe 2
Die Quelle beschreibt organisatorische Betriebsmechanismen - Data Contract, Data Product Lifecycle, Ownership, Governance-Einbettung und Work System Theory - zusammenhängend und kohärent. Rollen, Prozesse und Governance werden als aufeinander bezogenes Set dargestellt, das als Orientierungsrahmen für eine organisatorische Umsetzung dienen kann. Eine direkte technische Implementierung auf Basis dieser Quelle allein ist jedoch nicht möglich, da Schnittstellenspezifikationen, Architekturvorgaben und konkrete Qualitätsmechanismen fehlen.

#dhbwCite("blohm_data_2024")
Matrix 1 - Konzeptuelle Konkretisierung des Data-Product-Gedankens: 3
Die Quelle beschreibt Data Products nicht nur definitorisch, sondern bettet sie in ein organisatorisches Gesamtbild aus Rollen, Wertlogik und Governance ein. Data Products werden als wertorientierte Artefakte für definierte Nutzergruppen dargestellt und im Zusammenhang mit organisatorischen Verantwortlichkeiten wie Domain Ownership und Data-Product-Management diskutiert. Dadurch entsteht eine zusammenhängende Darstellung, wie Data Products organisatorisch gedacht und betrieben werden sollen.
Matrix 1 - Konkretisierung der Umsetzung eines Data-Product-Ansatzes: 2
Die Quelle beschreibt mehrere Elemente, wie ein Data-Product-Ansatz umgesetzt werden könnte, etwa Domain-orientierte Ownership, Self-Service-Data-Plattformen, föderierte Governance sowie Metadaten- und Katalogmechanismen. Architektur, Rollen und Plattformkomponenten sind damit klar erkennbar. Die Darstellung bleibt jedoch auf einem allgemeinen konzeptionellen Niveau ohne konkrete Implementierungsstrukturen.
Matrix 2 - Produktorientierung für Nutzer und Nutzen: 2
Data Products werden als Artefakte definiert, die wiederkehrende Informationsbedürfnisse bestimmter Nutzergruppen adressieren und Daten in konsumierbarer Form bereitstellen. Der Fokus liegt auf Nutzung, Wiederverwendbarkeit und Unterstützung von Analysen oder Anwendungen. Ein konkretes Data Product mit aktiv erzeugten Ergebnissen oder kontinuierlichen Services wird jedoch nicht beschrieben.
Matrix 2 - Technischer und organisatorischer Betrieb: 0
Die Quelle beschreibt kein konkretes Data Product mit geregeltem Betrieb. Aspekte wie Lifecycle, Monitoring, konkrete Qualitätsmetriken oder Schnittstellen eines spezifischen Produkts werden nicht ausgearbeitet. Stattdessen werden nur allgemeine Architektur- und Governanceprinzipien diskutiert.

#dhbwCite("hasan_improving_2024")
Matrix 1 - Achse 1: 3
Die Quelle entwickelt ein zusammenhängendes Verständnis von Data Products als organisatorisch betriebenen Artefakten zur Bereitstellung wiederverwendbarer Datenangebote. Dabei werden zentrale Elemente eines Data-Product-Betriebs systematisch dargestellt, darunter Rollen (Data Product Owner, Data Product Manager), Governance-Mechanismen sowie ein Data-Product-Lifecycle. Dadurch geht die Darstellung über eine reine Begriffsdefinition hinaus und beschreibt, wie Data Products organisatorisch betrieben werden sollen.
Matrix 1 - Achse 2: 2
Die Quelle beschreibt mehrere Mechanismen, mit denen ein Data-Product-Ansatz umgesetzt werden kann, etwa Data Contracts, Data Catalogs beziehungsweise Marketplaces, Rollenstrukturen sowie Lifecycle-Prozesse. Diese Elemente zeigen, wie Organisationen Data Products strukturell organisieren und bereitstellen könnten. Die Darstellung bleibt jedoch auf einem allgemeinen Organisations- und Governance-Level und enthält keine konkrete Architektur oder Implementierungsbeschreibung eines spezifischen Data Products.
Matrix 2 - Achse 1: 2
Data Products werden als Datenangebote beschrieben, die wiederkehrende Informationsbedürfnisse von Nutzern adressieren und Daten in eine konsumierbare Form überführen. Ein Beispiel ist ein „Sales 360° data product“, das verschiedene Datensätze kombiniert, um unterschiedliche analytische Anwendungsfälle zu unterstützen. Damit ist eine klare Zielgruppe und ein wiederkehrender Nutzungskontext erkennbar, auch wenn der Fokus primär auf der Bereitstellung analysierbarer Daten liegt und nicht auf einem eigenständigen Service mit kontinuierlichen Ergebnissen oder Vorhersagen.
Matrix 2 - Achse 2: 1
Die Quelle beschreibt keine konkrete Implementierung eines spezifischen Data Products. Stattdessen werden organisatorische Mechanismen und Fallbeispiele aus Unternehmen dargestellt, etwa Rollen, Plattformen oder Lifecycle-Phasen. Diese zeigen, wie ein Data-Product-Ansatz strukturiert werden kann, liefern jedoch keine operative Umsetzung eines einzelnen Data Products mit konkreten Datenpipelines, Architektur oder Betriebsprozessen. Es existiert keine operative tatsächliche Umsetzung aber das Betriebsmodell wird skizziert.

#dhbwCite("ballou_modeling_1998")
Matrix 1 - Achse 1 (Konzeptuelle Konkretisierung des Data-Product-Gedankens): 1
Die Quelle nutzt zwar den Begriff „Information Product“ und rahmt Informationsentstehung als Manufacturing-Prozess, aber sie arbeitet den Data-Product-Gedanken im heutigen Sinn nicht aus (kein expliziter Purpose/Use-Case als Produktlogik, keine Ownership/Produktverantwortung, keine Schnittstellen-/Contract-Perspektive). Damit bleibt es konzeptionell primär Information-Manufacturing/Data-Quality und nicht ein Data-Product-Modell.
Matrix 1 - Achse 2 (Konkretisierung der Umsetzung eines Data-Product-Ansatzes): 1
Die Quelle konkretisiert eine Methode zur Modellierung und Analyse der Informationsherstellung (Bausteine, Metriken, Rechenbeispiel), aber nicht die Umsetzung eines Data-Product-Ansatzes als betreibbares Produkt. Es fehlen erkennbare Umsetzungsmechanismen für Bereitstellung/Plattform, Zugriff/Discovery, Rollen/Operating Model oder Lifecycle/Change, die eine Implementierung als Data Product nahelegen würden.
Matrix 2 - Achse 1 (Wie stark ist es ein Produkt für Nutzer und Nutzen): 1
Ein „Customer“-Bezug und eine Value-/Trade-off-Diskussion sind vorhanden, aber es wird kein klar abgegrenztes, konsumierbares Datenangebot für eine definierte Zielgruppe mit wiederkehrendem Bedarf beschrieben. Der Nutzen bleibt indirekt über Prozessoptimierung (Quality/Timeliness/Cost) statt über ein konkretes nutzungsorientiertes Data Product.
Matrix 2 - Achse 2 (Wie gut es technisch und organisatorisch betrieben werden kann): 0
Als modernes Data Product ist keine betreibbare Einheit beschrieben: kein definiertes Interface/Contract, keine Zugriffskontrolle/IAM, kein Monitoring/Feedback im Betrieb, kein Lifecycle/Change und keine explizite Produktverantwortung. Das Paper liefert ein Framework zur Analyse/Optimierung der Informationsproduktion, nicht eine operativ betreibbare Produktbereitstellung

#dhbwCite("wang_framework_1995")
Matrix 1 - Konzeptuelle Konkretisierung des Data-Product-Gedankens: 1
Die Quelle verwendet den Begriff „data product“ und beschreibt Informationssysteme als „data manufacturing systems“, bei denen Rohdaten verarbeitet werden und als Output Datenprodukte entstehen.
Der Begriff dient jedoch hauptsächlich zur Erklärung von Datenqualität und Produktionsprozessen; ein eigenständiges konzeptionelles Modell für Data Products mit Rollen, Governance oder Betriebslogik wird nicht ausgearbeitet.
Matrix 1 - Konkretisierung der Umsetzung eines Data-Product-Ansatzes: 0
Das Paper entwickelt ein Framework zur Analyse von Data-Quality-Forschung mit Bereichen wie Management Responsibilities, Production und Distribution.
Diese Struktur dient der Einordnung von Forschung zu Datenqualität, enthält jedoch keine organisatorischen oder technischen Mechanismen zur Umsetzung eines Data-Product-Ansatzes.
Matrix 2 - Wie stark ist es ein Produkt für Nutzer und Nutzen: 0
„Data products“ werden lediglich als generischer Output eines Informationssystems beschrieben, etwa erzeugte oder korrigierte Datensätze.
Ein konkretes Datenangebot für eine definierte Nutzergruppe oder einen klaren Use Case wird im Text nicht ausgearbeitet.
Matrix 2 - Wie gut es technisch und organisatorisch betrieben werden kann: 0
Der Text behandelt Qualitätsmanagement, Fehlerkosten und Datenproduktionsprozesse, jedoch nicht den Betrieb eines konkreten Datenprodukts.
Elemente wie definierte Bereitstellung, Zugriff, Ownership, Monitoring oder Lifecycle eines nutzbaren Datenangebots sind im Ausschnitt nicht erkennbar.

#dhbwCite("madnick_overview_2009")
Matrix 1 – Konzeptionelle Reife des Data-Product-Gedankens
1. Konzeptuelle Konkretisierung: Stufe 2 Die Quelle verwendet den Begriff „information product" explizit und beschreibt zentrale Bausteine systematisch: Der TDQM-Zyklus (Define, Measure, Analyze, Improve) strukturiert Qualität als Produkteigenschaft, und die Dimensionen von Wang & Strong (1996) liefern ein Rahmenwerk für Qualitätsanforderungen aus Nutzersicht. Elemente wie Nutzerrollen (Collector, Custodian, Consumer), Qualitätsmessung und konzeptuelle Modellierung (Quality ER, IPMap) werden als zusammenhängende Bausteine dargestellt. Ein vollständiges Betriebsmodell mit Governance, Lifecycle und Wertschöpfungslogik wird jedoch nicht geschlossen ausgearbeitet, weshalb Stufe 3 nicht erreicht wird.
2. Konkretisierung der Umsetzung: Stufe 1 Das Paper ist ein Überblicksartikel, der existierende Forschung kategorisiert und ein Klassifikationsframework vorschlägt. Konkrete Umsetzungsmechanismen wie Architekturen, Prozesse oder Plattformkomponenten werden zwar als Forschungsthemen benannt (COIN, IPMap, ETL-Frameworks), aber nur referenziert und nicht selbst ausgearbeitet. Es entsteht kein erkennbarer Umsetzungspfad für einen Data-Product-Ansatz — der Beitrag bleibt auf der konzeptionellen Ebene der Forschungslandkarte.

Matrix 2 – Produkt- und Betriebsreife des beschriebenen Datenangebots
1. Produkt für Nutzer und Nutzen: Stufe 1 Die Quelle postuliert zwar grundsätzlich, dass Daten als Produkt aus Konsumentensicht betrachtet werden sollten („fitness for use"), und benennt Rollen. Allerdings wird kein konkretes Datenangebot an einem Use Case beschrieben, bei dem eine Zielgruppe, ein wiederkehrender Bedarf oder eine bewusste Aufbereitung zur Nutzung operativ erkennbar wären. Die Aussagen bleiben auf der Ebene allgemeiner Forschungspostulate, nicht auf der Ebene eines tatsächlich ausgestalteten Produkts.
2. Technischer und organisatorischer Betrieb: Stufe 0 Es wird kein konkretes Datenangebot beschrieben, das in irgendeiner Form betrieben wird. Themen wie Monitoring, Cleansing, Lineage, Privacy und Security werden als Forschungsfelder kartiert, aber es gibt keinen Fall, in dem auch nur eine rudimentäre Betriebsstruktur für ein spezifisches Data Product dargestellt wird. Das Paper bewegt sich vollständig auf der Metaebene der Forschungsklassifikation.

#dhbwCite("huang_data_2015")
Matrix 1 – Konzeptionelle Reife des Data-Product-Gedankens
1. Konzeptuelle Konkretisierung: Stufe 2 Die Quelle definiert den Begriff Data-as-a-Product explizit und beschreibt strukturelle Bausteine systematisch. Das Modell unterscheidet drei Ebenen: Refine Modules zur Transformation von Rohdaten, die daraus entstehenden Data Products sowie ein DaaP Interface zur Bereitstellung an Anwendungen. Elemente wie Nutzerbezug, Qualitätsmessung, Schnittstellen und eine klare Abgrenzung zu Data-as-a-Service werden dargestellt. Eine Ausarbeitung organisatorischer Aspekte wie Ownership, Rollen, Governance oder Lifecycle fehlt jedoch, weshalb Stufe 3 nicht erreicht wird.
2. Konkretisierung der Umsetzung: Stufe 2 Das Paper bleibt nicht rein konzeptionell, sondern zeigt an drei Use Cases, wie Refine Modules Rohdaten in Data Products transformieren und wie anwendungsorientierte Mining-Module darauf arbeiten. Die Verarbeitungsketten werden für medizinische Sensordaten, Textdaten und GPS-Trajektorien jeweils konkret beschrieben. Architektur und Prozessschritte sind erkennbar und nachvollziehbar. Allerdings bleibt die Interface-Spezifikation vage, da zwar Standards gefordert, aber keine konkreten Definitionen oder Contracts geliefert werden. Eine direkte Implementierung des Gesamtmodells erscheint daraus noch nicht vollständig ableitbar.
Matrix 2 – Produkt- und Betriebsreife des beschriebenen Datenangebots
1. Produkt für Nutzer und Nutzen: Stufe 2 Die Data Products adressieren erkennbare Zielgruppen mit wiederkehrendem Bedarf. Ärzte nutzen Period Deviation Distributions zur Krankheitsdiagnose, Analysten nutzen Topic-Hotness-Kurven zur Ereigniserkennung, und Routenmuster werden aus GPS-Daten für Nutzerabfragen bereitgestellt. Die Daten sind bewusst zur Nutzung aufbereitet und auf etwa ein bis zwei Prozent der Originalgröße reduziert. Sie unterstützen konkrete Analysen und Entscheidungen. Allerdings funktionieren die Data Products nicht als eigenständiger Service mit kontinuierlicher Bereitstellung, sondern als Ergebnisse experimenteller Batch-Verarbeitungen.
2. Technischer und organisatorischer Betrieb: Stufe 1 Daten werden erzeugt und verarbeitet, aber ein geregelter Betrieb ist nicht erkennbar. Die drei Use Cases sind experimentelle Demonstrationen mit evaluierten Precision-Werten, nicht dauerhaft betriebene Systeme. Zugriffskontrolle, Monitoring, Verantwortlichkeiten, Lifecycle-Management oder Feedback-Mechanismen werden nicht beschrieben. Die Quelle postuliert zwar, dass Standards für Datenqualität und Interfaces nötig seien, liefert diese aber nicht. Der Betriebsaspekt bleibt eine Zukunftsvision für Cloud-Datacenter.


== Merkmale Data Products

aus #dhbwCite("niinikoski_defining", page:"10-11") Table 1 "Characteristics of data products based on the literature"

#show figure: set block(breakable: true)

// aus #dhbwCite("niinikoski_defining", page: "10–11") Table 1 "Characteristics of data products based on the literature"
#figure(
  table(
    columns: (auto, auto),
    align: (left, left),
    stroke: 0.5pt,
    inset: 8pt,

    table.header(
      [*Characteristics*],
      [*References*],
    ),

    [Valuable],
    [Dehghani 2022, Chapter 3; Balnojan et al. 2023, Chapter 5; Hasan & Legner 2023; Goedegebuure et al. 2024; Mucci & Stryker 2024],

    [Findable],
    [Dehghani 2022, Chapter 3; Balnojan et al. 2023, Chapter 5; Goedegebuure et al. 2024; Mucci & Stryker 2024],

    [Accessible],
    [Dehghani 2022, Chapter 3; Balnojan et al. 2023, Chapter 5; Goedegebuure et al. 2024; Mucci & Stryker 2024],

    [Secure],
    [Dehghani 2022, Chapter 3; Balnojan et al. 2023, Chapter 5; Goedegebuure et al. 2024; Mucci & Stryker 2024],

    [Interoperable],
    [Dehghani 2022, Chapter 3; Balnojan et al. 2023, Chapter 5; Goedegebuure et al. 2024; Mucci & Stryker 2024],

    [Understandable],
    [Dehghani 2022, Chapter 3; Balnojan et al. 2023, Chapter 5; Goedegebuure et al. 2024; Mucci & Stryker 2024],

    [Trustworthy],
    [Dehghani 2022, Chapter 3; Balnojan et al. 2023, Chapter 5; Goedegebuure et al. 2024; Mucci & Stryker 2024],

    [Addressable],
    [Dehghani 2022, Chapter 3; Balnojan et al. 2023, Chapter 5; Mucci & Stryker 2024],

    [Reusable],
    [Balnojan et al. 2023, Chapter 5],

    [Consumable],
    [Hasan & Legner 2023],
  ),
  caption: [Characteristics of data products based on the literature],
  kind: table,
  supplement: [Tabelle],
) <tab:niinikoski-characteritics>

]
