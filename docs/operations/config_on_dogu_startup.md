# Konfiguration bei Dogustart ausbringen

Es ist möglich, Konfiguration über den etcd auszubringen. Das ist für die folgenden Werte möglich:

* Einstellungen verändern
* Workflows erstellen
* Aufzählungen erstellen
* Custom-Fields erstellen
* Tracker erstellen
* Issue Statuses erstellen

Hinweis: Voraussetzung für die Funktionsfähigkeit dieses Mechanismus' ist, dass die REST-API in den Einstellungen
aktiviert ist. Dafür muss der etcd-Key `config/redmine/etcd_redmine_config` gesetzt werden.
Beim Neustart des Redmine-Dogus wird die definierte Konfiguration dann angewandt und anschließend dieser Key entfernt.

Die zuletzt angewandte Konfiguration wird in dem etcd-Key `config/redmine/etcd_redmine_config_archived` gespeichert.
**Hinweis:** Dieser Key wird bei jeder erneuten ausführung überschrieben. Es ist immer nur die zuletzt angewandte 
Konfiguration historisiert.

## Beispielkonfiguration

```json
{
  "settings": {
    "app_title": "apptitle",
    "rest_api_enabled": "1"
  },
  "trackers": [
    {
      "name": "new feature tracker",
      "default_status_id": 1,
      "description": "my description"
    }
  ],
  "workflows": [
    {
      "role_id": [
        "1"
      ],
      "tracker_id": [
        "1"
      ],
      "transitions": {
        "123": {
          "1": {
            "always": "1"
          }
        }
      }
    }
  ],
  "enumerations": [
    {
      "type": "IssuePriority",
      "name": "Example Name",
      "custom_field_values": {
        "20": "content for custom field with id 20"
      }
    }
  ],
  "customFields": [
    {
      "type": "IssueCustomField",
      "name": "Super Points X3",
      "field_format": "int",
      "role_ids": [
        "1"
      ]
    }
  ],
  "issueStatuses": [
    {
      "name": "One-X",
      "is_closed": true
    }
  ]
}
```

### Bereich `settings`

Ermöglicht das Verändern globaler Einstellungen.

Ein Json-Objekt im folgenden Format:

```
{
  ......
  "<name der einstellung 1>": "<wert 1>",
  "<name der einstellung 2>": "<wert 2>",
  ......
}
```

### Bereich `trackers`

Ermöglicht das Anlegen neuer Tracker.

Ein Json-Array mit allen anzulegenden Trackern in folgendem Format:

```
[
  .....
  {
    "name": "<tracker 1 name>"
    "default_status_id": <issue-status-id>,
    "description": "<description>"
  },
  {
    "name": "<tracker 2 name>"
    "default_status_id": <issue-status-id>,
    "description": "<description>"
  },
  .....
]
```

### Bereich `workflows`

Ermöglicht das Anlegen neuer Workflows.

Ein Json-Array mit allen anzulegenden Workflows in folgendem Format:

```
[
  .....
  {
    "role_id": [
      "1"
    ],
    "tracker_id": [
      "1"
    ],
    "transitions": {
      "123": {
        "1": {
          "always": "1"
        }
      }
    }
  },
  .....
]
```

### Bereich `enumerations`

Ermöglicht das Anlegen neuer Aufzählungen.

Ein Json-Array mit allen anzulegenden Aufzählungen in folgendem Format:

```
[
  .....
  {
    "type": "IssuePriority",
    "name": "Example Name",
    "custom_field_values": {
      "20": "content for custom field with id 20"
    }
  },
  .....
]
```

### Bereich `customFields`

Ermöglicht das Anlegen neuer Benutzerdefinierter Felder.

Ein Json-Array mit allen anzulegenden Benutzerdefinierten Feldern in folgendem Format:

```
[
  .....
  {
    "type": "IssueCustomField",
    "name": "Super Points X3",
    "field_format": "int",
    "role_ids": [
      "1"
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
    "name": "One-X",
    "is_closed": true
  },
  .....
]
```
