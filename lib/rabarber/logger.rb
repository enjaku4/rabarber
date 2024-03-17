# frozen_string_literal: true

module Rabarber
  class Logger
    include Singleton

    attr_reader :rails_logger, :audit_logger

    def initialize
      @rails_logger = Rails.logger
      @audit_logger = ::Logger.new(Rails.root.join("log/rabarber_audit.log"))
    end

    class << self
      def log(log_level, message)
        instance.rails_logger.tagged("Rabarber") { instance.rails_logger.public_send(log_level, message) }
      end

      def audit(log_level, message)
        return unless Rabarber::Configuration.instance.audit_trail_enabled

        instance.audit_logger.public_send(log_level, message)
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
end
