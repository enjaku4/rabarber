# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    NAME_REGEX = /\A[a-z0-9_]+\z/

    validates :name, presence: true, uniqueness: true, format: { with: NAME_REGEX }

    def self.names
      pluck(:name).map(&:to_sym)
    end
  end
end
