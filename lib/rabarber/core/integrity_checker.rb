# frozen_string_literal: true

module Rabarber
  module Core
    module IntegrityChecker
      extend self

      def run!
        check_for_missing_class_context
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

      # TODO: maybe context pruning should be a part of public API
      # TODO: although it would be cool if orphaned instance context roles could be deleted automatically along with the context itself
      # TODO: maybe integrity checker is not needed at all, and developers should handle all by themselves
      def prune_missing_instance_context
        ids = Rabarber::Role.where.not(context_id: nil).includes(:context).filter_map do |role|
          role.context
          nil
        rescue ActiveRecord::RecordNotFound
          role.id
        end

        return if ids.empty?

        ActiveRecord::Base.transaction do
          ActiveRecord::Base.connection.execute(
            ActiveRecord::Base.sanitize_sql(
              ["DELETE FROM rabarber_roles_roleables WHERE role_id IN (?)", ids]
            )
          )
          Rabarber::Role.where(id: ids).delete_all
        end
      end
    end
  end
end
