# frozen_string_literal: true

RSpec.describe Rabarber::Missing::Roles do
  subject { described_class.new(controller).handle }

  let(:callable_double) { instance_double(Proc) }

  before do
    allow(Rabarber::Configuration.instance).to receive(:when_roles_missing).and_return(callable_double)

    [:manager, :admin, :superadmin, :client].each { |role| Rabarber::Role.create!(name: role) }
  end

  after do
    Rabarber::Permissions.action_rules.delete(DummyAuthController)
    Rabarber::Permissions.controller_rules.delete(DummyAuthController)
  end

  context "cache" do
    let(:controller) { nil }

    it "caches roles" do
      expect(Rabarber::Cache).to receive(:fetch)
        .with(Rabarber::Cache::ALL_ROLES_KEY, expires_in: 1.day, race_condition_ttl: 10.seconds) do |&block|
          result = block.call
          expect(result).to eq(Rabarber::Role.names)
          result
        end.at_least(:once)
      subject
    end
  end

  context "when controller is not specified" do
    let(:controller) { nil }

    context "when role is missing" do
      context "in controller rules" do
        before { Rabarber::Permissions.add(DummyAuthController, nil, [:missing_role], nil, nil) }

        it "calls configuration" do
          expect(callable_double).to receive(:call).with([:missing_role], { controller: DummyAuthController })
          subject
        end
      end

      context "in action rules" do
        before { Rabarber::Permissions.add(DummyAuthController, :index, [:missing_role], nil, nil) }

        it "calls configuration" do
          expect(callable_double).to receive(:call).with(
            [:missing_role], { controller: DummyAuthController, action: :index }
          )
          subject
        end
      end

      context "in both controller and action rules" do
        before do
          Rabarber::Permissions.add(DummyAuthController, nil, [:missing_role], nil, nil)
          Rabarber::Permissions.add(DummyAuthController, :index, [:missing_role], nil, nil)
        end

        it "calls configuration twice" do
          expect(callable_double).to receive(:call).with(
            [:missing_role], { controller: DummyAuthController }
          )
          expect(callable_double).to receive(:call).with(
            [:missing_role], { controller: DummyAuthController, action: :index }
          )
          subject
        end
      end
    end

    context "when role is not missing" do
      it "does not call configuration" do
        expect(callable_double).not_to receive(:call)
        subject
      end
    end
  end

  context "when controller is specified" do
    let(:controller) { DummyAuthController }

    context "when role is missing" do
      context "in controller rules" do
        before { Rabarber::Permissions.add(DummyAuthController, nil, [:missing_role], nil, nil) }

        it "calls configuration" do
          expect(callable_double).to receive(:call).with([:missing_role], { controller: DummyAuthController })
          subject
        end
      end

      context "in action rules" do
        before { Rabarber::Permissions.add(DummyAuthController, :index, [:missing_role], nil, nil) }

        it "calls configuration" do
          expect(callable_double).to receive(:call).with(
            [:missing_role], { controller: DummyAuthController, action: :index }
          )
          subject
        end
      end

      context "in both controller and action rules" do
        before do
          Rabarber::Permissions.add(DummyAuthController, nil, [:missing_role], nil, nil)
          Rabarber::Permissions.add(DummyAuthController, :index, [:missing_role], nil, nil)
        end

        it "calls configuration twice" do
          expect(callable_double).to receive(:call).with(
            [:missing_role], { controller: DummyAuthController }
          )
          expect(callable_double).to receive(:call).with(
            [:missing_role], { controller: DummyAuthController, action: :index }
          )
          subject
        end
      end
    end

    context "when role is not missing" do
      it "does not call configuration" do
        expect(callable_double).not_to receive(:call)
        subject
      end
    end

    context "when role is missing in another controller" do
      context "in controller rules" do
        before { Rabarber::Permissions.add(DummyController, nil, [:missing_role], nil, nil) }

        after { Rabarber::Permissions.controller_rules.delete(DummyController) }

        it "does not call configuration" do
          expect(callable_double).not_to receive(:call)
          subject
        end
      end

      context "in action rules" do
        before { Rabarber::Permissions.add(DummyController, :index, [:missing_role], nil, nil) }

        after { Rabarber::Permissions.action_rules[DummyController].pop }

        it "does not call configuration" do
          expect(callable_double).not_to receive(:call)
          subject
        end
      end

      context "in both controller and action rules" do
        before do
          Rabarber::Permissions.add(DummyController, nil, [:missing_role], nil, nil)
          Rabarber::Permissions.add(DummyController, :index, [:missing_role], nil, nil)
        end

        after do
          Rabarber::Permissions.controller_rules.delete(DummyController)
          Rabarber::Permissions.action_rules[DummyController].pop
        end

        it "does not call configuration" do
          expect(callable_double).not_to receive(:call)
          subject
        end
      end
    end
  end
end
