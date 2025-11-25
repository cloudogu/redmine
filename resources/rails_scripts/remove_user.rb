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
user = User.find_by_login(opts[:username])
if user
  user.destroy!
else
  puts "User did not exist"
end
rescue StandardError => e
  warn "User deletion failed: #{e.class}: #{e.message}"
  raise
end