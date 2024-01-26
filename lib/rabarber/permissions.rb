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
      handle_missing_roles(roles, controller, action)

      rule = ::Rabarber::Rule.new(action, roles, dynamic_rule, negated_dynamic_rule)

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

    def self.handle_missing_roles(roles, controller, action)
      missing_roles = roles - ::Rabarber::Role.names

      return if missing_roles.empty?

      delimiter = action ? "#" : ""
      context = "#{controller}#{delimiter}#{action}"

      ::Rabarber::Configuration.instance.when_roles_missing.call(missing_roles, context)
    end
  end
end
