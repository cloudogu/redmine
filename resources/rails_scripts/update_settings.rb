require 'optparse'

# print a message to the console during script execution
def _puts(text)
  puts text
  # the buffer needs to be flushed so the text is printed immediately
  STDOUT.flush
end

module SettingsHelper
  @options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: update_settings.rb [options]"

    opts.on("-l", "--allow_local_users OPTION", Integer, "allow local users login")
    opts.on("-p", "--plugin PLUGIN_NAME", "name of the plugin")
  end.parse!(into: @options)

  case
  when @options[:allow_local_users]
    _puts "use passed value #{@options[:allow_local_users]} for option 'allow_local_users'"
  else
    _puts "use default value 0 for option 'allow_local_users'"
    @options[:allow_local_users] = 0
  end

  @options[:plugin] = "redmine_cas" if @options[:plugin].nil?

  def self.options
    @options
  end

  def self.available_settings
    [
      { key: :enabled, value: 1 },
      { key: :attributes_mapping, value: 'firstname=givenName&lastname=surname&mail=mail&login=username&allgroups=allgroups' },
      { key: :redmine_fqdn, value: ENV['FQDN'].to_s },
      { key: :cas_fqdn, value: ENV['FQDN'].to_s },
      { key: :cas_relative_url, value: '/cas' },
      { key: :admin_group, value: ENV['ADMIN_GROUP'].to_s },
      { key: :local_users_enabled, value: @options[:allow_local_users].to_i },
      { key: :ticket_store, value: :active_record_ticket_store }
    ]
  end

  class ActiveSupport::HashWithIndifferentAccess
    def symbolize_keys!
      transform_keys! { |key| key.to_sym rescue key }
    end
  end

  class PluginSettings
    def initialize(plugin_name)
      @plugin_name = "plugin_#{plugin_name}"
    end

    def get_setting(key)
      settings = Setting[@plugin_name]
      settings[key]
    end

    def set_setting(key, value)
      settings = Setting[@plugin_name]
      settings[key] = value
      Setting.set_from_params("#{@plugin_name}", settings)
    end

    private

    def get_plugin_settings
      Setting[@plugin_name]
    end
  end
end

begin
  opts = SettingsHelper::options
  redmine_cas_helper = SettingsHelper::PluginSettings.new opts[:plugin].to_sym
  SettingsHelper::available_settings.each do |entry|
    _puts '==============================='
    _puts "Set settings key '#{entry[:key]}'"
    _puts "Previous settings value: #{redmine_cas_helper.get_setting(entry[:key])}"
    redmine_cas_helper.set_setting(entry[:key], entry[:value])
    _puts "New settings value: #{redmine_cas_helper.get_setting(entry[:key])}"
    _puts '==============================='
  end
rescue => error
  _puts error.message
end