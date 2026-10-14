# frozen_string_literal: true

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
