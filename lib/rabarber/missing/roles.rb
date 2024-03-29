# frozen_string_literal: true

module Rabarber
  module Missing
    class Roles < Rabarber::Missing::Base
      private

      def check_controller_rules
        controller_rules.each do |controller, controller_rule|
          missing_roles = controller_rule.roles - all_roles
          missing_list << Rabarber::Missing::Item.new(missing_roles, controller, nil) unless missing_roles.empty?
        end
      end

      def check_action_rules
        action_rules.each do |controller, controller_action_rules|
          controller_action_rules.each do |action_rule|
            missing_roles = action_rule.roles - all_roles
            missing_list << Rabarber::Missing::Item.new(missing_roles, controller, action_rule.action) if missing_roles.any?
          end
        end
      end

      def configuration_name
        :when_roles_missing
      end

      def all_roles
        @all_roles ||= Rabarber::Cache.fetch(
          Rabarber::Cache::ALL_ROLES_KEY, expires_in: 1.day, race_condition_ttl: 10.seconds
        ) { Rabarber::Role.names }
      end
    end
  end
end
