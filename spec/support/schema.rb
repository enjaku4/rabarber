# frozen_string_literal: true

ActiveRecord::Schema.define do
  self.verbose = false

  create_table "rabarber_roles", force: :cascade do |t|
    t.string "name", null: false
    t.string "context_type"
    t.integer "context_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["context_type", "context_id"], name: "index_rabarber_roles_on_context"
    t.index ["name", "context_type", "context_id"], name: "index_rabarber_roles_on_name_and_context_type_and_context_id", unique: true
  end

  create_table "rabarber_roles_roleables", id: false, force: :cascade do |t|
    t.integer "role_id", null: false
    t.integer "roleable_id", null: false
    t.index ["role_id", "roleable_id"], name: "index_rabarber_roles_roleables_on_role_id_and_roleable_id", unique: true
    t.index ["role_id"], name: "index_rabarber_roles_roleables_on_role_id"
    t.index ["roleable_id"], name: "index_rabarber_roles_roleables_on_roleable_id"
  end

  create_table "users", force: true do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projects", force: true do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "rabarber_roles_roleables", "rabarber_roles", column: "role_id"
  add_foreign_key "rabarber_roles_roleables", "users", column: "roleable_id"
end
