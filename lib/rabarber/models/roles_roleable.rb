# frozen_string_literal: true
#
module Rabarber
  class RolesRoleable < ActiveRecord::Base
    self.table_name = "rabarber_roles_roleables"

    belongs_to :role, class_name: "Rabarber::Role"
  end
end
