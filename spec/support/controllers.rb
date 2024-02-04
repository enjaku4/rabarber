# frozen_string_literal: true

require "action_controller"
require "action_view"

class DummyPagesController < ActionController::Base
  def home
    head :ok
  end
end

class DummyAuthController < ActionController::Base
  include Rabarber::Authorization
end

class DummyController < ActionController::Base
  include Rabarber::Authorization

  grant_access action: :multiple_roles, roles: [:admin, :superadmin]
  def multiple_roles
    head :ok
  end

  grant_access action: :single_role, roles: :client
  def single_role
    head :ok
  end

  grant_access action: :all_access
  def all_access
    head :ok
  end

  def no_access
    head :ok
  end

  grant_access action: :if_lambda, roles: :admin, if: -> { params[:foo] == "bar" }
  def if_lambda
    head :ok
  end

  grant_access action: :if_method, roles: :admin, if: :foo?
  def if_method
    head :ok
  end

  grant_access action: :unless_lambda, roles: :admin, unless: -> { params[:foo] == "bar" }
  def unless_lambda
    head :ok
  end

  grant_access action: :unless_method, roles: :admin, unless: :foo?
  def unless_method
    head :ok
  end

  private

  def foo?
    params[:bad] == "baz"
  end
end

class DummyParentController < ActionController::Base
  include Rabarber::Authorization

  grant_access roles: :manager

  def foo
    head :ok
  end

  def bar
    head :ok
  end
end

class DummyChildController < DummyParentController
  def baz
    head :ok
  end

  def bad
    head :ok
  end
end
