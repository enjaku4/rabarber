# frozen_string_literal: true

class DummyParentController < ApplicationController
  grant_access roles: :manager

  def foo = head(:ok)

  def bar = head(:ok)
end
