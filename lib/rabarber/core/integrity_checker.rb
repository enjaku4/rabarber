# frozen_string_literal: true

module Rabarber
  module Core
    module IntegrityChecker
      extend self

      def run!
        check_for_missing_class_context
        check_for_orphaned_grant_access
        check_for_missing_actions
        prune_missing_instance_context
      end

      private

      def check_for_missing_class_context
        Rabarber::Role.where.not(context_type: nil).distinct.pluck(:context_type).each do |context_class|
          context_class.constantize
        rescue NameError => e
          raise Rabarber::Error, "Context not found: class #{e.name} may have been renamed or deleted"
        end
      end

      def check_for_orphaned_grant_access
        controllers = (
          Rabarber::Core::Permissions.controller_rules.keys | Rabarber::Core::Permissions.action_rules.keys
        ).reject do |controller|
          controller._process_action_callbacks.any? { |callback| callback.kind == :before && callback.filter == :authorize }
        end

        return if controllers.empty?

        raise(
          Rabarber::Error,
          "The following controllers use `grant_access` but are missing `before_action :authorize`:\n#{controllers.map(&:to_s).to_yaml}"
        )
      end

      def check_for_missing_actions
        missing_actions_list = Rabarber::Core::Permissions.action_rules.filter_map do |controller, actions|
          missing_actions = actions.keys - controller.action_methods.map(&:to_sym)
          { controller.name => missing_actions } if missing_actions.any?
        end

        return if missing_actions_list.empty?

        raise(
          Rabarber::Error,
          "The following actions were passed to `grant_access` but are not defined in the controller:\n#{missing_actions_list.to_yaml}"
        )
      end

      def prune_missing_instance_context
        ids = Rabarber::Role.where.not(context_id: nil).includes(:context).filter_map do |role|
          role.context
          nil
        rescue ActiveRecord::RecordNotFound
          role.id
        end

        return if ids.empty?

        ActiveRecord::Base.transaction do
          ActiveRecord::Base.connection.execute("DELETE FROM rabarber_roles_roleables WHERE role_id IN (#{ids.join(",")})")
          Rabarber::Role.where(id: ids).delete_all
        end
      end
    end
  end
end
