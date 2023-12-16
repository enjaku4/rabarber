# frozen_string_literal: true

ActiveRecord::Schema.define do
  self.verbose = false

  create_table "rabarber_roles", force: true do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_rabarber_roles_on_name", unique: true
  end

  create_table "rabarber_roles_roleables", id: false, force: true do |t|
    t.integer "role_id"
    t.integer "roleable_id"
    t.index ["role_id", "roleable_id"], name: "index_rabarber_roles_roleables_on_role_id_and_roleable_id", unique: true
    t.index ["role_id"], name: "index_rabarber_roles_roleables_on_role_id"
    t.index ["roleable_id"], name: "index_rabarber_roles_roleables_on_roleable_id"
  end

  create_table "users", force: true do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
