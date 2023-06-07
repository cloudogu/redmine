require 'redmine'

Redmine::Plugin.register :redmine_cas do
  name 'Redmine CAS plugin'
  author 'Robert Auer (Cloudogu GmbH)'
  description 'Plugin to CASify your Redmine installation.'
  version '2.0.0'
  url 'https://github.com/cloudogu/redmine_cas'

  settings :default => {
    'enabled' => 1,
    'attributes_mapping' => 'firstname=givenName&lastname=surname&mail=mail&login=username&allgroups=allgroups',
    'redmine_fqdn' => '192.168.56.2',
    'cas_fqdn' => '192.168.56.2',
    'cas_relative_url' => '/cas',
    'local_users_enabled' => 1,
    'admin_group' => 'admin',
  }, :partial => 'redmine_cas/settings'

  # http://sundivenetworks.com/archive/2021/tried-to-load-unspecified-class-time-psych-disallowedclass.html
  Psych::ClassLoader::ALLOWED_PSYCH_CLASSES = [ Time ]

  module Psych
    class ClassLoader
      ALLOWED_PSYCH_CLASSES = [] unless defined? ALLOWED_PSYCH_CLASSES
      class Restricted < ClassLoader
        def initialize classes, symbols
          @classes = classes + Psych::ClassLoader::ALLOWED_PSYCH_CLASSES.map(&:to_s)
          @symbols = symbols
          super()
        end
      end
    end
  end

  ApplicationController.send(:include, RedmineCas::ApplicationControllerPatch)
  AccountController.send(:include, RedmineCas::AccountControllerPatch)
  User.send(:include, RedmineCas::UserPatch)

  ActionDispatch::Callbacks.before do
    RedmineCas.setup!
  end

end
