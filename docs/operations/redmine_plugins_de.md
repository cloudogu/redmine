# Dateiverwaltung von Redmine-Plugins

Redmine lässt sich mit Plugins erweitern. Dabei ist die Verwaltung auf Dateiebene einfach. 

## Neue Plugins hinzufügen

Neue Plugins müssen als Verzeichnis unterhalb von Redmines Plugin-Verzeichnis liegen. Die Pfade lauten 
- im Container `/usr/share/webapps/redmine/plugins_prod`
- im Cloudogu EcoSystem `/var/lib/ces/redmine/volumes/plugins_prod`

Beispielhafte Verzeichnisansicht anhand des CAS-Plugins:

```
/var/lib/ces/redmine/volumes/plugins/
├─ redmine_cas/
   ├─ app
      ├─ ...
   ├─ config
      ├─ ...
   ├─ lib
      ├─ ...
   ├─ Gemfile
   ├─ init.rb
```

Um ein neues Plugin hinzuzufügen, muss lediglich das Verzeichnis des neuen Plugins in Redmines Plugin-Verzeichnis kopiert werden. Beim nächsten Dogu-Neustart kann das Plugin seine Wirkung entfalten.

### Ruby Gem und eine Internetverbindung

Neue Plugins benötigen sehr wahrscheinlich weitere Gem-Abhängigkeiten. In der Regel werden diese über https://rubygems.org ausgeliefert. 

In Cloudogu EcoSystem-Instanzen ohne Internetzugang ist daher dieser Schritt **nicht ohne weiteres möglich**. Eine Lösungsmöglichkeit wäre das Kopieren der Abhängigkeiten in den Ruby-Gem-Cache innerhalb des Containers mit `docker cp` udgl. Aktuell liegt der Cache unter `/usr/lib/ruby/gems/2.7.0`, dies kann sich jedoch in weiteren Versionen ändern. `docker exec redmine gem environment` liefert hierzu weitere Informationen.

Für im Dogu mitgelieferte Plugins ist keine Internetverbindung nötig, da dies während des Imagebaus bereits durchgeführt wurde und Ruby sich offenbar nicht beschwert, wenn die Summen stimmen. Dies ist auch der Grund, warum die Plugins im Image sowohl unter `${WORKDIR}/plugins` als auch unter `${WORKDIR}/defaultPlugins` liegen. 

## Plugins entfernen

Ein Redmine-Plugin zu entfernen ist einfach. Um ein Plugin zu entfernen, löscht oder verschiebt man das Verzeichnis des entsprechenden Plugins aus Redmines Plugin-Verzeichnis. Beim nächsten Dogu-Neustart tritt die Entfernung in Kraft.

Beim Entfernen von Plugins sollte verzichtet werden, Redmines gesamtes Plugin-Verzeichnis zu leeren oder zu löschen. Um einen Defekt nach dem Neustart auszuschließen, liegen die folgenden infrastruktur-relevanten Plugins gesichert im Container-Image vor, so dass sie bei Bedarf wiederhergestellt werden können:
- redmine_cas
- redmine_extended_rest_api
- redmine_activerecord_session_store

Die `startup.sh` übernimmt die Installation der Plugins, falls eines oder mehrere der Plugin-Verzeichnisse gelöscht oder verschoben wurden.