# frozen_string_literal: true

class DummyChildController < DummyParentController
  grant_access roles: :client

  def baz = head(:ok)

  def bad = head(:ok)
end
