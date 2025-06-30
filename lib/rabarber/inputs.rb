# frozen_string_literal: true

require "dry-types"

module Rabarber
  module Inputs
    # TODO: make sure correct error messages are returned everywhere inputs are used, then simplify this mess, and test using the deleted tests as reference
    extend self

    include Dry.Types()

    TYPES = {
      boolean: -> { self::Strict::Bool },
      non_empty_string: -> { self::Strict::String.constrained(min_size: 1) },
      symbol: -> { (self::Strict::Symbol | self::Strict::String.constrained(min_size: 1)).constrained(format: /\A.+\z/).constructor(&:to_sym) },
      role: -> { (self::Strict::Symbol | self::Strict::String.constrained(min_size: 1)).constrained(format: /\A[a-z0-9_]+\z/).constructor(&:to_sym) },
      model: -> { self::Strict::Class.constructor { _1.try(:safe_constantize) || _1 }.constrained(lt: ActiveRecord::Base) },
      roles: -> { self::Array.of((self::Strict::Symbol | self::Strict::String.constrained(min_size: 1)).constrained(format: /\A[a-z0-9_]+\z/)).constructor { |input| Kernel::Array(input) } },
      dynamic_rule: -> { self::Strict::Symbol.constructor { |v| v.is_a?(::String) ? v.to_sym : v }.constrained(format: /\A.+\z/) | self::Instance(Proc) },
      context: -> {
        (self::Strict::Class | self::Instance(ActiveRecord::Base).constrained(&:persisted?) | self::Hash.schema(context_type: self::Strict::String | self::Nil, context_id: self::Strict::String | self::Strict::Integer | self::Nil) | self::Nil)
          .constructor do |value|
            case value
            when nil
              { context_type: nil, context_id: nil }
            when Class
              { context_type: value.to_s, context_id: nil }
            when ActiveRecord::Base
              { context_type: value.class.to_s, context_id: value.public_send(value.class.primary_key) }
            else
              value
            end
          end
      },
      authorization_context: -> {
        symbol_type = self::Strict::Symbol | self::Strict::String.constrained(min_size: 1).constructor(&:to_sym)
        proc_type = self::Instance(Proc)
        class_type = self::Strict::Class.constructor { |v| v.try(:safe_constantize) || v }
        ar_instance_type = self::Instance(ActiveRecord::Base).constrained(&:persisted?)
        hash_type = self::Hash.schema(
          context_type: self::Strict::String | self::Nil,
          context_id: self::Strict::String | self::Strict::Integer | self::Nil
        ).constructor do |value|
          case value
          when nil
            { context_type: nil, context_id: nil }
          when Class
            { context_type: value.to_s, context_id: nil }
          when ActiveRecord::Base
            { context_type: value.class.to_s, context_id: value.public_send(value.class.primary_key) }
          else
            value
          end
        end
        symbol_type | proc_type | class_type | ar_instance_type | hash_type
      }
    }.freeze

    def process(value, as:, optional: false, error: Rabarber::InvalidArgumentError, message: nil)
      checker = type_for(as)
      checker = checker.optional if optional

      checker[value]
    rescue Dry::Types::CoercionError, TypeError => e
      raise error, message || e.message
    end

    private

    def type_for(name) = Rabarber::Inputs::TYPES.fetch(name).call
  end
end
