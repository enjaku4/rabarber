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
  class InvalidArgumentError < Rabarber::Error; end
  class ConfigurationError < Rabarber::InvalidArgumentError; end
  class InvalidContextError < Rabarber::InvalidArgumentError; end
  class NotFoundError < Rabarber::Error; end

  delegate :configure, to: Rabarber::Configuration
  module_function :configure
  # TOOD: specs
  class << self
    def roles(context: nil) = Rabarber::Role.names(context:)
    def all_roles = Rabarber::Role.all_names
    def create_role(name, context: nil) = Rabarber::Role.add(name, context:)
    def rename_role(old_name, new_name, context: nil, force: false) = Rabarber::Role.rename(old_name, new_name, context:, force:)
    def delete_role(name, context: nil, force: false) = Rabarber::Role.remove(name, context:, force:)
    def prune_roles = Rabarber::Role.prune
  end
end

require_relative "rabarber/core/cache"

require_relative "rabarber/core/roleable"

require_relative "rabarber/controllers/concerns/authorization"
require_relative "rabarber/helpers/helpers"
require_relative "rabarber/helpers/migration_helpers"
require_relative "rabarber/models/concerns/roleable"
require_relative "rabarber/models/role"

require_relative "rabarber/core/permissions"

require_relative "rabarber/railtie"
