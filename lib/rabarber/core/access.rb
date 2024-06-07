# frozen_string_literal: true

module Rabarber
  module Core
    module Access
      def access_granted?(roles, action, controller_instance)
        controller_accessible?(roles, controller_instance) || action_accessible?(roles, action, controller_instance)
      end

      def controller_accessible?(roles, controller_instance)
        controller_rules.any? do |rule_controller, rule|
          controller_instance.class <= rule_controller && rule.verify_access(roles, controller_instance)
        end
      end

      def action_accessible?(roles, action, controller_instance)
        action_rules[controller_instance.class].any? do |rule|
          rule.action == action && rule.verify_access(roles, controller_instance)
        end
      end
    end
  end
end
