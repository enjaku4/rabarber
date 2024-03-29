# frozen_string_literal: true

module Rabarber
  module Missing
    class Actions < Rabarber::Missing::Base
      private

      def check_controller_rules
        nil
      end

      def check_action_rules
        action_rules.each do |controller, controller_action_rules|
          missing_actions = controller_action_rules.map(&:action) - controller.action_methods.map(&:to_sym)
          missing_list << Rabarber::Missing::Item.new(missing_actions, controller, nil) if missing_actions.present?
        end
      end

      def configuration_name
        :when_actions_missing
      end
    end
  end
end
