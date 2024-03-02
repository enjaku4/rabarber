# frozen_string_literal: true

module Rabarber
  module Core
    module Access
      def access_granted?(roles, controller, action, dynamic_rule_receiver)
        controller_accessible?(roles, controller, dynamic_rule_receiver) ||
          action_accessible?(roles, controller, action, dynamic_rule_receiver)
      end

      def controller_accessible?(roles, controller, dynamic_rule_receiver)
        accessible_controllers(roles, dynamic_rule_receiver).any? do |accessible_controller|
          controller <= accessible_controller
        end
      end

      def action_accessible?(roles, controller, action, dynamic_rule_receiver)
        action_rules[controller].any? { |rule| rule.verify_access(roles, dynamic_rule_receiver, action) }
      end

      private

      def accessible_controllers(roles, dynamic_rule_receiver)
        controller_rules.select { |_, rule| rule.verify_access(roles, dynamic_rule_receiver) }.keys
      end
    end
  end
end
