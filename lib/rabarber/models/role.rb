# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    validates :name, presence: true, uniqueness: true, format: { with: Rabarber::Input::Roles::REGEX }

    after_commit :invalidate_cache

    def self.names
      pluck(:name).map(&:to_sym)
    end

    private

    def invalidate_cache
      # TODO: cache key should probably be specified somewhere else and reused
      Rails.cache.delete("rabarber:roles")
    end
  end
end
