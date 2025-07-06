# frozen_string_literal: true

require "dry-types"

module Rabarber
  module Inputs
    extend self

    include Dry.Types()

    PROC_TYPE = self::Instance(Proc)
    SYMBOL_TYPE = self::Coercible::Symbol.constrained(min_size: 1)
    ROLE_TYPE = self::SYMBOL_TYPE.constrained(format: /\A[a-z0-9_]+\z/)

    CONTEXT_TYPE = self::Strict::Class | self::Instance(ActiveRecord::Base) | self::Hash.schema(
      context_type: self::Strict::String | self::Nil,
      context_id: self::Strict::String | self::Strict::Integer | self::Nil
    ) | self::Nil

    TYPES = {
      boolean: self::Strict::Bool,
      string: self::Strict::String.constrained(min_size: 1).constructor { _1.is_a?(::String) ? _1.strip : _1 },
      symbol: self::SYMBOL_TYPE,
      role: self::ROLE_TYPE,
      roles: self::Array.of(self::ROLE_TYPE).constructor { Kernel::Array(_1) },
      model: self::Strict::Class.constructor { _1.try(:safe_constantize) }.constrained(lt: ActiveRecord::Base),
      dynamic_rule: self::SYMBOL_TYPE | self::PROC_TYPE,
      role_context: self::CONTEXT_TYPE,
      authorization_context: self::SYMBOL_TYPE | self::PROC_TYPE | self::CONTEXT_TYPE
    }.freeze

    def process(value, as:, optional: false, error: Rabarber::InvalidArgumentError, message: nil)
      checker = type_for(as)
      checker = checker.optional if optional

      result = checker[value]

      # TODO: intuitively doesn't feel right
      [:role_context, :authorization_context].include?(as) ? resolve_context(result) : result
    rescue Dry::Types::CoercionError => e
      raise error, message || e.message
    end

    private

    def type_for(name) = self::TYPES.fetch(name)

    # TODO: there should be some separate context resolver or smth
    def resolve_context(value)
      case value
      when nil
        { context_type: nil, context_id: nil }
      when Class
        { context_type: value.to_s, context_id: nil }
      when ActiveRecord::Base
        # TODO: this should be included in the type definition somehow, or maybe dry-validation?
        raise Dry::Types::CoercionError, "instance context not persisted" unless value.persisted?

        { context_type: value.class.to_s, context_id: value.public_send(value.class.primary_key) }
      else
        value
      end
    end
  end
end
