# frozen_string_literal: true

module Rabarber
  module Core
    module Access
      def access_granted?(roleable, action, controller_instance)
        controller_accessible?(roleable, controller_instance) || action_accessible?(roleable, action, controller_instance)
      end

      def controller_accessible?(roleable, controller_instance)
        controller_rules.any? do |controller, rules|
          controller_instance.is_a?(controller) && rules.any? { _1.verify_access(roleable, controller_instance) }
        end
      end

      def action_accessible?(roleable, action, controller_instance)
        action_rules[controller_instance.class][action].any? { _1.verify_access(roleable, controller_instance) }
      end
    end
  end
end
