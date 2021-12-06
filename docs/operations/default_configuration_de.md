# Konfiguration bei Dogustart ausbringen

Es ist möglich, Konfiguration über den etcd auszubringen. Das ist für die folgende Konfiguration möglich:

* Einstellungen verändern
* Rollen erstellen oder verändern
* Workflows erstellen
* Aufzählungen erstellen
* Custom-Fields erstellen
* Tracker erstellen
* Issue Statuses erstellen

Hinweis: Voraussetzung für die Funktionsfähigkeit dieses Mechanismus' ist, dass die REST-API in den Einstellungen
aktiviert ist.

Zum Anwenden der Konfiguration muss der etcd-Key `config/redmine/default_data/new_configuration` gesetzt werden.
Beim Neustart des EasyRedmine-Dogus wird die definierte Konfiguration dann angewandt und anschließend dieser Key
entfernt.

Die zuletzt angewandte Konfiguration wird in dem etcd-Key `config/redmine/default_data/archived/<Zeitstempel>`
gespeichert.

Bei jedem Import werden ID's und Namen von Rollen, Ticket-Status und Tracker von der Datenbank der aktuellen Instanz abgefragt.
Dies ermöglicht die Verwendung der genannten Objekte bei der Erstellung von beliebigen Feldern.

## Beispielkonfiguration

Im Folgenden ist eine funktionsfähige Beispielkonfiguration und eine grobe Erklärung der einzelnen Felder hinterlegt.
Die Konfiguration orientiert sich sehr stark an der API des extended_rest_api-Plugins.

Für weitere Informationen über die API des `extended_rest_api`-Plugins:
Mit dem Plugin wird eine Openapi 3.0 Definition für die API ausgeliefert. Diese ist auf der Seite des Plugins
auf [Github](https://github.com/cloudogu/redmine_extended_rest_api/blob/main/src/assets/openapi.yml) zu finden.
Alternativ wird diese mit EasyRedmine zusammen ausgeliefert und kann
unter `https://<fqdn>/redmine/extended_api/v1/spec`
abgerufen werden. Um diese grafisch darzustellen, kann z. B.
das [Swagger UI - Dogu](https://github.com/cloudogu/swaggerui) genutzt werden.

```json
{
  "settings": {
    "app_title": "Updated Redmine"
  },
  "roles": [
    {
      "name": "User",
      "permissions": [
        "add_project",
        "edit_project",
        "close_project",
        "select_project_modules",
        "manage_members",
        "manage_versions",
        "add_subprojects",
        "manage_public_queries",
        "save_queries",
        "view_messages",
        "add_messages",
        "view_calendar",
        "view_documents",
        "view_files",
        "manage_files",
        "view_gantt",
        "view_issues",
        "add_issues",
        "edit_issues",
        "manage_issue_relations",
        "add_issue_notes",
        "view_news",
        "comment_news",
        "view_changesets",
        "browse_repository",
        "view_time_entries",
        "log_time",
        "view_wiki_pages",
        "view_wiki_edits",
        "edit_wiki_pages"
      ]
    }
  ],
  "issueStatuses": [
    {
      "name": "New issue",
      "is_closed": false
    },
    {
      "name": "Issue in Progress",
      "is_closed": false
    },
    {
      "name": "Issue in Review",
      "is_closed": false
    },
    {
      "name": "Issue Done",
      "is_closed": true
    }
  ],
  "trackers": [
    {
      "name": "Bugtracker",
      "default_status_name": "New",
      "description": "It's just a bug."
    },
    {
      "name": "User Story tracker",
      "default_status_name": "New",
      "description": "It's just a User Story"
    },
    {
      "name": "Tasktracker",
      "default_status_name": "New",
      "description": "It's just a Task."
    }
  ],
  "customFields": [
    {
      "type": "IssueCustomField",
      "name": "Story Points Field",
      "field_format": "int",
      "role_names": [
        "User"
      ],
      "tracker_names": [
        "Bug",
        "User Story",
        "Task"
      ]
    },
    {
      "type": "IssueCustomField",
      "name": "Extended description field",
      "field_format": "text",
      "role_names": [
        "User"
      ],
      "tracker_names": [
        "Bug",
        "User Story",
        "Task"
      ]
    }
  ],
  "enumerations": [
    {
      "type": "IssuePriority",
      "name": "Not important at all"
    },
    {
      "type": "IssuePriority",
      "name": "A little bit important"
    },
    {
      "type": "IssuePriority",
      "name": "Very important"
    },
    {
      "type": "IssuePriority",
      "name": "Very Immediate"
    },
    {
      "type": "IssuePriority",
      "name": "Yesterday"
    }
  ],
  "workflows": [
    {
      "role_names": [
        "User",
        "Anonymous"
      ],
      "tracker_names": [
        "Bug",
        "User Story",
        "Task"
      ],
      "transitions": {
        "New": {
          "In Progress": {
            "always": "1"
          },
          "Review": {
            "always": "1"
          },
          "Done": {
            "always": "1"
          }
        },
        "In Progress": {
          "Review": {
            "always": "1"
          },
          "Done": {
            "always": "1"
          },
          "New": {
            "always": "0"
          }
        },
        "Review": {
          "In Progress": {
            "always": "1"
          },
          "Done": {
            "always": "1"
          },
          "New": {
            "always": "0"
          }
        },
        "Done": {
          "In Progress": {
            "always": "0"
          },
          "Done": {
            "always": "0"
          },
          "New": {
            "always": "0"
          }
        }
      }
    }
  ]
}
```

### Bereich `settings`

Ermöglicht das Verändern globaler Einstellungen.

Ein JSON-Objekt im folgenden Format:

```
{
  ......
  "<name der einstellung 1>": "<wert 1>",
  "<name der einstellung 2>": "<wert 2>",
  ......
}
```

### Bereich `roles`

Ermöglicht das Anlegen oder Verändern von Rollen.

Ein JSON-Objekt im folgenden Format:

```
[
  .....
  {
    "name": "<Name der Rolle>",
    "permissions": [
      "<Wert>",
      ...
    ]
  },
  .....
]
```

### Bereich `issueStatuses`

Ermöglicht das Anlegen neuer Ticket-Status.

```
[ 
  .....
  {
    "name": "<Name des Ticket-Status>",
    "is_closed": <true|false>
  },
  .....
]
```

### Bereich `customFields`

Ermöglicht das Anlegen neuer benutzerdefinierter Felder.

Ein JSON-Array mit allen anzulegenden benutzerdefinierten Feldern in folgendem Format:

```
[
  .....
  {
    "type": "<Typ des Feldes, z.B 'IssueCustomField'>",
    "name": "<Name des Feldes>",
    "field_format": "<Format des Feldes z.B 'int'>",
    "role_ids": [
      "<Id einer Rolle>"
    ]
  },
  .....
]
```

### Bereich `enumerations`

Ermöglicht das Anlegen neuer Aufzählungen.

Ein JSON-Array mit allen anzulegenden Aufzählungen in folgendem Format:

```
[
  .....
  {
    "type": "<Typ der Aufzählung (z.B 'IssuePriority')>",
    "name": "<Name der Aufzählung>",
    "custom_field_values": {
      "<id eines custom-fields | name eines custom-fields>": "<name eines Wertes>"
      "<id eines custom-fields | name eines custom-fields>": "<name eines Wertes>"
    }
  },
  .....
]
```

#### Besonderheit der `custom_field_values`

Der Eintrag `custom_field_values` ist ein Json-Objekt, bei welchem der Key entweder der id eines Benutzerdefinierten
Feldes oder aber dem Namen entspricht. Der Name kann aber nur dann verwendet werden, wenn das custom-field zuvor über
den hier beschriebenen Mechanismus angelegt worden ist.

### Bereich `trackers`

Ermöglicht das Anlegen neuer Tracker.

Ein JSON-Array mit allen anzulegenden Trackern in folgendem Format:

```
[
  .....
  {
    "name": "<tracker 1 name>",
    "default_status_id": <issue-status-id>,
    "description": "<description>"
  },
  {
    "name": "<tracker 2 name>",
    "default_status_name": "<issue-status-name>",
    "description": "<description>"
  },
  .....
]
```

#### Besonderheit des Feldes `default_status_name`

Statt des Feldes `default_status_id` kann alternativ das Feld `default_status_name` angegeben werden. Dies funktioniert
allerdings nur dann, wenn der Ticket-Status vorher über den hier beschriebenen Mechanismus angelegt worden ist.

### Bereich `workflows`

Ermöglicht das Anlegen neuer Workflows.

Ein JSON-Array mit allen anzulegenden Workflows in folgendem Format:

```
[
  .....
  {
    "role_names": [
      "<rollen-name 1>",
      "<rollen-name 2>"
    ],
    "tracker_names": [
      "<tracker-name 1>",
      "<tracker-name 2>"
    ],
    "transitions": {
      "<from-issue-status-id>": {
        "<to-issue-status-id>": {
          "always": "1"
        }
      },
      "<from-issue-status-name>": {
        "<to-issue-status-name>": {
          "always": "1"
        }
      }
    }
  },
  .....
]
```

