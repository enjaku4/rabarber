# frozen_string_literal: true

require_relative "rabarber/version"

require "active_record"
require "active_support"

require_relative "rabarber/inputs/base"
require_relative "rabarber/inputs/boolean"
require_relative "rabarber/inputs/context"
require_relative "rabarber/inputs/contexts/authorizational"
require_relative "rabarber/inputs/dynamic_rule"
require_relative "rabarber/inputs/model"
require_relative "rabarber/inputs/non_empty_string"
require_relative "rabarber/inputs/role"
require_relative "rabarber/inputs/roles"
require_relative "rabarber/inputs/symbol"

require_relative "rabarber/configuration"

module Rabarber
  class Error < StandardError; end
  class ConfigurationError < Rabarber::Error; end
  class InvalidArgumentError < Rabarber::Error; end
  class NotFoundError < Rabarber::Error; end

  delegate :configure, to: Rabarber::Configuration
  module_function :configure
end

require_relative "rabarber/core/cache"

require_relative "rabarber/core/roleable"

require_relative "rabarber/controllers/concerns/authorization"
require_relative "rabarber/helpers/helpers"
require_relative "rabarber/helpers/migration_helpers"
require_relative "rabarber/models/concerns/has_roles"
require_relative "rabarber/models/role"

require_relative "rabarber/core/permissions"
require_relative "rabarber/core/integrity_checker"

require_relative "rabarber/railtie"
