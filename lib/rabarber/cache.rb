# frozen_string_literal: true

module Rabarber
  module Cache
    module_function

    CACHE_PREFIX = "rabarber"
    ALL_ROLES_KEY = "#{CACHE_PREFIX}:roles".freeze

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
      "#{CACHE_PREFIX}:roles_#{id}"
    end

    def clear
      Rails.cache.delete_matched(/^#{CACHE_PREFIX}/o)
    end
  end
end
