# frozen_string_literal: true

module Rabarber
  class RoleAssignment < ActiveRecord::Base
    self.table_name = "rabarber_roles_roleables"
  end
end
