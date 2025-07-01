# frozen_string_literal: true

require "dry-types"

module Rabarber
  module Inputs
    extend self

    include Dry.Types()

    Dry::Logic::Predicates.module_eval do
      predicate(:predicate?) { |predicate, input| input.public_send(predicate) }
    end

    CONTEXT_TYPE = self::Strict::Class | self::Instance(ActiveRecord::Base).constrained(predicate: :persisted?) |
                   self::Hash.schema(
                     context_type: self::Strict::String | self::Nil,
                     context_id: self::Strict::String | self::Strict::Integer | self::Nil
                   ) | self::Nil

    PROC_TYPE = self::Instance(Proc)
    SYMBOL_TYPE = self::Coercible::Symbol.constrained(min_size: 1)
    ROLE_TYPE = Rabarber::Inputs::SYMBOL_TYPE.constrained(format: /\A[a-z0-9_]+\z/)

    TYPES = {
      boolean: self::Strict::Bool,
      string: self::Strict::String.constrained(min_size: 1).constructor { _1.is_a?(::String) ? _1.strip : _1 },
      symbol: Rabarber::Inputs::SYMBOL_TYPE,
      role: Rabarber::Inputs::ROLE_TYPE,
      model: self::Strict::Class.constructor { _1.try(:safe_constantize) }.constrained(lt: ActiveRecord::Base),
      roles: self::Array.of(Rabarber::Inputs::ROLE_TYPE).constructor { Kernel::Array(_1) },
      dynamic_rule: Rabarber::Inputs::SYMBOL_TYPE | Rabarber::Inputs::PROC_TYPE,
      role_context: Rabarber::Inputs::CONTEXT_TYPE,
      authorization_context: Rabarber::Inputs::SYMBOL_TYPE | Rabarber::Inputs::PROC_TYPE | Rabarber::Inputs::CONTEXT_TYPE
    }.freeze

    def process(value, as:, optional: false, error: Rabarber::InvalidArgumentError, message: nil)
      checker = type_for(as)
      checker = checker.optional if optional

      result = checker[value]

      [:role_context, :authorization_context].include?(as) ? resolve_context(result) : result
    rescue Dry::Types::CoercionError => e
      raise error, message || e.message
    end

    private

    def type_for(name) = Rabarber::Inputs::TYPES.fetch(name)

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
