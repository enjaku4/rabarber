# frozen_string_literal: true

require "rails/generators"
require_relative "../../lib/generators/rabarber/roles_generator"

RSpec.describe Rabarber::RolesGenerator do
  subject { described_class.start(args) }

  let(:migration_file) { "db/migrate/20221201201056_create_rabarber_roles.rb" }
  let(:migration_content) do
    <<~MIGRATION
      # frozen_string_literal: true

      class CreateRabarberRoles < ActiveRecord::Migration[6.2]
        def change
          create_table :rabarber_roles#{", id: :uuid" if args.include?("--uuid")} do |t|
            t.string :name, null: false
            t.belongs_to :context, polymorphic: true, index: true#{", type: :uuid" if args.include?("--uuid")}
            t.timestamps
          end

          add_index :rabarber_roles, [:name, :context_type, :context_id], unique: true

          create_table :rabarber_roles_roleables, id: false do |t|
            t.belongs_to :role, null: false, index: true, foreign_key: { to_table: :rabarber_roles }#{", type: :uuid" if args.include?("--uuid")}
            t.belongs_to :roleable, null: false, index: true, foreign_key: { to_table: :my_users }#{", type: :uuid" if args.include?("--uuid")}
          end

          add_index :rabarber_roles_roleables, [:role_id, :roleable_id], unique: true
        end
      end
    MIGRATION
  end

  before do
    allow(Time).to receive(:now).and_return(Time.new(2022, 12, 1, 21, 10, 56, "+01:00"))
    allow(ActiveRecord::Migration).to receive(:current_version).and_return(6.2)
    subject
  end

  after { FileUtils.rm_rf(Dir.glob("db")) }

  shared_examples "a migration generator" do
    it "generates a properly named migration file" do
      expect(File).to exist(migration_file)
    end

    it "generates a migration file with proper content" do
      expect(File.read(migration_file)).to eq(migration_content)
    end
  end

  context "when --uuid option is not provided" do
    let(:args) { [:my_users] }

    it_behaves_like "a migration generator"
  end

  context "when --uuid option is provided" do
    let(:args) { [:my_users, "--uuid"] }

    it_behaves_like "a migration generator"
  end
end
