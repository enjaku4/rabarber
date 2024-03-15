# frozen_string_literal: true

module Rabarber
  module Logger
    module_function

    def log(log_level, message)
      Rails.logger.tagged("Rabarber") { Rails.logger.public_send(log_level, message) }
    end

    def audit(log_level, message)
      return unless Rabarber::Configuration.instance.audit_trail_enabled

      @@audit_logger ||= ::Logger.new(Rails.root.join("log/rabarber_audit.log"))
      @@audit_logger.public_send(log_level, message)
    end

    def roleable_identity(roleable, with_roles:)
      if roleable
        model_name = roleable.model_name.human
        primary_key = roleable.class.primary_key
        roleable_id = roleable.public_send(primary_key)

        roles = with_roles ? ", roles: #{roleable.roles}" : ""

        "#{model_name} with #{primary_key}: '#{roleable_id}'#{roles}"
      else
        "Unauthenticated user"
      end
    end
  end
end
