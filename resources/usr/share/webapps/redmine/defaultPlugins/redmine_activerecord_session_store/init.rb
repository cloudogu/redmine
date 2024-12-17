Redmine::Plugin.register :redmine_activerecord_session_store do
  name 'Redmine ActiveRecord Session Store plugin'
  author 'Original: Nils Caspar/Forked: robert.auer@cloudogu.com'
  description 'This plugin teaches Redmine to use ActiveRecord as session store.'
  version '0.2.0'
  url 'https://github.com/cloudogu/redmine_activerecord_session_store'
  author_url 'https://cloudogu.com/'

  RedmineApp::Application.config.session_store :active_record_store unless Module.const_defined?(:RedmineExtensions)
end
