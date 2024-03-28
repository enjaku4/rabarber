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

        def roleable_identity(with_roles:)
          if roleable
            model_name = roleable.model_name.human
            primary_key = roleable.class.primary_key
            roleable_id = roleable.public_send(primary_key)

            roles = with_roles ? ", roles: #{roleable.roles}" : ""

            "#{model_name} with #{primary_key}: '#{roleable_id}'#{roles}"
          else
            "Unauthenticated #{Rabarber::HasRoles.roleable_class.model_name.human.downcase}"
          end
        end
      end
    end
  end
end
