# Release Notes

Im Folgenden finden Sie die Release Notes für das Redmine-Dogu. 

Technische Details zu einem Release finden Sie im zugehörigen [Changelog](https://docs.cloudogu.com/de/docs/dogus/redmine/CHANGELOG/).

## [Unreleased]
### Security
- [#157] fixes [CVE GHSA-353f-x4gh-cqq8](https://github.com/advisories/GHSA-353f-x4gh-cqq8)

## [v5.1.8-2] - 2025-06-11
### Added
* Zusätzliche Konfigurationsschlüssel rack/params_limit und rack/bytesize_limit hinzugefügt.
* ``rack/params_limit`` erhöht das Limit an Parametern in Anfragen an Redmine
    * Achtung: Requests mit sehr vielen Parametern können sehr lange dauern. In dieser Zeit ist das Redmine-Dogu für alle Benutzer in der Funktion eingeschränkt.
* ``rack/bytesize_limit`` erhöht das die Maximalgröße des Requests
    * Achtung: Sehr große Requests können sehr lange dauern. In dieser Zeit ist das Redmine-Dogu für alle Benutzer in der Funktion eingeschränkt.

## [v5.1.8-1] - 2025-05-13
### Changed
* Das Dogu bietet nun die Redmine-Version 5.1.6 an. Die Release Notes von Redmine finden Sie [hier](https://www.redmine.org/projects/redmine/wiki/Changelog_5_1#518-2025-04-20).

## [v5.1.6-3] - 2025-04-28
### Changed
- Die Verwendung von Speicher und CPU wurden für die Kubernetes-Multinode-Umgebung optimiert.

## [v5.1.6-2] - 2025-04-04
* Wir haben nur technische Änderungen vorgenommen. Näheres finden Sie in den Changelogs.

## [v5.1.6-1] - 2025-02-17
* Das Dogu bietet nun die Redmine-Version 5.1.6 an. Die Release Notes von Redmine finden Sie [hier](https://www.redmine.org/projects/redmine/wiki/Changelog_5_1#516-2025-01-29).
* Diese Version stellt Multinode-Kompatibilität sicher, indem sie das Löschen des Konfigurationsschlüssels "default_data" vermeidet. Weitere Details finden Sie in den Changelogs.

## [v5.1.4-3] - 2025-02-17
* die Version 5.1.6-1 wurde unter einer falschen Version released. Diese Version wurde wieder zurückgezogen und unter der korrekten Version wiederveröffentlicht 

## [v5.1.4-2] - 2025-01-09
* Konfigurationsschlüssel des Ecosystems welche globale Passwortrichtlinie behandeln, werden auch auf Redmine angewendet.
    * Dies bedeutet, dass dieselben Passwortrichtlinien, die für CES-Benutzer gelten, auch für interne Redmine-Benutzer gelten.

## [v5.1.4-1] - 2024-12-16
* Das Dogu bietet nun die Redmine-Version 5.1.4 an. Die Release Notes von Redmine finden Sie [hier](https://www.redmine.org/projects/redmine/wiki/Changelog_5_1#514-2024-11-03).

## 5.1.3-4
Wir haben nur technische Änderungen vorgenommen. Näheres finden Sie in den Changelogs.

## 5.1.3-3
* Die Cloudogu-eigenen Quellen werden von der MIT-Lizenz auf die AGPL-3.0-only relizensiert.

## 5.1.3-2
* Behebung von kritischem CVE-2024-41110 in Bibliotheksabhängigkeiten. Diese Schwachstelle konnte jedoch nicht aktiv ausgenutzt werden.

## 5.1.3-1

* Das Dogu bietet nun die Redmine-Version 5.1.2 an. Die Release Notes von Redmine finden Sie [hier](https://www.redmine.org/projects/redmine/wiki/Changelog_5_1#512-2024-06-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_REPLACE_ME).
* Diese Version veraltet das ursprüngliche Markdown-Format "Markdown" zugunsten des verbreiteten Markdown-Formats "CommonMark Markdown (Github-flavored)".
   - Für Neuinstallationen ist `CommonMark Markdown (github-flavoured)` nun der Standardformatter  
   - Obwohl der alte Formatter noch verwendet werden kann, sollten Administratoren von vorherigen Redmine-Versionen sich auf eine Umstellung ihrer Projekte einstellen:
      - Unterstrichener Text (`_underline_`) wird nicht länger als solches unterstützt und wird stattdessen *kursiv* dargestellt
      - Die [Github documentation](https://docs.github.com/de/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) hält zu den meisten unterstützen _Github-flavored Markdown_-Formatierungen Informationen bereit (der in Redmine verwendet jedoch nicht die neuesten Formatierungen wie z. B. _Alerts_)
   - Andere Formatter sind von dieser Änderung nicht betroffen

## 5.0.8-1

* Das Dogu bietet nun die Redmine-Version 5.0.8 an. Die Release Notes von Redmine finden Sie [hier](https://www.redmine.org/projects/redmine/wiki/Changelog_5_0#508-2024-03-04).
* In der Vergangenheit kam es vor, dass [Änderungen aus dem Usermanagement](https://docs.cloudogu.com/de/usermanual/usermgt/documentation/#synchronisation-von-accounts-und-gruppen) nach einem Login des betroffenen Nutzers nicht in Redmine aktualisiert worden sind. Der Fehler ist in dieser Version behoben worden.