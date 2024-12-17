Rails.application.configure do
  config.session_store :active_record_store
end

RedmineExtensions::Reloader.to_prepare do
end
