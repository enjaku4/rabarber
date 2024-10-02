# frozen_string_literal: true

require_relative "../logger"

module Rabarber
  module Audit
    module Events
      class Base
        attr_reader :roleable, :specifics

        def self.trigger(roleable, specifics)
          new(roleable, specifics).send(:log)
        end

        private

        def initialize(roleable, specifics)
          @roleable = roleable
          @specifics = specifics
        end

        def log
          Rabarber::Audit::Logger.log(log_level, message)
        end

        def log_level
          raise NotImplementedError
        end

        def message
          raise NotImplementedError
        end

        def identity
          roleable.log_identity
        end

        def human_context
          case context
          in { context_type: nil, context_id: nil } then "Global"
          in { context_type: context_type, context_id: nil } then context_type
          in { context_type: context_type, context_id: context_id } then "#{context_type}##{context_id}"
          else raise "Unexpected context: #{context}"
          end
        end
      end
    end
  end
end
