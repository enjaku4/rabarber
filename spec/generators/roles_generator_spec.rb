# frozen_string_literal: true

require "rails/generators"
require_relative "../../lib/generators/rabarber/roles_generator"

RSpec.describe Rabarber::RolesGenerator do
  subject { described_class.start([:my_users]) }

  before do
    allow(Time).to receive(:now).and_return(Time.new(2022, 12, 1, 21, 10, 56, "+01:00"))
    allow(ActiveRecord::Migration).to receive(:current_version).and_return(6.2)

    subject
  end

  after do
    FileUtils.rm_rf(Dir.glob("db"))
  end

  it "generates a properly named migration file" do
    expect(File).to exist("db/migrate/20221201201056_create_rabarber_roles.rb")
  end

  it "generates a migration file with proper content" do
    expect(File.read("db/migrate/20221201201056_create_rabarber_roles.rb")).to eq <<~MIGRATION
      # frozen_string_literal: true

      class CreateRabarberRoles < ActiveRecord::Migration[6.2]
        def change
          create_table :rabarber_roles do |t|
            t.string :name, null: false, index: { unique: true }
            t.timestamps
          end

          create_table :rabarber_roles_roleables, id: false do |t|
            t.belongs_to :role, null: false, index: true, foreign_key: { to_table: :rabarber_roles }
            t.belongs_to :roleable, null: false, index: true, foreign_key: { to_table: :my_users }
          end

          add_index :rabarber_roles_roleables, [:role_id, :roleable_id], unique: true
        end
      end
    MIGRATION
  end
end
