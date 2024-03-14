# frozen_string_literal: true

module Rabarber
  module Cache
    module_function

    ALL_ROLES_KEY = "rabarber:roles"

    def fetch(key, options, &)
      enabled? ? Rails.cache.fetch(key, options, &) : yield
    end

    def delete(*keys)
      Rails.cache.delete_multi(keys) if enabled?
    end

    def enabled?
      Rabarber::Configuration.instance.cache_enabled
    end

    def key_for(id)
      "rabarber:roles_#{id}"
    end

    def clear
      Rails.cache.delete_matched(/^rabarber/)
    end
  end
end
