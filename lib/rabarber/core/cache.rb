# frozen_string_literal: true

require "digest/md5"
require "securerandom"

module Rabarber
  module Core
    module Cache
      extend self

      def fetch(roleable_id, scope, &)
        return yield if !enabled? || ActiveRecord::Base.current_transaction.open?

        Rails.cache.fetch(prepare_key(roleable_id, scope), expires_in: 1.hour, race_condition_ttl: 5.seconds, &)
      end

      def delete(*pairs)
        return unless enabled? && pairs.any?

        ActiveRecord.after_all_transactions_commit do
          Rails.cache.delete_multi(pairs.map { |roleable_id, scope| prepare_key(roleable_id, scope) })
        end
      end

      def clear
        ActiveRecord.after_all_transactions_commit { rotate_version }
      end

      private

      def enabled?
        Rabarber::Configuration.cache_enabled
      end

      def prepare_key(roleable_id, scope)
        Digest::MD5.base64digest(Marshal.dump([current_version, roleable_id, scope]))
      end

      def current_version
        version = Rails.cache.read(VERSION_KEY).presence

        return version if version

        rotate_version

        Rails.cache.read(VERSION_KEY)
      end

      def rotate_version
        Rails.cache.write(VERSION_KEY, SecureRandom.alphanumeric(8))
      end

      VERSION_KEY = "rabarber"
      private_constant :VERSION_KEY
    end
  end

  module Cache
    delegate :clear, to: :"Rabarber::Core::Cache"
    module_function :clear
  end
end
