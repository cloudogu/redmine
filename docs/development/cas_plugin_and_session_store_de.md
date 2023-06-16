# Entwicklerhinweise zum CAS-Plugin und dem Session-Store
Seit Redmine 5.x und dem damit verbundenen Wechsel auf Rails 6 wurde etwas am Initialisierungsmechanismus der Plugins geändert.
Dies führte dazu, dass das `redmine_activerecord_session_store`-Plugin nicht mehr alleine lauffähig war.
Die Konfiguration des Session-Stores wurde nicht mehr angezogen.
Dafür war es notwendig, zusätzlich die Datei `resources/usr/share/webapps/redmine/config/initializers/session_store.rb` hinzuzufügen.
Ohne diese mit dem Aufruf `Rails.application.config.session_store :active_record_store` wurde von Redmine der Session-Store nicht mehr erkannt.
Diese Konfiguration ist wichtig, damit der Backchannel-Logout bei Redmine funktioniert. Bei Weiterentwicklungen und damit möglicherweise auftretenden
Problemen könnte es sinnvoll sein, diesen Mechanismus noch einmal zu überarbeiten.