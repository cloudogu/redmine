development:
  secret_key_base:

test:
  secret_key_base:

production:
  secret_key_base: {{ .Config.GetAndDecrypt "secret_key_base" }}
