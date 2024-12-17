# Wrap in to_prepare to comply with Rails 7
Rails.application.config.to_prepare do
  Rails.application.config.session_store :active_record_store
end
