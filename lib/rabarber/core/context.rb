# frozen_string_literal: true

module Rabarber
  module Core
    class Context
      attr_reader :context

      def initialize(context, wrap: false)
        @context = wrap ? context : Rabarber::Input::Context.new(context).process
      end

      def to_h
        context
      end

      def to_s
        case context
        in { context_type: nil, context_id: nil } then "Global"
        in { context_type: context_type, context_id: nil } then context_type
        in { context_type: context_type, context_id: context_id } then "#{context_type}##{context_id}"
        else raise "Unexpected context: #{context}"
        end
      end
    end
  end
end
