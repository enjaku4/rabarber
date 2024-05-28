# frozen_string_literal: true

require "action_controller"
require "action_view"

class DummyPagesController < ActionController::Base
  def home = head(:ok)
end

class ApplicationController < ActionController::Base
  include Rabarber::Authorization
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
