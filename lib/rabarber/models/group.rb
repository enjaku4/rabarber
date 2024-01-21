# frozen_string_literal: true

module Rabarber
  class Group < ActiveRecord::Base
    self.table_name = "rabarber_groups"

    validates :name, presence: true, uniqueness: true, format: { with: Input::Roles::REGEX }

    has_and_belongs_to_many :rabarber_roles, class_name: "Rabarber::Role", join_table: "rabarber_groups_roles"

    # TODO: convenient interface for managing groups and roles
    # TODO: a mixin created out of HasRoles which will be included in both HasRoles and Group might be useful
  end
end
