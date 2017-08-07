# Copy this file to additional_environment.rb and add any statements
# that need to be passed to the Rails::Initializer.  `config` is
# available in this context.
#
# Example:
#
#   config.log_level = :debug
#   ...
#

# configure redmine to log to stdout
config.logger = Logger.new(STDOUT)
config.log_level = :info
