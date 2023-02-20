require 'optparse'

module CreateAdminHelper
  @options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: get_setting.rb [options]"

    opts.on("-u", "--username USERNAME", "username")
    opts.on("-p", "--password PASSWORD", "password")
  end.parse!(into: @options)

  @options[:username] = "" if @options[:username].nil?

  def self.options
    @options
  end

  class ActiveSupport::HashWithIndifferentAccess
    def symbolize_keys!
      transform_keys! { |key| key.to_sym rescue key }
    end
  end
end

begin
  opts = CreateAdminHelper::options
  username = opts[:username]
  password = opts[:password]
  puts "Try to create user '%s'" % username
  user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option, :admin => true)
  user.login = username
  user.password = password
  user.password_confirmation = password
  user.lastname = username
  user.firstname = username
  user.mail = "#{username}@#{username}.de"
  user.save!
  puts 'User saved successfully.'
rescue Exception => error
  puts '================================================'
  puts error.message
  puts '================================================'
  raise 'User was not saved.'
end
