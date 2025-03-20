# frozen_string_literal: true

require "digest/sha2"

module Rabarber
  module Core
    module Cache
      extend self

      def fetch(key, &)
        return yield unless enabled?

        Rails.cache.fetch(prepare_key(key), expires_in: 1.hour, race_condition_ttl: 5.seconds, &)
      end

      def delete(*keys)
        return unless enabled?

        Rails.cache.delete_multi(keys.map { prepare_key(_1) }) if keys.any?
      end

      def enabled?
        Rabarber::Configuration.instance.cache_enabled
      end

      def clear
        Rails.cache.delete_matched(/^#{CACHE_PREFIX}/o)
      end

      CACHE_PREFIX = "rabarber"
      private_constant :CACHE_PREFIX

      private

      def prepare_key(key)
        "#{CACHE_PREFIX}:#{Digest::SHA2.hexdigest(Marshal.dump(key))}"
      end
    end
  end

  module Cache
    delegate :clear, to: :"Rabarber::Core::Cache"
    module_function :clear
  end
end
