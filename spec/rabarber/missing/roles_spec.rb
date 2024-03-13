# frozen_string_literal: true

RSpec.describe Rabarber::Missing::Roles do
  subject { described_class.new(controller).handle }

  before { [:manager, :admin, :superadmin, :client].each { |role| Rabarber::Role.create!(name: role) } }

  after do
    Rabarber::Core::Permissions.action_rules.delete(DummyAuthController)
    Rabarber::Core::Permissions.controller_rules.delete(DummyAuthController)
  end

  shared_examples_for "it caches roles" do
    it "caches roles" do
      expect(Rabarber::Cache).to receive(:fetch)
        .with(Rabarber::Cache::ALL_ROLES_KEY, expires_in: 1.day, race_condition_ttl: 10.seconds) do |&block|
          result = block.call
          expect(result).to eq(Rabarber::Role.names)
          result
        end
      subject
    end
  end

  context "when controller is not specified" do
    let(:controller) { nil }

    context "when role is missing" do
      context "in controller rules" do
        before { Rabarber::Core::Permissions.add(DummyAuthController, nil, [:missing_role], nil, nil) }

        it "logs" do
          expect(Rabarber::Logger).to receive(:log).with(
            :debug, "'grant_access' method called with non-existent roles: [:missing_role], context: 'DummyAuthController'"
          )
          subject
        end

        it_behaves_like "it caches roles"
      end

      context "in action rules" do
        before { Rabarber::Core::Permissions.add(DummyAuthController, :index, [:missing_role], nil, nil) }

        it "logs" do
          expect(Rabarber::Logger).to receive(:log).with(
            :debug, "'grant_access' method called with non-existent roles: [:missing_role], context: 'DummyAuthController#index'"
          )
          subject
        end

        it_behaves_like "it caches roles"
      end

      context "in both controller and action rules" do
        before do
          Rabarber::Core::Permissions.add(DummyAuthController, nil, [:missing_role], nil, nil)
          Rabarber::Core::Permissions.add(DummyAuthController, :index, [:missing_role], nil, nil)
        end

        it "logs twice" do
          expect(Rabarber::Logger).to receive(:log).with(
            :debug, "'grant_access' method called with non-existent roles: [:missing_role], context: 'DummyAuthController'"
          )
          expect(Rabarber::Logger).to receive(:log).with(
            :debug, "'grant_access' method called with non-existent roles: [:missing_role], context: 'DummyAuthController#index'"
          )
          subject
        end

        it_behaves_like "it caches roles"
      end
    end
  end

  context "when controller is specified" do
    let(:controller) { DummyAuthController }

    context "when role is missing" do
      context "in controller rules" do
        before { Rabarber::Core::Permissions.add(DummyAuthController, nil, [:missing_role], nil, nil) }

        it "logs" do
          expect(Rabarber::Logger).to receive(:log).with(
            :debug, "'grant_access' method called with non-existent roles: [:missing_role], context: 'DummyAuthController'"
          )
          subject
        end

        it_behaves_like "it caches roles"
      end

      context "in action rules" do
        before { Rabarber::Core::Permissions.add(DummyAuthController, :index, [:missing_role], nil, nil) }

        it "calls configuration" do
          expect(Rabarber::Logger).to receive(:log).with(
            :debug, "'grant_access' method called with non-existent roles: [:missing_role], context: 'DummyAuthController#index'"
          )
          subject
        end

        it_behaves_like "it caches roles"
      end

      context "in both controller and action rules" do
        before do
          Rabarber::Core::Permissions.add(DummyAuthController, nil, [:missing_role], nil, nil)
          Rabarber::Core::Permissions.add(DummyAuthController, :index, [:missing_role], nil, nil)
        end

        it "logs twice" do
          expect(Rabarber::Logger).to receive(:log).with(
            :debug, "'grant_access' method called with non-existent roles: [:missing_role], context: 'DummyAuthController'"
          )
          expect(Rabarber::Logger).to receive(:log).with(
            :debug, "'grant_access' method called with non-existent roles: [:missing_role], context: 'DummyAuthController#index'"
          )
          subject
        end

        it_behaves_like "it caches roles"
      end
    end
  end
end
