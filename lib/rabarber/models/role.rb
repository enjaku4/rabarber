# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    validates :name, presence: true, uniqueness: true

    def self.names
      pluck(:name).map(&:to_sym)
    end
  end
end
