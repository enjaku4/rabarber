# frozen_string_literal: true

module Rabarber
  module Core
    class IntegrityChecker
      attr_reader :controller

      def initialize(controller = nil)
        @controller = controller
      end

      def run!
        # TODO: raise if class context is missing in any role
        # TODO: prune roles with missing instance context
        return if missing_list.empty?

        raise(
          Rabarber::Error,
          "Following actions were passed to 'grant_access' method but are not defined in the controller:\n#{missing_list.to_yaml}"
        )
      end

      private

      def missing_list
        @missing_list ||= action_rules.each_with_object([]) do |(controller, hash), arr|
          missing_actions = hash.keys - controller.action_methods.map(&:to_sym)
          arr << { controller => missing_actions } if missing_actions.any?
        end
      end

      def action_rules
        rules = Rabarber::Core::Permissions.action_rules
        controller ? rules.slice(controller) : rules
      end
    end
  end
end
