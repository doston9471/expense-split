# frozen_string_literal: true

# Public URL host for route helpers, Devise, and mailers.
# Prefer APPLICATION_HOST; on Heroku fall back to HEROKU_APP_NAME.herokuapp.com when unset.
Rails.application.config.after_initialize do
  host = ENV["APPLICATION_HOST"].presence
  host ||= "#{ENV['HEROKU_APP_NAME']}.herokuapp.com" if ENV["HEROKU_APP_NAME"].present?
  next if host.blank?

  host = host.sub(%r{\Ahttps?://}i, "").split("/").first
  opts = { host: host }
  opts[:port] = ENV["APPLICATION_PORT"].to_i if ENV["APPLICATION_PORT"].present?
  opts[:protocol] = "https" if ENV["DYNO"].present?

  Rails.application.routes.default_url_options.merge!(opts)
  Rails.application.config.action_mailer.default_url_options = opts
end
