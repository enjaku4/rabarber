# frozen_string_literal: true

module Rabarber
  module Input
    class Context < Rabarber::Input::Base
      def valid?
        value.nil? || value.is_a?(Class) || value.is_a?(ActiveRecord::Base)
      end

      private

      def processed_value
        case value
        when nil then { context_type: nil, context_id: nil }
        when Class then { context_type: value.to_s, context_id: nil }
        when ActiveRecord::Base then { context_type: value.class.to_s, context_id: value.public_send(value.class.primary_key) }
        end
      end

      def default_error_message
        "Context must be a Class or an instance of ActiveRecord::Base"
      end
    end
  end
end
