# frozen_string_literal: true

module Rabarber
  module Core
    module Access
      def access_granted?(roles, controller, action, controller_instance)
        controller_accessible?(roles, controller, controller_instance) ||
          action_accessible?(roles, controller, action, controller_instance)
      end

      def controller_accessible?(roles, controller, controller_instance)
        controller_rules.any? do |rule_controller, rule|
          controller <= rule_controller && rule.verify_access(roles, controller_instance)
        end
      end

      def action_accessible?(roles, controller, action, controller_instance)
        action_rules[controller].any? do |rule|
          rule.action == action && rule.verify_access(roles, controller_instance)
        end
      end
    end
  end
end
