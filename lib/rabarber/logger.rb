# frozen_string_literal: true

module Rabarber
  module Logger
    module_function

    def log(log_level, message)
      Rails.logger.tagged("Rabarber") { Rails.logger.public_send(log_level, message) }
    end

    def audit(log_level, message)
      return unless Rabarber::Configuration.instance.audit_trail_enabled

      ::Logger.new(Rails.root.join("log/rabarber_audit.log")).public_send(log_level, message)
    end
  end
end
