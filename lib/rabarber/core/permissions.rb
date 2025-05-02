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
        @storage = {
          controller_rules: Hash.new { |h, k| h[k] = [] },
          action_rules: Hash.new { |h1, k1| h1[k1] = Hash.new { |h2, k2| h2[k2] = [] } }
        }
      end

      class << self
        def add(controller, action, roles, context, dynamic_rule, negated_dynamic_rule)
          rule = Rabarber::Core::Rule.new(roles, context, dynamic_rule, negated_dynamic_rule)
          action ? action_rules[controller][action] += [rule] : controller_rules[controller] += [rule]
        end

        def controller_rules
          instance.storage[:controller_rules]
        end

        def action_rules
          instance.storage[:action_rules]
        end

        def reset!
          instance.storage[:controller_rules].clear
          instance.storage[:action_rules].clear
        end
      end
    end
  end
end
