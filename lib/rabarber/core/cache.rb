# frozen_string_literal: true

require "digest/md5"

module Rabarber
  module Core
    module Cache
      module_function

      def fetch(roleable_id, scope, &)
        return yield unless enabled?

        Rails.cache.fetch(prepare_key(roleable_id, scope), expires_in: 1.hour, race_condition_ttl: 5.seconds, &)
      end

      def delete(*pairs)
        return unless enabled?

        Rails.cache.delete_multi(pairs.map { |roleable_id, scope| prepare_key(roleable_id, scope) }) if pairs.any?
      end

      def enabled?
        Rabarber::Configuration.cache_enabled
      end

      def clear
        Rails.cache.delete_matched(/^#{CACHE_PREFIX}/o)
      end

      def prepare_key(roleable_id, scope)
        "#{CACHE_PREFIX}:#{roleable_id}:#{Digest::MD5.base64digest(Marshal.dump(scope))}"
      end

      CACHE_PREFIX = "rabarber"
      private_constant :CACHE_PREFIX
    end
  end

  module Cache
    delegate :clear, to: :"Rabarber::Core::Cache"
    module_function :clear
  end
end
