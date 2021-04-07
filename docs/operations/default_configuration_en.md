# Deploy configuration on dogustart

It is possible to deploy configuration via the etcd. This is possible for the following values:

* change settings
* create workflows
* Create enumerations
* Create custom fields
* Create trackers
* Create issue statuses

Note: For this mechanism to work, the REST API must be enabled in the settings
is enabled.

To apply the configuration, the etcd key `config/redmine/etcd_redmine_config` must be set.
When the Redmine dogus is restarted, the defined configuration is then applied and this key is then removed.
# Deploy configuration on dogustart

The last applied configuration is stored in the etcd key `config/redmine/etcd_redmine_config_archived`.
**Note:** This key is overwritten with every new execution. Only the last used configuration is
historized.

## Example configuration


In the following a functional example configuration and a rough explanation of the individual fields is deposited.
fields.
The structure of the individual sub-items follows exactly the structure given in the `extended_rest_api` plugin structure.

For more information about the API of the `extended_rest_api` plugin:
An Openapi 3.0 definition for the API is shipped with the plugin. It can be found on the
plugin page on [Github](https://github.com/cloudogu/redmine_extended_rest_api/blob/main/src/assets/openapi.yml).
Alternatively, this is shipped with Redmine and can be accessed at `https://<fqdn>/redmine/extended_api/v1/spec`.
To display this graphically, e.g. the [Swagger UI - Dogu](https://github.com/cloudogu/swaggerui) can be used.

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

### Area `settings`

Allows changing global settings.

A Json object in the following format:

```
{
  ......
  "<name of setting 1>":"<value 1>",
  "<name of setting 2>":"<value 2>",
  ......
}
```

### `trackers` section

Enables the creation of new trackers.

A json array with all trackers to be created in the following format:

```
[
  .....
  {
    "name":"<tracker 1 name>"
    "default_status_id": <issue-status-id>,
    "description":"<description>"
  },
  {
    "name": "<tracker 2 name>"
    "default_status_id": <issue-status-id>,
    "description":"<description>"
  },
  .....
]
```

### `workflows` section

Enables the creation of new workflows.

A json array with all workflows to be created in the following format:

```
[
  .....
  {
    { "role_id": [
      "<role_id 1>",
      "<role-id 2>"
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

### `enumerations` section

Enables the creation of new enumerations.

A json array with all enumerations to be created in the following format:

```
[
  .....
  {
    "type":"<type of enumeration (e.g. 'IssuePriority')>",
    "name": "<name of enumeration>",
    "custom_field_values": {.
      "<id of a value>":"<name of a value>"
    }
  },
  .....
]
```

### `customFields` section

Allows creating new Custom Fields.

A json array with all custom fields to be created in the following format:

```
[
  .....
  {
    "type":"<type of field, e.g. 'IssueCustomField'>",
    "name":"<name of field>",
    "field_format":"<format of field e.g. 'int'>",
    "role_ids": [.
      "<Id of a role>"
    ]
  },
  .....
]
```

### `issueStatuses` area

Enables the creation of new ticket statuses.

```
[ 
  .....
  {
    "name":"<name of ticket status>",
    "is_closed": <true|false>
  },
  .....
]
```
