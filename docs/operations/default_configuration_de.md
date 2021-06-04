# Konfiguration bei Dogustart ausbringen

Es ist möglich, Konfiguration über den etcd auszubringen. Das ist für die folgende Konfiguration möglich:

* Einstellungen verändern
* Workflows erstellen
* Aufzählungen erstellen
* Custom-Fields erstellen
* Tracker erstellen
* Issue Statuses erstellen

Hinweis: Voraussetzung für die Funktionsfähigkeit dieses Mechanismus' ist, dass die REST-API in den Einstellungen
aktiviert ist.

Zum Anwenden der Konfiguration muss der etcd-Key `config/redmine/default_data/new_configuration` gesetzt werden.
Beim Neustart des Redmine-Dogus wird die definierte Konfiguration dann angewandt und anschließend dieser Key
entfernt.

Die zuletzt angewandte Konfiguration wird in dem etcd-Key `config/redmine/default_data/archived/<Zeitstempel>`
gespeichert.

Wurden Ticket-Status, Benutzerdefinierte Felder oder Tracker angelegt, so werden die IDs dieser Felder in dem
Key `config/redmine/default_data/creation_ids` gespeichert, damit ein Mapping zwischen der ID und dem Namen der
Felder für das weitere Anlegen von Feldern geschehen kann. Der Key bleibt für weitere Zugriffe erhalten und wird bei
jedem weiteren Zugriff ergänzt.

## Beispielkonfiguration

Im Folgenden ist eine funktionsfähige Beispielkonfiguration und eine grobe Erklärung der einzelnen Felder hinterlegt.
Die Konfiguration orientiert sich sehr stark an der API des extended_rest_api-Plugins.

Für weitere Informationen über die API des `extended_rest_api`-Plugins:
Mit dem Plugin wird eine Openapi 3.0 Definition für die API ausgeliefert. Diese ist auf der Seite des Plugins
auf [Github](https://github.com/cloudogu/redmine_extended_rest_api/blob/main/src/assets/openapi.yml) zu finden.
Alternativ wird diese mit Redmine zusammen ausgeliefert und kann
unter `https://<fqdn>/redmine/extended_api/v1/spec`
abgerufen werden. Um diese grafisch darzustellen, kann z. B.
das [Swagger UI - Dogu](https://github.com/cloudogu/swaggerui) genutzt werden.

```json
{
  "settings": {
    "app_title": "Updated Redmine"
  },
  "issueStatuses": [
    {
      "name": "New Status",
      "is_closed": false
    },
    {
      "name": "In Progress Status",
      "is_closed": false
    },
    {
      "name": "Review Status",
      "is_closed": false
    },
    {
      "name": "Done Status",
      "is_closed": true
    }
  ],
  "trackers": [
    {
      "name": "Bug Tracker",
      "default_status_name": "New Status",
      "description": "It's just a bug."
    },
    {
      "name": "User Story Tracker",
      "default_status_name": "New Status",
      "description": "It's just a User Story"
    },
    {
      "name": "Task Tracker",
      "default_status_name": "New Status",
      "description": "It's just a Task."
    }
  ],
  "customFields": [
    {
      "type": "IssueCustomField",
      "name": "Story Points",
      "field_format": "int",
      "role_ids": [
        "1"
      ],
      "tracker_ids": [
        "Bug Tracker",
        "User Story Tracker",
        "Task Tracker"
      ]
    },
    {
      "type": "IssueCustomField",
      "name": "Extended description",
      "field_format": "text",
      "role_ids": [
        "1"
      ],
      "tracker_ids": [
        "Bug Tracker",
        "User Story Tracker",
        "Task Tracker"
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
      "name": "Super Immediate"
    },
    {
      "type": "IssuePriority",
      "name": "Yesterday"
    }
  ],
  "workflows": [
    {
      "role_id": [
        "1",
        "2"
      ],
      "tracker_names": [
        "Bug Tracker",
        "User Story Tracker",
        "Task Tracker"
      ],
      "transitions": {
        "New Status": {
          "In Progress Status": {
            "always": "1"
          },
          "Review Status": {
            "always": "1"
          },
          "Done Status": {
            "always": "1"
          }
        },
        "In Progress Status": {
          "Review Status": {
            "always": "1"
          },
          "Done Status": {
            "always": "1"
          },
          "New Status": {
            "always": "0"
          }
        },
        "Review Status": {
          "In Progress Status": {
            "always": "1"
          },
          "Done Status": {
            "always": "1"
          },
          "New Status": {
            "always": "0"
          }
        },
        "Done Status": {
          "In Progress Status": {
            "always": "0"
          },
          "Done Status": {
            "always": "0"
          },
          "New Status": {
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
    "role_id": [
      "<rollen-id 1>",
      "<rollen-id 2>"
    ],
    "tracker_id": [
      "<tracker-id 1>",
      "<tracker-id 2>"
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

#### Besonderheit `transitions`

In diesem Bereich werden die Übergänge zwischen Ticket-Status definiert. Dafür kann sowohl die ID eines Ticket-Status
verwendet werden als auch der Name. Der Name kann aber nur dann verwendet werden, wenn der Ticket-Status zuvor über den
hier beschriebenen Mechanismus angelegt wurde.

