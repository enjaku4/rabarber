# frozen_string_literal: true

module Rabarber
  module Core
    class Context
      attr_reader :context

      def initialize(context)
        @context = Rabarber::Input::Context.new(context).process
      end

      def to_h
        context
      end

      # TODO: perhaps this class is not needed and to_s can be moved to audit base class
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
