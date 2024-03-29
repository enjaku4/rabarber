# frozen_string_literal: true

require "singleton"

module Rabarber
  module Audit
    class Logger
      include Singleton

      attr_reader :logger

      def initialize
        @logger = ::Logger.new(Rails.root.join("log/rabarber_audit.log"))
      end

      def self.log(log_level, message)
        return unless Rabarber::Configuration.instance.audit_trail_enabled

        instance.logger.public_send(log_level, message)
      end
    end
  end
end
