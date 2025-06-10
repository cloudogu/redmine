# Copy this file to additional_environment.rb and add any statements
# that need to be passed to the Rails::Initializer.  `config` is
# available in this context.
#
# Example:
#
#   config.log_level = :debug
#   ...
#

require 'rack'
require 'rack/query_parser'

# This is the rack 2.2.17 syntax
# adjust the call when upgrading rack
{{ if .Config.Get "rack/params_limit" }}
Rack::Utils.default_query_parser.instance_variable_set(:@params_limit, {{ .Config.Get "rack/params_limit" }})
{{ end }}

{{ if .Config.Get "rack/bytesize_limit" }}
Rack::Utils.default_query_parser.instance_variable_set(:@bytesize_limit, {{ .Config.Get "rack/bytesize_limit" }})
{{ end }}

 # log to STDOUT (https://github.com/docker-library/redmine/issues/108)
logger           = ActiveSupport::Logger.new(STDOUT)
logger.formatter = config.log_formatter
config.logger = ActiveSupport::TaggedLogging.new(logger)
config.log_level = {{ .Env.Get "REDMINE_LOGLEVEL" }}
