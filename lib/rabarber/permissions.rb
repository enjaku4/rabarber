# frozen_string_literal: true

require_relative "access"
require_relative "rule"

module Rabarber
  class Permissions
    include Singleton

    extend Access

    attr_reader :storage

    def initialize
      @storage = { controller_rules: Hash.new({}), action_rules: Hash.new([]) }
    end

    def self.add(controller, action, roles, dynamic_rule, negated_dynamic_rule)
      rule = Rule.new(action, roles, dynamic_rule, negated_dynamic_rule)

      if action
        instance.storage[:action_rules][controller] += [rule]
      else
        instance.storage[:controller_rules][controller] = rule
      end
    end

    def self.controller_rules
      instance.storage[:controller_rules]
    end

    def self.action_rules
      instance.storage[:action_rules]
    end
  end
end
