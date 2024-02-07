# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    validates :name, presence: true, uniqueness: true, format: { with: Rabarber::Input::Roles::REGEX }

    after_commit :delete_cache

    def self.names
      pluck(:name).map(&:to_sym)
    end

    private

    def delete_cache
      Rabarber::Cache.delete(Rabarber::Cache::ALL_ROLES_KEY)
    end
  end
end
