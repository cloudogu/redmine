# Release Notes

Im Folgenden finden Sie die Release Notes für das Redmine-Dogu. 

Technische Details zu einem Release finden Sie im zugehörigen [Changelog](https://docs.cloudogu.com/de/docs/dogus/redmine/CHANGELOG/).

## [Unreleased]
### Changed
- Das Dogu bietet nun Redmine in Version 6.1.2. Den Redmine changelog finden sie [hier](https://www.redmine.org/projects/redmine/wiki/Changelog_6_1#612-2026-03-16)
### Security
- Sicherheitslücke [CVE-2026-22184](https://avd.aquasec.com/nvd/cve-2026-22184) geschlossen

## [v6.1.1-5] - 2026-02-24
### Fixed
- [#185] HTTPS-Kommunikation von Redmine zu einem anderen Dogu mit
  selbstsignierten Zertifikaten behoben

## [v6.1.1-4] - 2026-02-18
### Security
- [#183] Sicherheitslücke CVE-2025-61732 und CVE-2025-68121 geschlossen

## [v6.1.1-3] - 2026-02-02
### Fixed
* Manchmal wurden E-Mails versendet, wenn temporäre Administratorkonten erstellt wurden.
  Das verwirrte die Administratoren, da sie nicht erkennen konnten, ob es sich um ein Sicherheitsproblem handelte.
  Wir verwenden nun ein einziges internes Administratorkonto, das nur einmal erstellt wird, anstatt bei jedem Systemstart
  ein neues zu erstellen und zu löschen. Dies sollte die Anzahl dieser E-Mails verringern.
## [v6.1.1-2] - 2026-01-29

### Security
- [#178] Sicherheitslücke geschlossen [cve-2025-15467](https://avd.aquasec.com/nvd/2025/cve-2025-15467/)

## [v6.1.1-1] - 2026-01-22
### Changed
* Das Dogu bietet nun die Redmine-Version 6.1.1 an. Die Release Notes von Redmine finden Sie [hier](https://www.redmine.org/projects/redmine/wiki/Changelog_6_1#611-2026-01-05).


## [v6.0.6-3] - 2025-11-25
### Fixed
* Robustheit des Löschvorgangs von temporären Admins erhöht.
    * In Fehlerfällen können temporäre Admin Accounts in einem vorherigen Startversuch schon gelöscht wurden sein.
      * Während der damit verbundene Schlüssel in der Konfiguration darauf hingewiesen hat das ein solcher Account noch existiert. 
      * Nachfolgende Löschversuche würden demnach fehlschlagen und die Konfiguration nicht richtig aufgeräumt werden, welches den Start des Dogu's verhindert. 
      * Dieses Release behebt diesen Fehler.

## [v6.0.6-2] - 2025-09-19
### Changed
* Wir haben nur technische Änderungen vorgenommen. Näheres finden Sie in den Changelogs.

## [v6.0.6-1] - 2025-08-22
### Changed
* Das Dogu bietet nun die Redmine-Version 6.0.6 an. Die Release Notes von Redmine finden Sie [hier](https://www.redmine.org/projects/redmine/wiki/Changelog_6_0#606-2025-07-07).

## [v5.1.8-4] - 2025-11-27
### Fixed
* Robustheit des Löschvorgangs von temporären Admins erhöht.
    * In Fehlerfällen können temporäre Admin Accounts in einem vorherigen Startversuch schon gelöscht wurden sein.
        * Während der damit verbundene Schlüssel in der Konfiguration darauf hingewiesen hat das ein solcher Account noch existiert.
        * Nachfolgende Löschversuche würden demnach fehlschlagen und die Konfiguration nicht richtig aufgeräumt werden, welches den Start des Dogu's verhindert.
        * Dieses Release behebt diesen Fehler.
    * Backport für die Version 5

## [v5.1.8-3] - 2025-08-06
### Changed
* Wir haben nur technische Änderungen vorgenommen. Näheres finden Sie in den Changelogs.

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
