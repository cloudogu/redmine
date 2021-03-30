# Copy this file to additional_environment.rb and add any statements
# that need to be passed to the Rails::Initializer.  `config` is
# available in this context.
#
# Example:
#
#   config.log_level = :debug
#   ...
#

 # log to STDOUT (https://github.com/docker-library/redmine/issues/108)
logger           = ActiveSupport::Logger.new(STDOUT)
logger.formatter = config.log_formatter
config.logger = ActiveSupport::TaggedLogging.new(logger)
config.log_level = {{ .Env.Get "REDMINE_LOGLEVEL" }}
