# Deploy configuration on dogustart

It is possible to deploy configuration via the etcd. This is possible for the following configuration:

* change settings
* create workflows
* Create enumerations
* Create custom fields
* Create trackers
* Create Issue Statuses

Note: For this mechanism to work, the REST API must be enabled in the settings.

To apply the configuration, the etcd key `config/redmine/default_data/new_configuration` must be set. At
restart of the Redmine-Dogu, the defined configuration will be applied and afterwards this key will be removed.

The last applied configuration is stored in the etcd key `config/redmine/default_data/archived/<timestamp>`.

If ticket statuses, user-defined fields or trackers have been created, the IDs of these fields will be
stored in the key `config/redmine/default_data/creation_ids`, so that a mapping between the ID and the name of the
of the fields for further creation of fields. The key is kept for further accesses and will be extended at further access.

## Example configuration

In the following a functional example configuration and a rough explanation of the individual fields is deposited.

## Example configuration

In the following a functional example configuration and a rough explanation of the individual fields is deposited.
The configuration is very much based on the API of the extended_rest_api plugin.


For more information about the API of the `extended_rest_api` plugin:
An Openapi 3.0 definition for the API is shipped with the plugin. This can be found on the plugin's page
on [Github](https://github.com/cloudogu/redmine_extended_rest_api/blob/main/src/assets/openapi.yml).
Alternatively, it is shipped with Redmine and can be found at
at `https://<fqdn>/redmine/extended_api/v1/spec`.
can be retrieved. To display them graphically, you can use e.g.
the [Swagger UI - Dogu](https://github.com/cloudogu/swaggerui) can be used.


```json
{
  "settings": {
    "app_title": "Updated Redmine"
  },
  "issueStatuses": [
    {
      "name": "New",
      "is_closed": false
    },
    {
      "name": "In Progress",
      "is_closed": false
    },
    {
      "name": "Review",
      "is_closed": false
    },
    {
      "name": "Done",
      "is_closed": true
    }
  ],
  "trackers": [
    {
      "name": "Bug",
      "default_status_name": "New",
      "description": "It's just a bug."
    },
    {
      "name": "User Story",
      "default_status_name": "New",
      "description": "It's just a User Story"
    },
    {
      "name": "Task",
      "default_status_name": "New",
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
        "Bug",
        "User Story",
        "Task"
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
      "name": "Immediate"
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


### `settings` area

Allows changing global settings.

A JSON object in the following format:

```
{
......
"<name of setting 1>":"<value 1>",
"<name of setting 2>":"<value 2>",
......
}
```

### `issueStatuses` area

Enables the creation of new ticket statuses.

```
[ 
  .....
  {
    "name": "<Name of the issue status>",
    "is_closed": <true|false>
  },
  .....
]
```

### `customFields` area

Allows to create new custom fields.

A JSON array with all custom fields to be created in the following format:

```
[
  .....
  {
    "type": "<Type of the field, e.g. 'IssueCustomField'>",
    "name": "<Name of the field>",
    "field_format": "<Format of the field e.g. 'int'>",
    "role_ids": [
      "<role id>"
    ]
  },
  .....
]
```

### `enumerations` area

Enables the creation of new enumerations.

A JSON array with all enumerations to be created in the following format:

```
[
  .....
  {
    "type":"<type of enumeration (e.g. 'IssuePriority')>",
    "name": "<name of enumeration>",
    "custom_field_values": {.
      "<id of a custom-field | name of a custom-field>":"<name of a value>"
      "<id of a custom-field | name of a custom-field>":"<name of a value>"
    }
  },
  .....
]
```

#### Special feature of `custom_field_values`.

The entry `custom_field_values` is a json object, where the key
is either the id of a custom field or the name. The name can only be used
can only be used if the custom-field has been created using the mechanism described here.
described here.

### `trackers` area

Allows the creation of new trackers.

A JSON array with all trackers to be created in the following format:

```
[
  .....
  {
    }, "name":"<tracker 1 name>",
    "default_status_id": <issue-status-id>,
    "description":"<description>"
  },
  {
    }, "name": "<tracker 2 name>",
    "default_status_name":"<issue-status-name>",
    "description":"<description>"
  },
  .....
]
```

#### Special feature of the field `default_status_name`.

Instead of the `default_status_id` field, the `default_status_name` field can be specified alternatively.
However, this will only work if the ticket status has been created beforehand via the mechanism described here.

### `workflows` area

Enables the creation of new workflows.

A JSON array with all workflows to be created in the following format:

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
      "<from-issue-status-id>": {.
        "<to-issue-status-id>": {
          "always": "1"
        }
      },
      "<from-issue-status-name>": { "always": "1" }, { "<from-issue-status-name>".
        "<to-issue-status-name>": {
          "always": "1"
        }
      }
    }
  },
  .....
]
```

#### Special feature `transitions`

This area is used to define the transitions between ticket states. For this purpose, the ID
of a ticket status as well as the name. However, the name can only be used
The name can only be used, if the ticket status has been created beforehand via the mechanism described here.



Translated with www.DeepL.com/Translator (free version)
