# frozen_string_literal: true

require "dry-types"

module Rabarber
  module Inputs
    # TODO: simplify this mess
    extend self

    include Dry.Types()

    TYPES = {
      boolean: -> { self::Strict::Bool },
      non_empty_string: -> { self::Strict::String.constrained(min_size: 1) },
      symbol: -> { (self::Strict::Symbol | self::Strict::String.constrained(min_size: 1)).constrained(format: /\A.+\z/).constructor(&:to_sym) },
      role: -> { (self::Strict::Symbol | self::Strict::String.constrained(min_size: 1)).constrained(format: /\A[a-z0-9_]+\z/).constructor(&:to_sym) },
      model: -> { self::Strict::Class.constructor { _1.try(:safe_constantize) || _1 }.constrained(lt: ActiveRecord::Base) },
      roles: -> { self::Array.of((self::Strict::Symbol | self::Strict::String.constrained(min_size: 1)).constrained(format: /\A[a-z0-9_]+\z/)).constructor { |input| Kernel::Array(input).map(&:to_sym) } },
      dynamic_rule: -> { self::Strict::Symbol.constructor { |v| v.is_a?(::String) ? v.to_sym : v }.constrained(format: /\A.+\z/) | self::Instance(Proc) },
      context: -> {
        (self::Strict::Class | self::Instance(ActiveRecord::Base) | self::Hash.schema(context_type: self::Strict::String | self::Nil, context_id: self::Strict::String | self::Strict::Integer | self::Nil) | self::Nil)
          .constructor do |value|
            case value
            when nil
              { context_type: nil, context_id: nil }
            when Class
              { context_type: value.to_s, context_id: nil }
            when ActiveRecord::Base
              raise Rabarber::InvalidArgumentError, "Context must be a Class or an instance of ActiveRecord model" unless value.persisted?

              { context_type: value.class.to_s, context_id: value.public_send(value.class.primary_key) }
            else
              value
            end
          end
      },
      authorization_context: -> {
        (self::Strict::Symbol | self::Strict::String | self::Strict::Class | self::Instance(Proc) | self::Instance(ActiveRecord::Base) | self::Hash.schema(context_type: self::Strict::String | self::Nil, context_id: self::Strict::String | self::Strict::Integer | self::Nil) | self::Nil)
          .constructor do |value|
            case value
            when nil
              { context_type: nil, context_id: nil }
            when String
              raise Rabarber::InvalidArgumentError, "Context must be a Class, an instance of ActiveRecord model, a Symbol, a String, or a Proc" if value.empty?

              value.to_sym
            when Symbol
              raise Rabarber::InvalidArgumentError, "Context must be a Class, an instance of ActiveRecord model, a Symbol, a String, or a Proc" if value == :""

              value
            when Class
              { context_type: value.to_s, context_id: nil }
            when ActiveRecord::Base
              raise Rabarber::InvalidArgumentError, "Context must be a Class, an instance of ActiveRecord model, a Symbol, a String, or a Proc" unless value.persisted?

              { context_type: value.class.to_s, context_id: value.public_send(value.class.primary_key) }
            else
              value
            end
          end
      }
    }.freeze

    def process(value, as:, optional: false, error: Rabarber::InvalidArgumentError, message: nil)
      checker = type_for(as)
      checker = checker.optional if optional

      checker[value]
    rescue Dry::Types::CoercionError => e
      raise error, message || e.message
    end

    private

    def type_for(name) = Rabarber::Inputs::TYPES.fetch(name).call
  end
end
