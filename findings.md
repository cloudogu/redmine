#### redmine_activerecord_session_store plugin 
  * ``` shell
    Because activerecord-session_store >= 2.0.0, < 2.1.0 depends on rack >= 2.0.8, < 3
    and Gemfile depends on rack >= 3.1.3,
    activerecord-session_store >= 2.0.0, < 2.1.0 cannot be used.
    So, because Gemfile depends on activerecord-session_store ~> 2.0.0,
    version solving has failed.
    ```
  * -> redmine_activerecord_session_store updaten und neu releasen
  * es gibt kein Release von activerecord für Rails 7
    * ~~activerecord müsste selbst von source gebaut werden https://github.com/rails/activerecord-session_store/blob/master/gemfiles/rails_7.1.gemfile~~
  * Activerecord_session_store braucht rack < 3, Redmine 6 braucht rack > 3.x
  * Lösung
    * https://github.com/customink/activerecord-session_store dieser Fork kann als Alternative genutzt werden
      * selbst forken geht auch
      * Fork als globalen Gem im Container installieren
        * siehe Dockerfile ~ Zeile 102: # install Activerecord-sesion_store gem manually
      * Plugin wie vorher aus git in den Plugins-Ordner installieren, aber Version auf die Version vom Fork anpassen (z.B. 2.1.0)
        * In diesem Branch wurde das Plugin manuell in den resources-Ordner eingecheckt
#### Ruby-Version muss geupdatet werden
  * via EXTENDED_REST_API_PLUGIN_VERSION mind 1.2.0
  * lib könnte man direkt auch hochziehen
#### stringio
  * ``` shell
    WARN: Unresolved or ambiguous specs during Gem::Specification.reset:
    stringio (>= 0)
    Available/installed versions of this gem:
      - 3.1.2
      - 3.0.4
    ```
  * besteht eventuell schon länger
  * Tritt bei ruby tasks auf
#### yaml-dev
* yaml-dev zu apk /.build-deps hinzufügen
  * Dockerfile ~ Zeile 100
#### rexml
* rexml als Gem hinzufügen, ist nicht mehr automatisch in ruby installiert
  *  `&& echo 'gem "rexml"' >> ${WORKDIR}/Gemfile \`
  * siehe ähnliche Zeile (Dockerfile 127) zu json
#### secrets-File
* secrets file zu credentials-file ändern.
  * braucht migrations-Skript um vorhande File anzupassen
  * ```
    echo "Rendering config/credentials.yml..."
      doguctl template "${WORKDIR}/config/credentials.yml.tpl" "${WORKDIR}/config/credentials.yml"
      rails credentials:edit
    ```
  * config master.key muss eventuell aus den Logs entfernt werden
  * https://blog.assistancy.be/blog/how-to-store-credentials-in-rails-7/
#### db:sessions:clear ersetzen
* exec_rake db:sessions:clear
  * ist nicht mehr vorhanden
  * https://stackoverflow.com/questions/48093136/rails-5-managing-sessions-data
    * exec_rake tmp:clear
#### RedmineUP Plugins
  * keine Infos, wann Redmine 6 unterstützt wird
  * Redmine Checklists plugin
    * 5.1
  * Redmine Agile plugin
    * 5.1
  * Redmine CRM plugin
    * 5.1
  * Redmine Helpdesk plugin
    * 5.1
  * Redmine Tags plugin
    * 5.1
#### Other Plugins
  * Redmine edit issue author
    * 5.1
    * scheint zu funktionieren
  * Redmine google chat
    * 4.1???
    * Fehler bei der Installation -> nicht weiter untersucht
  * Redmine issue templates
    * 5.1
    * ``` shell
      DEPRECATION WARNING: Defining enums with keyword arguments is deprecated and will be removed
      in Rails 8.0. Positional arguments should be used instead:

      enum :visibility, {:roles=>1, :open=>2}
      (called from <class:GlobalNoteTemplate> at /usr/share/webapps/redmine/plugins/redmine_issue_templates/app/models/global_note_template.rb:33)
    * scheint zu funktionieren
#### Deprecation warning
* [f32f8add-6c1a-4649-b8e9-0fdd30d89d1c] DEPRECATION WARNING: to_time will always preserve the timezone offset of the receiver in Rails 8.0. To opt in to the new behavior, set `ActiveSupport.to_time_preserves_timezone = true`. (called from time_tag at /usr/share/webapps/redmine/app/helpers/application_helper.rb:744)
#### User Logout
```shell
[ae299ef5-3599-48c3-adbf-9724746f1333] Couldn't destroy session service ticket ST-5-Jl0UFJKozJyKGPj-2E902kfJqyw-cas because no corresponding session id could be found.
[ae299ef5-3599-48c3-adbf-9724746f1333] Missing template, responding with 404: Missing template account/cas, application/cas with {:locale=>[:en], :formats=>[:html], :variants=>[], :handlers=>[:raw, :erb, :html, :builder, :ruby, :rsb]}.

Searched in:
  * "/usr/share/webapps/redmine/plugins/redmine_issue_templates/app/views"
  * "/usr/share/webapps/redmine/plugins/redmine_editauthor/app/views"
  * "/usr/share/webapps/redmine/plugins/redmine_cas/app/views"
  * "/usr/share/webapps/redmine/app/views"

```
* Der Logout eines Benutzers über das warp-Menü scheint nicht korrekt zu funktionieren
  * Beim Login mit einem anderen Benutzer bleibt der vorherige Benutzer angemeldet
  * CAS-Plugin oder activerecord-session_store