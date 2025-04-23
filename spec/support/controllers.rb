# frozen_string_literal: true

require "action_controller"
require "action_view"

class DummyPagesController < ActionController::Base
  def home = head(:ok)
end

class ApplicationController < ActionController::Base
  include Rabarber::Authorization

  before_action :authorize
end

class DummyAuthController < ApplicationController; end

class DummyController < ApplicationController
  grant_access action: :multiple_roles, roles: [:admin, :superadmin]
  def multiple_roles = head(:ok)

  grant_access action: :single_role, roles: :client
  def single_role = head(:ok)

  grant_access action: :all_access
  def all_access = head(:ok)

  def no_access = head(:ok)

  grant_access action: :multiple_rules, roles: [:manager]
  grant_access action: :multiple_rules, roles: [:client]
  def multiple_rules = head(:ok)

  grant_access action: :if_lambda, roles: :admin, if: -> { params[:foo] == "bar" }
  def if_lambda = head(:ok)

  grant_access action: :if_method, roles: :admin, if: :foo?
  def if_method = head(:ok)

  grant_access action: :unless_lambda, roles: :admin, unless: -> { params[:foo] == "bar" }
  def unless_lambda = head(:ok)

  grant_access action: :unless_method, roles: :admin, unless: :foo?
  def unless_method = head(:ok)

  private

  def foo?
    params[:bad] == "baz"
  end
end

class DummyParentController < ApplicationController
  grant_access roles: :manager

  def foo = head(:ok)

  def bar = head(:ok)
end

class DummyChildController < DummyParentController
  grant_access roles: :client

  def baz = head(:ok)

  def bad = head(:ok)
end

class MultipleRulesController < ApplicationController
  grant_access roles: [:maintainer]
  grant_access roles: [:admin, :user], context: Project

  def qux = head(:ok)
end

class AllAccessController < ApplicationController
  grant_access

  def quux = head(:ok)
end

class NoUserController < ApplicationController
  grant_access action: :access_with_roles, roles: :admin
  def access_with_roles = head(:ok)

  grant_access action: :all_access
  def all_access = head(:ok)

  def no_access = head(:ok)
end

class ControllerWideDynamicRuleController < ApplicationController
  grant_access if: :foo?

  private

  def foo?
    true
  end
end

class NoRulesController < ApplicationController
  def no_rules = head(:ok)
end

class SkipAuthorizationController < ApplicationController
  skip_authorization only: [:skip_no_rules, :skip_rules]

  def skip_no_rules = head(:ok)

  grant_access action: :skip_rules, roles: :admin
  def skip_rules = head(:ok)

  grant_access action: :no_skip, roles: :developer
  def no_skip = head(:ok)
end

class ContextController < ApplicationController
  grant_access action: :global_ctx, roles: :admin, context: nil
  def global_ctx = head(:ok)

  grant_access action: :class_ctx, roles: :admin, context: Project
  def class_ctx = head(:ok)

  grant_access action: :instance_ctx, roles: :admin, context: Project.create!
  def instance_ctx = head(:ok)

  grant_access action: :symbol_ctx, roles: :admin, context: :project
  def symbol_ctx = head(:ok)

  grant_access action: :proc_ctx, roles: :admin, context: -> { Project }
  def proc_ctx = head(:ok)

  private

  def project = Project.create!
end

class ApiController < ActionController::API
  include Rabarber::Authorization

  before_action :authorize

  grant_access action: :api_action, roles: :client
  def api_action = head(:ok)
end
