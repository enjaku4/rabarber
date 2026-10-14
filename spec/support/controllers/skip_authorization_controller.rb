# frozen_string_literal: true

class SkipAuthorizationController < ApplicationController
  skip_authorization only: [:skip_no_rules, :skip_rules]

  def skip_no_rules = head(:ok)

  grant_access action: :skip_rules, roles: :admin
  def skip_rules = head(:ok)

  grant_access action: :no_skip, roles: :developer
  def no_skip = head(:ok)
end
