# frozen_string_literal: true

module Rabarber
  module Core
    class IntegrityChecker
      attr_reader :controller

      def initialize(controller = nil)
        @controller = controller
      end

      def run!
        check_for_missing_context_class
        check_for_missing_actions
        prune_missing_instance_context_roles
      end

      private

      def check_for_missing_context_class
        # TODO: tests
        Rabarber::Role.where.not(context_type: nil).distinct.pluck(:context_type).each do |context_class|
          context_class.constantize
        rescue NameError => e
          raise Rabarber::Error, "Context not found: class #{e.name} was renamed or deleted"
        end
      end

      def check_for_missing_actions
        return if missing_actions_list.empty?

        raise(
          Rabarber::Error,
          "Following actions were passed to 'grant_access' method but are not defined in the controller:\n#{missing_actions_list.to_yaml}"
        )
      end

      def missing_actions_list
        @missing_actions_list ||= action_rules.each_with_object([]) do |(controller, hash), arr|
          missing_actions = hash.keys - controller.action_methods.map(&:to_sym)
          arr << { controller => missing_actions } if missing_actions.any?
        end
      end

      def action_rules
        rules = Rabarber::Core::Permissions.action_rules
        controller ? rules.slice(controller) : rules
      end

      def prune_missing_instance_context_roles
        # TODO: tests
        ids = Rabarber::Role.where.not(context_id: nil).includes(:context).filter_map do |role|
          role.context
          false
        rescue ActiveRecord::RecordNotFound
          role.id
        end

        ActiveRecord::Base.transaction do
          ActiveRecord::Base.connection.execute("DELETE FROM rabarber_roles_roleables WHERE role_id IN (#{ids.join(",")})")
          Rabarber::Role.where(id: ids).delete_all
        end
      end
    end
  end
end
