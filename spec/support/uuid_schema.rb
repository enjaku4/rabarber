# frozen_string_literal: true

ActiveRecord::Schema.define do
  self.verbose = false

  create_table "rabarber_roles", id: false, force: :cascade do |t|
    t.string "id", primary_key: true, null: false, limit: 36
    t.string "name", null: false
    t.string "context_type"
    t.string "context_id", limit: 36
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["context_type", "context_id"], name: "index_rabarber_roles_on_context"
    t.index ["name", "context_type", "context_id"], name: "index_rabarber_roles_on_name_and_context_type_and_context_id", unique: true
  end

  create_table "rabarber_roles_roleables", id: false, force: :cascade do |t|
    t.string "role_id", null: false, limit: 36
    t.string "roleable_id", null: false, limit: 36
    t.index ["role_id", "roleable_id"], name: "index_rabarber_roles_roleables_on_role_id_and_roleable_id", unique: true
    t.index ["role_id"], name: "index_rabarber_roles_roleables_on_role_id"
    t.index ["roleable_id"], name: "index_rabarber_roles_roleables_on_roleable_id"
  end

  create_table "users", id: false, force: true do |t|
    t.string "id", primary_key: true, null: false, limit: 36
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "clients", id: false, force: true do |t|
    t.string "id", primary_key: true, null: false, limit: 36
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projects", id: false, force: true do |t|
    t.string "id", primary_key: true, null: false, limit: 36
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "rabarber_roles_roleables", "rabarber_roles", column: "role_id"
  add_foreign_key "rabarber_roles_roleables", "users", column: "roleable_id"
end
