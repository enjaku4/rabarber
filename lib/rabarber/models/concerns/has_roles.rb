# frozen_string_literal: true

module Rabarber
  module HasRoles
    extend ActiveSupport::Concern

    include Internal

    included do
      raise Error, "Rabarber::HasRoles can only be included once" if defined?(@@included) && @@included != name

      @@included = name

      has_and_belongs_to_many :rabarber_roles, class_name: "Rabarber::Role",
                                               foreign_key: "roleable_id",
                                               join_table: "rabarber_roles_roleables"
    end
  end
end
