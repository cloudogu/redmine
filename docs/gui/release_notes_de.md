# Release Notes

Im Folgenden finden Sie die Release Notes für das Redmine-Dogu. 

Technische Details zu einem Release finden Sie im zugehörigen [Changelog](https://docs.cloudogu.com/de/docs/dogus/redmine/CHANGELOG/).

## Release 5.1.3-1

* Das Dogu bietet nun die Redmine-Version 5.1.2 an. Die Release Notes von Redmine finden Sie [hier](https://www.redmine.org/projects/redmine/wiki/Changelog_5_1#512-2024-06-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_REPLACE_ME).
* Diese Version veraltet das ursprüngliche Markdown-Format "Markdown" zugunsten des verbreiteten Markdown-Formats "CommonMark Markdown (Github-flavored)".
   - Obwohl der alte Formatter noch verwendet werden kann, sollten Administratoren sich auf eine Umstellung ihrer Projekte einstellen:
      - Unterstrichener Text (`_underline_`) wird nicht länger als solches unterstützt und wird stattdessen *kursiv* dargestellt
      - Die [Github documentation](https://docs.github.com/de/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) hält zu den meisten unterstützen _Github-flavored Markdown_-Formatierungen Informationen bereit (der in Redmine verwendet jedoch nicht die neuesten Formatierungen wie z. B. _Alerts_)
   - Andere Formatter sind von dieser Änderung nicht betroffen

## Release 5.0.8-1

* Das Dogu bietet nun die Redmine-Version 5.0.8 an. Die Release Notes von Redmine finden Sie [hier](https://www.redmine.org/projects/redmine/wiki/Changelog_5_0#508-2024-03-04).
* In der Vergangenheit kam es vor, dass [Änderungen aus dem Usermanagement](https://docs.cloudogu.com/de/usermanual/usermgt/documentation/#synchronisation-von-accounts-und-gruppen) nach einem Login des betroffenen Nutzers nicht in Redmine aktualisiert worden sind. Der Fehler ist in dieser Version behoben worden.