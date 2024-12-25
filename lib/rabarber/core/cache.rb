# frozen_string_literal: true

require "digest/sha2"

module Rabarber
  module Core
    module Cache
      CACHE_PREFIX = "rabarber"
      private_constant :CACHE_PREFIX

      module_function

      def fetch(roleable_id, context:, &block)
        return yield unless enabled?

        Rails.cache.fetch(key_for(roleable_id, context), expires_in: 1.hour, race_condition_ttl: 5.seconds, &block)
      end

      def delete(*roleable_ids, context:)
        return unless enabled?

        keys = roleable_ids.map { |roleable_id| key_for(roleable_id, context) }
        Rails.cache.delete_multi(keys) if keys.any?
      end

      def enabled?
        Rabarber::Configuration.instance.cache_enabled
      end

      def clear
        Rails.cache.delete_matched(/^#{CACHE_PREFIX}/o)
      end

      def key_for(id, context)
        "#{CACHE_PREFIX}:#{Digest::SHA2.hexdigest("#{id}#{context.fetch(:context_type)}#{context.fetch(:context_id)}")}"
      end
    end
  end

  module Cache
    module_function

    def clear
      Rabarber::Core::Cache.clear
    end
  end
end
