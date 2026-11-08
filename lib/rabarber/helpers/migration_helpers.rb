# frozen_string_literal: true

module Rabarber
  module MigrationHelpers
    def migrate_authorization_context!(old_context, new_context)
      old_context_type = Rabarber::Inputs::NonEmptyString.new(old_context).process
      new_context_type = Rabarber::Inputs::NonEmptyString.new(new_context).process

      Rabarber::Role.where(context_type: old_context_type).update_all(context_type: new_context_type)
    end

    def delete_authorization_context!(context)
      context_type = Rabarber::Inputs::NonEmptyString.new(context).process

      Rabarber::Role.delete_with_assignments(Rabarber::Role.where(context_type:))
    end
  end
end
