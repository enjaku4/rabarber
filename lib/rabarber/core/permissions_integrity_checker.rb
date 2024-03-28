# frozen_string_literal: true

module Rabarber
  module Core
    class PermissionsIntegrityChecker
      attr_reader :controller

      def initialize(controller = nil)
        @controller = controller
      end

      def run
        missing_list = find_missing

        return if missing_list.empty?

        raise(
          Rabarber::Error,
          "Following actions are passed to 'grant_access' method but are not defined in the controller: #{missing_list}"
        )
      end

      private

      def find_missing
        action_rules.each_with_object([]) do |(controller, controller_action_rules), missing_list|
          missing_actions = controller_action_rules.map(&:action) - controller.action_methods.map(&:to_sym)
          missing_list << { controller => missing_actions } if missing_actions.any?
        end
      end

      def action_rules
        if controller
          Rabarber::Core::Permissions.action_rules.slice(controller)
        else
          Rabarber::Core::Permissions.action_rules
        end
      end
    end
  end
end
