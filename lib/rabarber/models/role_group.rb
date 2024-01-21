# frozen_string_literal: true

module Rabarber
  class RoleGroup < ActiveRecord::Base
    self.table_name = "rabarber_role_groups"

    # TODO: RoleNames::REGEX?
    validates :name, presence: true, uniqueness: true, format: { with: RoleNames::REGEX }

    has_many :rabarber_roles

    # TODO: Maybe to include HasRoles 👀

    # TODO: convenient interface for managing groups and roles
  end
end
