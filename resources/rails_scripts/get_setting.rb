require 'optparse'
require 'json'

def _puts(text)
  puts text
  STDOUT.flush
end

module SettingsHelper
  @options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: get_setting.rb [options]"

    opts.on("-k", "--key SETTING_KEY", "key of the plugin setting")
    opts.on("-p", "--plugin PLUGIN_NAME", "name of the plugin")
  end.parse!(into: @options)

  @options[:plugin] = "redmine_cas" if @options[:plugin].nil?

  def self.options
    @options
  end

  class PluginSettings
    def initialize(plugin_name)
      @plugin_name = "plugin_#{plugin_name}"
    end

    def get_setting(key)
      settings = Setting[@plugin_name]
      settings[key]
    end
  end
end

begin
  opts = SettingsHelper::options
  redmine_cas_helper = SettingsHelper::PluginSettings.new opts[:plugin].to_sym
  result = {result: redmine_cas_helper.get_setting(opts[:key].to_sym)}
  _puts JSON.generate(result)
rescue => error
  _puts error.message
end
