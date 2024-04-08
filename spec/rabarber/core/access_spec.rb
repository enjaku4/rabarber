# frozen_string_literal: true

RSpec.describe Rabarber::Core::Access do
  let(:permissions) { Class.new(Rabarber::Core::Permissions) }

  before { permissions.extend(described_class) }

  describe ".access_granted?" do
    subject { permissions.access_granted?([:admin, :client], DummyController, :index, dynamic_rule_receiver) }

    let(:dynamic_rule_receiver) { double }

    context "if controller is accessible" do
      before do
        allow(permissions).to receive(:controller_accessible?)
          .with([:admin, :client], DummyController, dynamic_rule_receiver).and_return(true)
        allow(permissions).to receive(:action_accessible?)
          .with([:admin, :client], DummyController, :index, dynamic_rule_receiver).and_return(false)
      end

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "if action is accessible" do
      before do
        allow(permissions).to receive(:controller_accessible?)
          .with([:admin, :client], DummyController, dynamic_rule_receiver).and_return(false)
        allow(permissions).to receive(:action_accessible?)
          .with([:admin, :client], DummyController, :index, dynamic_rule_receiver).and_return(true)
      end

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "if controller and action are not accessible" do
      before do
        allow(permissions).to receive(:controller_accessible?)
          .with([:admin, :client], DummyController, dynamic_rule_receiver).and_return(false)
        allow(permissions).to receive(:action_accessible?)
          .with([:admin, :client], DummyController, :index, dynamic_rule_receiver).and_return(false)
      end

      it "returns false" do
        expect(subject).to be false
      end
    end
  end

  describe ".controller_accessible?" do
    subject { permissions.controller_accessible?([:admin], controller, dynamic_rule_receiver) }

    let(:dynamic_rule_receiver) { double }

    before { permissions.add(DummyParentController, nil, [:admin], nil, nil) }

    context "if controller is in permissions" do
      let(:controller) { DummyParentController }

      context "if role has access to the controller" do
        before do
          allow(permissions.controller_rules[controller]).to receive(:verify_access)
            .with([:admin], dynamic_rule_receiver).and_return(true)
        end

        it "returns true" do
          expect(subject).to be true
        end
      end

      context "if role doesn't have access to the controller" do
        before do
          allow(permissions.controller_rules[controller]).to receive(:verify_access)
            .with([:admin], dynamic_rule_receiver).and_return(false)
        end

        it "returns false" do
          expect(subject).to be false
        end
      end
    end

    context "if controller's parent is in permissions" do
      let(:controller) { DummyChildController }

      context "if role has access to the controller's parent" do
        before do
          allow(permissions.controller_rules[DummyParentController]).to receive(:verify_access)
            .with([:admin], dynamic_rule_receiver).and_return(true)
        end

        it "returns true" do
          expect(subject).to be true
        end
      end

      context "if role doesn't have access to the controller's parent" do
        before do
          allow(permissions.controller_rules[DummyParentController]).to receive(:verify_access)
            .with([:admin], dynamic_rule_receiver).and_return(false)
        end

        it "returns false" do
          expect(subject).to be false
        end
      end
    end

    context "if controller is not in permissions" do
      let(:controller) { DummyPagesController }

      it "returns false" do
        expect(subject).to be false
      end
    end
  end

  describe ".action_accessible?" do
    subject { permissions.action_accessible?([:admin], controller, action, dynamic_rule_receiver) }

    let(:dynamic_rule_receiver) { double }

    before { permissions.add(DummyController, :index, [:admin], nil, nil) }

    context "if controller is in permissions" do
      let(:controller) { DummyController }

      context "if action is in permissions" do
        let(:action) { :index }

        context "if role has access to the action" do
          before do
            allow(permissions.action_rules[controller].first).to receive(:verify_access)
              .with([:admin], dynamic_rule_receiver).and_return(true)
          end

          it "returns true" do
            expect(subject).to be true
          end
        end

        context "if role doesn't have access to the action" do
          before do
            allow(permissions.action_rules[controller].first).to receive(:verify_access)
              .with([:admin], dynamic_rule_receiver).and_return(false)
          end

          it "returns false" do
            expect(subject).to be false
          end
        end
      end

      context "if action is not in permissions" do
        let(:action) { :show }

        it "returns false" do
          expect(subject).to be false
        end
      end
    end

    context "if controller is not in permissions" do
      let(:action) { :index }
      let(:controller) { DummyPagesController }

      it "returns false" do
        expect(subject).to be false
      end
    end
  end
end
