# frozen_string_literal: true

module Rabarber
  class RoleAssignment < ActiveRecord::Base
    self.table_name = "rabarber_roles_roleables"

    belongs_to :role, class_name: "Rabarber::Role"
    belongs_to :roleable, class_name: Rabarber::Configuration.user_model_name
  end
end
