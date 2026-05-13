# frozen_string_literal: true

# Used by Docker Compose so `*_url` helpers (invites, Devise mailers) use the public host/port.
Rails.application.config.after_initialize do
  next if ENV["APPLICATION_HOST"].blank?

  opts = { host: ENV.fetch("APPLICATION_HOST") }
  opts[:port] = ENV["APPLICATION_PORT"].to_i if ENV["APPLICATION_PORT"].present?

  Rails.application.routes.default_url_options.merge!(opts)
  Rails.application.config.action_mailer.default_url_options = opts
end
