# Default setup is given for MySQL with ruby1.9.
# Examples for PostgreSQL, SQLite3 and SQL Server can be found at the end.
# Line indentation must be 2 spaces (no tabs).

production:
  adapter: mysql2
  database: {{ .Config.GetAndDecrypt "sa-mariadb/database" }}
  host: mariadb
  username: {{ .Config.GetAndDecrypt "sa-mariadb/username" }}
  password: {{ .Config.GetAndDecrypt "sa-mariadb/password" }}
  encoding: utf8mb4

#development:
#  adapter: mysql2
#  database: redmine_development
#  host: localhost
#  username: root
#  password: ""
#  encoding: utf8

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
#test:
#  adapter: mysql2
#  database: redmine_test
#  host: localhost
#  username: root
#  password: ""
#  encoding: utf8

# PostgreSQL configuration example
#production:
#  adapter: postgresql
#  database: redmine
#  host: localhost
#  username: postgres
#  password: "postgres"

# SQLite3 configuration example
#production:
#  adapter: sqlite3
#  database: db/redmine.sqlite3

# SQL Server configuration example
#production:
#  adapter: sqlserver
#  database: redmine
#  host: localhost
#  username: jenkins
#  password: jenkins
