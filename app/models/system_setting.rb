class SystemSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  # SMTP settings management
  SMTP_KEYS = %w[
    smtp_address smtp_port smtp_domain smtp_username smtp_password
    smtp_authentication smtp_enable_starttls smtp_from_email smtp_reply_to_email
  ].freeze

  class << self
    def smtp_settings
      settings = {}
      SMTP_KEYS.each do |key|
        setting = find_by(key: key)
        settings[key.sub("smtp_", "")] = setting&.value
      end
      settings.compact
    end

    def update_smtp_settings(params)
      params.each do |key, value|
        next if value.blank?

        setting_key = "smtp_#{key}"
        setting = find_or_initialize_by(key: setting_key)

        if key.include?("password")
          # For passwords, use encrypted storage if available
          setting.encrypted_value = value
          setting.value = nil
        else
          setting.value = value
          setting.encrypted_value = nil
        end

        setting.save!
      end

      # Update ActionMailer configuration
      update_action_mailer_config
    end

    def get_setting(key)
      setting = find_by(key: key)
      return nil unless setting

      setting.encrypted_value.present? ? setting.encrypted_value : setting.value
    end

    def redis_connected?
      return false unless defined?(Redis)

      begin
        # Try to connect to Redis if configured
        if ENV["REDIS_URL"].present?
          redis = Redis.new(url: ENV["REDIS_URL"])
          redis.ping == "PONG"
        else
          false
        end
      rescue => e
        Rails.logger.warn "Redis connection failed: #{e.message}"
        false
      end
    end

    private

    def update_action_mailer_config
      smtp_settings = self.smtp_settings
      return if smtp_settings.empty?

      Rails.application.configure do
        config.action_mailer.smtp_settings = {
          address: smtp_settings["address"],
          port: smtp_settings["port"]&.to_i || 587,
          domain: smtp_settings["domain"],
          user_name: smtp_settings["username"],
          password: get_setting("smtp_password"),
          authentication: smtp_settings["authentication"] || "plain",
          enable_starttls_auto: smtp_settings["enable_starttls"] == "true"
        }.compact

        config.action_mailer.default_options = {
          from: smtp_settings["from_email"],
          reply_to: smtp_settings["reply_to_email"]
        }.compact
      end
    end
  end
end
