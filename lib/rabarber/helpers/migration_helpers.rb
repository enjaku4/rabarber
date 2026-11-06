# frozen_string_literal: true

module Rabarber
  module MigrationHelpers
    def migrate_authorization_context!(old_context, new_context)
      old_context_type = Rabarber::Inputs::NonEmptyString.new(old_context).process
      new_context_type = Rabarber::Inputs::NonEmptyString.new(new_context).process

      Rabarber::Role.where(context_type: old_context_type).update_all(context_type: new_context_type)
    end

    def delete_authorization_context!(context)
      roles = Rabarber::Role.where(context_type: Rabarber::Inputs::NonEmptyString.new(context).process)

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
