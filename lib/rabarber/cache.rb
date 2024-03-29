# frozen_string_literal: true

module Rabarber
  module Cache
    extend self

    CACHE_PREFIX = "rabarber"
    private_constant :CACHE_PREFIX

    def fetch(roleable_id, options = { expires_in: 1.hour, race_condition_ttl: 5.seconds }, &)
      enabled? ? Rails.cache.fetch(key_for(roleable_id), **options, &) : yield
    end

    def delete(*roleable_ids)
      keys = roleable_ids.map { |roleable_id| key_for(roleable_id) }
      Rails.cache.delete_multi(keys) if enabled? && keys.any?
    end

    def enabled?
      Rabarber::Configuration.instance.cache_enabled
    end

    def clear
      Rails.cache.delete_matched(/^#{CACHE_PREFIX}/o)
    end

    private

    def key_for(id)
      "#{CACHE_PREFIX}:roles_#{id}"
    end
  end
end
