# frozen_string_literal: true

module Rabarber
  class Group < ActiveRecord::Base
    self.table_name = "rabarber_groups"

    include HasRoles::Internal

    validates :name, presence: true, uniqueness: true, format: { with: Input::Roles::REGEX }

    has_and_belongs_to_many :rabarber_roles, class_name: "Rabarber::Role", join_table: "rabarber_groups_roles"
  end
end
