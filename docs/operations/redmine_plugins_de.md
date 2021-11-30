# Dateiverwaltung von Redmine-Plugins

Redmine lässt sich mit Plugins erweitern. Dabei ist die Verwaltung auf Dateiebene einfach. 

## Neue Plugins hinzufügen

Neue Plugins müssen als Verzeichnis unterhalb von Redmines Plugin-Verzeichnis liegen. Die Pfade lauten 
- im Container `/usr/share/webapps/redmine/plugins`
- im Cloudogu EcoSystem `/var/lib/ces/redmine/volumes/plugins`

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

## Plugins entfernen

Ein Redmine-Plugin zu entfernen ist einfach. Um ein Plugin zu entfernen, löscht oder verschiebt man das Verzeichnis des entsprechenden Plugins aus Redmines Plugin-Verzeichnis. Beim nächsten Dogu-Neustart tritt die Entfernung in Kraft.

**Vorsicht:**

Beim Entfernen von Plugins sollte dringendst darauf geachtet werden, nicht Redmines gesamtes Plugin-Verzeichnis zu leeren oder zu löschen. Auch kritische Infrastruktur-Plugins (insbesondere das Redmine-CAS-Plugin / `redmine_cas`) darf nicht gelöscht werden, da dies ein defektes Dogu zur Folge haben wird. Ein übliches Kennzeichen ist eine ungewohnte Anmeldemaske oder die Unfähigkeit, sich per CAS an Redmine anzumelden.