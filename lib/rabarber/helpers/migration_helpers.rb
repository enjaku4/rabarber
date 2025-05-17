# frozen_string_literal: true

module Rabarber
  module MigrationHelpers
    def migrate_authorization_context!(old_context, new_context)
      roles = Rabarber::Role.where(context_type: old_context.to_s)

      raise Rabarber::InvalidArgumentError, "No roles exist in context #{old_context.inspect}" unless roles.exists?
      raise Rabarber::InvalidArgumentError, "Cannot migrate context to #{new_context.inspect}: class does not exist" unless new_context.to_s.safe_constantize

      roles.update_all(context_type: new_context.to_s)
    end

    def delete_authorization_context!(context)
      roles = Rabarber::Role.where(context_type: context.to_s)

      raise Rabarber::InvalidArgumentError, "No roles exist in context #{context.inspect}" unless roles.exists?

      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql(
            ["DELETE FROM rabarber_roles_roleables WHERE role_id IN (?)", roles.pluck(:id)]
          )
        )
        roles.delete_all
      end
    end
  end
end
