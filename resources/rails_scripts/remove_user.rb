require 'optparse'

module RemoveUserHelper
@options = {}
OptionParser.new do |opts|
opts.banner = "Usage: get_setting.rb [options]"

opts.on("-u", "--username USERNAME", "username")
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
opts = RemoveUserHelper::options
puts "Try to remove user %s" % opts[:username]
user = User.where(login: opts[:username]).first
puts 'User did not exist' if user.nil?
    user.destroy unless user.nil?
    puts 'User removed successfully.' unless user.nil?
    rescue Exception => error
puts '====================================================='
puts error.message
puts '====================================================='
puts 'User remove failed.'
end