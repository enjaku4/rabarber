# frozen_string_literal: true

module Rabarber
  module Inputs
    class Context < Rabarber::Inputs::Base
      def resolve
        case context = process
        when nil
          { context_type: nil, context_id: nil }
        when Class
          { context_type: context.to_s, context_id: nil }
        when ActiveRecord::Base
          raise_error unless context.persisted?
          { context_type: context.class.to_s, context_id: context.public_send(context.class.primary_key) }
        else
          context
        end
      end

      private

      def processor
        -> {
          return @value if @value.nil?
          return @value if @value.is_a?(Class)
          return @value if @value.is_a?(ActiveRecord::Base)
          return @value if @value in { context_type: String | nil, context_id: String | Integer | nil }

          raise_error
        }
      end
    end
  end
end
