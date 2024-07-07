# frozen_string_literal: true

require "digest/sha2"

module Rabarber
  module Core
    module Cache
      module_function

      CACHE_PREFIX = "rabarber"
      private_constant :CACHE_PREFIX

      def fetch(roleable_id, context:, &block)
        if enabled?
          Rails.cache.fetch(key_for(roleable_id, context), expires_in: 1.hour, race_condition_ttl: 5.seconds, &block)
        else
          yield
        end
      end

      def delete(*roleable_ids, context:)
        keys = roleable_ids.map { |roleable_id| key_for(roleable_id, context) }
        Rails.cache.delete_multi(keys) if enabled? && keys.any?
      end

      def enabled?
        Rabarber::Configuration.instance.cache_enabled
      end

      def clear
        Rails.cache.delete_matched(/^#{CACHE_PREFIX}/o)
      end

      def key_for(id, context)
        "#{CACHE_PREFIX}:#{Digest::SHA2.hexdigest("#{id}#{context}")}"
      end
    end
  end

  module Cache
    def clear
      Rabarber::Core::Cache.clear
    end
    module_function :clear
  end
end
