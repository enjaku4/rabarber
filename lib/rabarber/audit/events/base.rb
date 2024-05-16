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
          raise ArgumentError, "Roleable is required for #{self.class} event" if roleable.nil? && !nil_roleable_allowed?

          @roleable = roleable
          @specifics = specifics
        end

        def nil_roleable_allowed?
          raise NotImplementedError
        end

        def log
          Rabarber::Audit::Logger.log(log_level, message)
        end

        def log_level
          raise NotImplementedError
        end

        def message
          # TODO: it seems the log messages will be changed significantly, worth mentioning in changelog
          raise NotImplementedError
        end

        def identity
          if roleable
            model_name = roleable.model_name.human
            roleable_id = roleable.public_send(roleable.class.primary_key)

            "#{model_name}##{roleable_id}"
          else
            "Unauthenticated #{Rabarber::HasRoles.roleable_class.model_name.human.downcase}"
          end
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
