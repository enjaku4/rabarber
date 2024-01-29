# frozen_string_literal: true

module Rabarber
  module Missing
    class Roles < Rabarber::Missing::Base
      private

      def check_controller_rules
        controller_rules.each do |controller, controller_rule|
          missing_roles = controller_rule.roles - all_roles if controller_rule.present?
          missing_list << Rabarber::Missing::Item.new(missing_roles, controller, nil) if missing_roles.present?
        end
      end

      def check_action_rules
        action_rules.each do |controller, controller_action_rules|
          controller_action_rules.each do |action_rule|
            missing_roles = action_rule.roles - all_roles
            if missing_roles.any?
              missing_list << Rabarber::Missing::Item.new(missing_roles, controller, action_rule.action)
            end
          end
        end
      end

      def configuration_name
        :when_roles_missing
      end

      def all_roles
        # TODO: add configuration option to enable/disable caching and set cache expiration time and race condition ttl
        Rails.cache.fetch("rabarber:roles", expires_in: 1.day, race_condition_ttl: 10.seconds) do
          @all_roles ||= Rabarber::Role.names
        end
      end
    end
  end
end
