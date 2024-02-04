# frozen_string_literal: true

module Rabarber
  module Cache
    module_function

    ALL_ROLES_KEY = "rabarber:roles"

    def fetch(key, options, &block)
      enabled? ? Rails.cache.fetch(key, options, &block) : yield
    end

    def delete(key)
      Rails.cache.delete(key) if enabled?
    end

    def enabled?
      Rabarber::Configuration.instance.cache_enabled
    end

    def key_for(record)
      "rabarber:roles_#{record.public_send(record.class.primary_key)}"
    end
  end
end
