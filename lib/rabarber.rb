# frozen_string_literal: true

require_relative "rabarber/version"
require_relative "rabarber/configuration"

require "active_record"
require "active_support"

require_relative "rabarber/input/base"
require_relative "rabarber/input/actions"
require_relative "rabarber/input/dynamic_rules"
require_relative "rabarber/input/roles"
require_relative "rabarber/input/types/booleans"
require_relative "rabarber/input/types/callables"
require_relative "rabarber/input/types/symbols"

require_relative "rabarber/controllers/concerns/authorization"
require_relative "rabarber/helpers/helpers"
require_relative "rabarber/models/concerns/has_roles"
require_relative "rabarber/models/group"
require_relative "rabarber/models/role"
require_relative "rabarber/permissions"

module Rabarber
  module_function

  def configure
    yield(Configuration.instance)
  end

  class Error < StandardError; end
  class ConfigurationError < Error; end
  class InvalidArgumentError < Error; end
end
