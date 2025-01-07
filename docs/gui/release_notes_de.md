# Release Notes

Im Folgenden finden Sie die Release Notes für das Redmine-Dogu. 

Technische Details zu einem Release finden Sie im zugehörigen [Changelog](https://docs.cloudogu.com/de/docs/dogus/redmine/CHANGELOG/).

## [Unreleased]
* Konfigurationsschlüssel des Ecosystems welche globale Passwortrichtlinien behandeln, werden auch auf redmine angewendet.
    * Dies bedeutet, dass dieselben Passwortrichtlinien, die in Blueprints festgelegt wurden, auch in Redmine wirksam werden.den.

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