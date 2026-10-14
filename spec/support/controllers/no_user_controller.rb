# frozen_string_literal: true

class NoUserController < ApplicationController
  grant_access action: :access_with_roles, roles: :admin
  def access_with_roles = head(:ok)

  grant_access action: :all_access
  def all_access = head(:ok)

  def no_access = head(:ok)
end
