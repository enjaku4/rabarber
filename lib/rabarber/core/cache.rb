# frozen_string_literal: true

require "digest/sha2"

module Rabarber
  module Core
    module Cache
      module_function

      def fetch(uid, &)
        return yield unless enabled?

        Rails.cache.fetch(prepare_key(uid), expires_in: 1.hour, race_condition_ttl: 5.seconds, &)
      end

      def delete(*uids)
        return unless enabled?

        Rails.cache.delete_multi(uids.map { prepare_key(_1) }) if uids.any?
      end

      def enabled?
        Rabarber::Configuration.cache_enabled
      end

      def clear
        Rails.cache.delete_matched(/^#{CACHE_PREFIX}/o)
      end

      def prepare_key(uid)
        "#{CACHE_PREFIX}:#{Digest::SHA2.hexdigest(Marshal.dump(uid))}"
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
