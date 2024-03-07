# frozen_string_literal: true

RSpec.describe Rabarber::Missing::Roles do
  subject { described_class.new(controller).handle }

  let(:callable_double) { instance_double(Proc) }

  before do
    allow(Rabarber::Configuration.instance).to receive(:when_roles_missing).and_return(callable_double)

    [:manager, :admin, :superadmin, :client].each { |role| Rabarber::Role.create!(name: role) }
  end

  after do
    Rabarber::Core::Permissions.action_rules.delete(DummyAuthController)
    Rabarber::Core::Permissions.controller_rules.delete(DummyAuthController)
  end

  shared_examples_for "it caches roles" do
    before { allow(callable_double).to receive(:call).with(any_args) }

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

        it "calls configuration" do
          expect(callable_double).to receive(:call).with([:missing_role], { controller: DummyAuthController })
          subject
        end

        it_behaves_like "it caches roles"
      end

      context "in action rules" do
        before { Rabarber::Core::Permissions.add(DummyAuthController, :index, [:missing_role], nil, nil) }

        it "calls configuration" do
          expect(callable_double).to receive(:call).with(
            [:missing_role], { controller: DummyAuthController, action: :index }
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

        it "calls configuration twice" do
          expect(callable_double).to receive(:call).with(
            [:missing_role], { controller: DummyAuthController }
          )
          expect(callable_double).to receive(:call).with(
            [:missing_role], { controller: DummyAuthController, action: :index }
          )
          subject
        end

        it_behaves_like "it caches roles"
      end
    end

    context "when role is not missing" do
      it "does not call configuration" do
        expect(callable_double).not_to receive(:call)
        subject
      end

      it_behaves_like "it caches roles"
    end
  end

  context "when controller is specified" do
    let(:controller) { DummyAuthController }

    context "when role is missing" do
      context "in controller rules" do
        before { Rabarber::Core::Permissions.add(DummyAuthController, nil, [:missing_role], nil, nil) }

        it "calls configuration" do
          expect(callable_double).to receive(:call).with([:missing_role], { controller: DummyAuthController })
          subject
        end

        it_behaves_like "it caches roles"
      end

      context "in action rules" do
        before { Rabarber::Core::Permissions.add(DummyAuthController, :index, [:missing_role], nil, nil) }

        it "calls configuration" do
          expect(callable_double).to receive(:call).with(
            [:missing_role], { controller: DummyAuthController, action: :index }
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

        it "calls configuration twice" do
          expect(callable_double).to receive(:call).with(
            [:missing_role], { controller: DummyAuthController }
          )
          expect(callable_double).to receive(:call).with(
            [:missing_role], { controller: DummyAuthController, action: :index }
          )
          subject
        end

        it_behaves_like "it caches roles"
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
        before { Rabarber::Core::Permissions.add(DummyController, nil, [:missing_role], nil, nil) }

        after { Rabarber::Core::Permissions.controller_rules.delete(DummyController) }

        it "does not call configuration" do
          expect(callable_double).not_to receive(:call)
          subject
        end
      end

      context "in action rules" do
        before { Rabarber::Core::Permissions.add(DummyController, :index, [:missing_role], nil, nil) }

        after { Rabarber::Core::Permissions.action_rules[DummyController].pop }

        it "does not call configuration" do
          expect(callable_double).not_to receive(:call)
          subject
        end
      end

      context "in both controller and action rules" do
        before do
          Rabarber::Core::Permissions.add(DummyController, nil, [:missing_role], nil, nil)
          Rabarber::Core::Permissions.add(DummyController, :index, [:missing_role], nil, nil)
        end

        after do
          Rabarber::Core::Permissions.controller_rules.delete(DummyController)
          Rabarber::Core::Permissions.action_rules[DummyController].pop
        end

        it "does not call configuration" do
          expect(callable_double).not_to receive(:call)
          subject
        end
      end
    end
  end
end
