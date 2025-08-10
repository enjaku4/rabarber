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

      # TODO: pruning should be a part of public API and run manually by developers
      # TODO: missing context class should still raise an error automatically and fail fast
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
