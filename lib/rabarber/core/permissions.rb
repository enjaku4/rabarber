# frozen_string_literal: true

require_relative "access"
require_relative "rule"

require "singleton"

module Rabarber
  module Core
    class Permissions
      include Singleton

      extend Access

      attr_reader :storage

      def initialize
        @storage = { controller_rules: Hash.new({}), action_rules: Hash.new([]) }
      end

      class << self
        def add(controller, action, roles, dynamic_rule, negated_dynamic_rule)
          rule = Rabarber::Core::Rule.new(action, roles, dynamic_rule, negated_dynamic_rule)

          if action
            instance.storage[:action_rules][controller] += [rule]
          else
            instance.storage[:controller_rules][controller] = rule
          end
        end

        def controller_rules
          instance.storage[:controller_rules]
        end

        def action_rules
          instance.storage[:action_rules]
        end
      end
    end
  end
end
