# frozen_string_literal: true

module Rabarber
  module Inputs
    class Context < Base
      def resolve
        case context = process
        when nil
          { context_type: nil, context_id: nil }
        when Class
          { context_type: context.to_s, context_id: nil }
        when ActiveRecord::Base
          raise @error, @message unless context.persisted?

          { context_type: context.class.to_s, context_id: context.public_send(context.class.primary_key) }
        else
          context
        end
      end

      private

      def type
        self.class::Strict::Class |
          self.class::Instance(ActiveRecord::Base) |
          self.class::Hash.schema(
            context_type: self.class::Strict::String | self.class::Nil,
            context_id: self.class::Strict::String | self.class::Strict::Integer | self.class::Nil
          ) |
          self.class::Nil
      end
    end
  end
end
