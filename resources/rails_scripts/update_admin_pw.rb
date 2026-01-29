require 'optparse'

module UpdateUserHelper
  @options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: update_admin.rb [options]'

    opts.on('-u', '--username USERNAME', 'username')
    opts.on('-p', '--password PASSWORD', 'password')
  end.parse!(into: @options)

  @options[:username] = '' if @options[:username].nil?
  @options[:password] = '' if @options[:password].nil?

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
  opts = UpdateUserHelper::options
  puts "Try to update admin user with fresh password"
  user = User.where(login: opts[:username]).first
  puts 'Admin user did not exist' if user.nil?
  user.password = opts[:password]
  user.save! unless user.nil?
  puts 'Admin user updated successfully.' unless user.nil?
rescue Exception => error
  puts '====================================================='
  puts error.message
  puts '====================================================='
  raise 'Updating admin user failed.'
end
