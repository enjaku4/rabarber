# frozen_string_literal: true

module Rabarber
  module Core
    class PermissionsIntegrityChecker
      attr_reader :controller

      def initialize(controller = nil)
        @controller = controller
      end

      def run!
        return if missing_list.empty?

        raise(
          Rabarber::Error,
          "Following actions are passed to 'grant_access' method, but are not defined in the controller: #{missing_list}"
        )
      end

      private

      def missing_list
        @missing_list ||= action_rules.each_with_object([]) do |(controller, rules), arr|
          missing_actions = rules.map(&:action) - controller.action_methods.map(&:to_sym)
          arr << { controller => missing_actions } if missing_actions.any?
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
