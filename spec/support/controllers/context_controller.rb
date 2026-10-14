# frozen_string_literal: true

class ContextController < ApplicationController
  grant_access action: :global_ctx, roles: :admin, context: nil
  def global_ctx = head(:ok)

  grant_access action: :class_ctx, roles: :admin, context: Project
  def class_ctx = head(:ok)

  grant_access action: :symbol_ctx, roles: :admin, context: :project
  def symbol_ctx = head(:ok)

  grant_access action: :proc_ctx, roles: :admin, context: -> { Project }
  def proc_ctx = head(:ok)

  private

  def project = Project.create!
end
