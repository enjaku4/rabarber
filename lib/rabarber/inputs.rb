# frozen_string_literal: true

require "dry-types"

module Rabarber
  module Inputs
    # TODO: simplify
    extend self

    include Dry.Types()

    Dry::Logic::Predicates.module_eval do
      predicate(:predicate?) { |predicate, input| input.public_send(predicate) }
    end

    TYPES = {
      boolean: -> { self::Strict::Bool },
      non_empty_string: -> { self::Strict::String.constrained(min_size: 1).constructor { _1.is_a?(::String) ? _1.strip : _1 } },
      symbol: -> { self::Coercible::Symbol.constrained(min_size: 1) },
      role: -> { self::Coercible::Symbol.constrained(min_size: 1, format: /\A[a-z0-9_]+\z/) },
      model: -> { self::Strict::Class.constructor { _1.try(:safe_constantize) }.constrained(lt: ActiveRecord::Base) },
      roles: -> { self::Array.of(self::Coercible::Symbol.constrained(min_size: 1, format: /\A[a-z0-9_]+\z/)).constructor { Kernel::Array(_1) } },
      dynamic_rule: -> { self::Coercible::Symbol.constrained(min_size: 1) | self::Instance(Proc) },
      context: -> {
        (
          self::Strict::Class | self::Instance(ActiveRecord::Base).constrained(predicate: :persisted?) |
          self::Hash.schema(
            context_type: self::Strict::String | self::Nil,
            context_id: self::Strict::String | self::Strict::Integer | self::Nil
          ) | self::Nil
        )
      },
      authorization_context: -> {
        (
          self::Coercible::Symbol.constrained(min_size: 1) | self::Strict::Class | self::Instance(Proc) |
          self::Instance(ActiveRecord::Base).constrained(predicate: :persisted?) |
          self::Hash.schema(
            context_type: self::Strict::String | self::Nil,
            context_id: self::Strict::String | self::Strict::Integer | self::Nil
          ) | self::Nil
        )
      }
    }.freeze

    def process(value, as:, optional: false, error: Rabarber::InvalidArgumentError, message: nil)
      checker = type_for(as)
      checker = checker.optional if optional

      if [:context, :authorization_context].include?(as)
        resolve_context(checker[value])
      else
        checker[value]
      end
    rescue Dry::Types::CoercionError => e
      raise error, message || e.message
    end

    private

    def type_for(name) = Rabarber::Inputs::TYPES.fetch(name).call

    def resolve_context(value)
      case value
      when nil then { context_type: nil, context_id: nil }
      when Class then { context_type: value.to_s, context_id: nil }
      when ActiveRecord::Base then { context_type: value.class.to_s, context_id: value.public_send(value.class.primary_key) }
      else value
      end
    end
  end
end
