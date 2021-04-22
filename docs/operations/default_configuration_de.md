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

Zum Anwenden der Konfiguration muss der etcd-Key `config/redmine/etcd_redmine_config` gesetzt werden.
Beim Neustart des Redmine-Dogus wird die definierte Konfiguration dann angewandt und anschließend dieser Key entfernt.

Die zuletzt angewandte Konfiguration wird in dem etcd-Key `config/redmine/etcd_redmine_config_archived` gespeichert.
**Hinweis:** Dieser Key wird bei jeder erneuten Ausführung überschrieben. Es ist immer nur die zuletzt angewandte 
Konfiguration historisiert.

## Beispielkonfiguration

Im Folgenden ist eine funktionsfähige Beispielkonfiguration und eine grobe Erklärung der einzelnen 
Felder hinterlegt.
Die Struktur der einzelnen Unterpunkte richtet sich exakt nach der in dem `extended_rest_api`-Plugin vorgegebenen
Struktur.

Für weitere Informationen über die API des `extended_rest_api`-Plugins:
Mit dem Plugin wird eine Openapi 3.0 Definition für die API ausgeliefert. Diese ist auf der Seite des
Plugins auf [Github](https://github.com/cloudogu/redmine_extended_rest_api/blob/main/src/assets/openapi.yml) zu finden.
Alternativ wird diese mit Redmine zusammen ausgeliefert und kann unter `https://<fqdn>/redmine/extended_api/v1/spec` 
abgerufen werden.
Um diese grafisch darzustellen, kann z. B. das [Swagger UI - Dogu](https://github.com/cloudogu/swaggerui) genutzt werden. 

```json
{
  "settings": {
    "app_title": "My application name"
  },
  "trackers": [
    {
      "name": "new feature tracker",
      "default_status_id": 1,
      "description": "my description"
    },
    {
      "name": "new feature tracker 2",
      "default_status_id": 1,
      "description": "my description"
    },
    {
      "name": "new feature tracker 3",
      "default_status_id": 1,
      "description": "my description"
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
    "default_status_id": <issue-status-id>,
    "description": "<description>"
  },
  .....
]
```

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

Ein JSON-Array mit allen anzulegenden Aufzählungen in folgendem Format:

```
[
  .....
  {
    "type": "<Typ der Aufzählung (z.B 'IssuePriority')>",
    "name": "<Name der Aufzählung>",
    "custom_field_values": {
      "<id eines wertes>": "<name eines Wertes>"
    }
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
