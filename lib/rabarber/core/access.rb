# frozen_string_literal: true

module Rabarber
  module Core
    module Access
      def access_granted?(roles, controller, action, dynamic_rule_receiver)
        controller_accessible?(roles, controller, dynamic_rule_receiver) ||
          action_accessible?(roles, controller, action, dynamic_rule_receiver)
      end

      def controller_accessible?(roles, controller, dynamic_rule_receiver)
        controller_rules.any? do |rule_controller, rule|
          controller <= rule_controller && rule.verify_access(roles, dynamic_rule_receiver)
        end
      end

      def action_accessible?(roles, controller, action, dynamic_rule_receiver)
        action_rules[controller].any? do |rule|
          rule.action == action && rule.verify_access(roles, dynamic_rule_receiver)
        end
      end
    end
  end
end
