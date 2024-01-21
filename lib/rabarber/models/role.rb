# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    validates :name, presence: true, uniqueness: true, format: { with: RoleNames::REGEX }

    has_and_belongs_to_many :rabarber_groups, class_name: "Rabarber::Group", join_table: "rabarber_groups_roles"

    def self.names
      pluck(:name).map(&:to_sym)
    end
  end
end
