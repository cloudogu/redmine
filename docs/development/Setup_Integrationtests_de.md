# Setup für die Integrationstests

In diesem Abschnitt werden die benötigten Schritte beschrieben um die Integrationstests für Redmine korrekt ausführen zu können.

## Voraussetzungen

* Es ist notwendig das Program `yarn` zu installieren

## Konfiguration 

Damit alle Integrationstests auch einwandfrei funktionieren, müssen vorher einige Daten konfiguriert werden. 

**integrationTests/cypress.json** [[Link zur Datei](../../integrationTests/cypress.json)]

In dieser Datei muss die base-URL auf das Hostsystem angepasst werden.
Dafür muss das Feld `baseUrl` auf die Host-FQDN angepasst werden (`https://local.cloudogu.com`)

**integrationTests/cypress/fixtures/ces_admin_data.json** [[Link zur Datei](../../integrationTests/cypress/fixtures/ces_admin_data.json)]

In der `ces_admin_data.json` müssen die LoginInformation eines CES-Admin in den Feldern `adminuser` und `adminpassword` eingetragen werden.
Ebenfalls muss die derzeitige admin Gruppe im Feld `admingroup` anageben werden.

## Starten der Integrationstests

Die Integrationstests können auf zwei Arten gestartet werden:

1. Mit `yarn cypress run` starten die Tests nur in der Konsole ohne visuelles Feedback.
   Dieser Modus ist hilfreich, wenn die Ausführung im Vordergrund steht.
   Beispielsweise bei einer Jenkins-Pipeline.
   
1. Mit `yarn cypress open` startet ein interaktives Fenster, wo man die Tests ausführen, visuell beobachten und debuggen kann.
   Dieser Modus ist besonders hilfreich bei der Entwicklung neuer Tests und beim Finden von Fehlern.