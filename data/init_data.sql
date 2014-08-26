INSERT INTO "map" VALUES(1,'Beispiel','Eine **Beispiel-Concept-Map**');
INSERT INTO "map" VALUES(2,'01A','Die Concept Map der **Gruppe A**. Sie hat mehrere Vorteile:

* sie existiert
* ich kann comas Markdown-Kommentare demonstrieren');

INSERT INTO "connection" VALUES(1,'Java','isa','Programmiersprache');
INSERT INTO "connection" VALUES(1,'Java','has','JVM');
INSERT INTO "connection" VALUES(1,'Programmiersprache','isa','JVM');
INSERT INTO "connection" VALUES(2,'Informatik','besteht aus','Informationen');
INSERT INTO "connection" VALUES(2,'Informationen','haben','Repräsentationen');
INSERT INTO "connection" VALUES(2,'Repräsentationen','zuweisung von','Zustände');
INSERT INTO "connection" VALUES(2,'Informationen','werden','interpretiert');
INSERT INTO "connection" VALUES(2,'Zustände','sind','Berechenbar');
INSERT INTO "connection" VALUES(2,'Berechenbar','mit Hilfe von','Programme');
INSERT INTO "connection" VALUES(2,'Kopf','Teil von','Programme');
INSERT INTO "connection" VALUES(2,'Kopf','beinhaltet','Signatur');
INSERT INTO "connection" VALUES(2,'Kopf','beinhaltet','Zweck');
INSERT INTO "connection" VALUES(2,'Rumpf','Teil von','Programme');
INSERT INTO "connection" VALUES(2,'Rumpf','hat eine','Funktion');
INSERT INTO "connection" VALUES(2,'Funktion','nutzt','Hilfsfunktionen');
INSERT INTO "connection" VALUES(1,'Informatik','beinhaltet','Zweck');
INSERT INTO "connection" VALUES(1,'Programmiersprache','hat eine','Informatik');
INSERT INTO "connection" VALUES(2,'Programme','liefern','Informationen');
INSERT INTO "connection" VALUES(2,'Signatur','Teil von','Programme');
