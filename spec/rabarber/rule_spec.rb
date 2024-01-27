# frozen_string_literal: true

RSpec.describe Rabarber::Rule do
  describe "#verify_access" do
    subject { rule.verify_access(:admin, DummyController, :index) }

    let(:rule) { described_class.new(:index, :admin, -> { true }, nil) }

    context "if all conditions are met" do
      before do
        allow(rule).to receive(:action_accessible?).with(:index).and_return(true)
        allow(rule).to receive(:roles_permitted?).with(:admin).and_return(true)
        allow(rule).to receive(:dynamic_rule_followed?).with(DummyController).and_return(true)
      end

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "if at least one condition is not met" do
      context "if action is not accessible" do
        before do
          allow(rule).to receive(:action_accessible?).with(:index).and_return(false)
          allow(rule).to receive(:roles_permitted?).with(:admin).and_return(true)
          allow(rule).to receive(:dynamic_rule_followed?).with(DummyController).and_return(true)
        end

        it "returns false" do
          expect(subject).to be false
        end
      end

      context "if roles are not permitted" do
        before do
          allow(rule).to receive(:action_accessible?).with(:index).and_return(true)
          allow(rule).to receive(:roles_permitted?).with(:admin).and_return(false)
          allow(rule).to receive(:dynamic_rule_followed?).with(DummyController).and_return(true)
        end

        it "returns false" do
          expect(subject).to be false
        end
      end

      context "if dynamic rule is not followed" do
        before do
          allow(rule).to receive(:action_accessible?).with(:index).and_return(true)
          allow(rule).to receive(:roles_permitted?).with(:admin).and_return(true)
          allow(rule).to receive(:dynamic_rule_followed?).with(DummyController).and_return(false)
        end

        it "returns false" do
          expect(subject).to be false
        end
      end
    end
  end

  describe "#action_accessible?" do
    subject { rule.action_accessible?(action_name) }

    let(:rule) { described_class.new(:index, [:admin], -> { true }, nil) }

    context "if action is accesible" do
      let(:action_name) { :index }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "if action is nil" do
      let(:action_name) { nil }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "if action is not accesible" do
      let(:action_name) { :show }

      it "returns false" do
        expect(subject).to be false
      end
    end
  end

  describe "#roles_permitted?" do
    subject { rule.roles_permitted?(user_roles) }

    let(:rule) { described_class.new(:index, roles, nil, nil) }

    context "if roles are permitted" do
      let(:roles) { :admin }
      let(:user_roles) { [:manager, :admin] }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "if roles are empty" do
      let(:roles) { [] }

      context "if user is not required to have roles" do
        context "if user has roles" do
          let(:user_roles) { [:manager] }

          it "returns true" do
            expect(subject).to be true
          end
        end

        context "if user does not have roles" do
          let(:user_roles) { [] }

          it "returns true" do
            expect(subject).to be true
          end
        end
      end

      context "if user is required to have roles" do
        before { Rabarber::Configuration.instance.must_have_roles = true }

        context "if user has roles" do
          let(:user_roles) { [:manager] }

          it "returns true" do
            expect(subject).to be true
          end
        end

        context "if user does not have roles" do
          let(:user_roles) { [] }

          it "returns false" do
            expect(subject).to be false
          end
        end
      end
    end

    context "if roles are not permitted" do
      let(:roles) { :admin }
      let(:user_roles) { [:accountant, :manager] }

      it "returns false" do
        expect(subject).to be false
      end
    end
  end

  describe "#dynamic_rule_followed?" do
    subject { rule.dynamic_rule_followed?(dynamic_rule_receiver) }

    let(:dynamic_rule_receiver) { double }
    let(:rule) { described_class.new(:index, :manager, dynamic_rule, negated_dynamic_rule) }

    context "both dynamic rules are empty" do
      let(:dynamic_rule) { nil }
      let(:negated_dynamic_rule) { nil }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when dynamic rule is a proc" do
      before { allow(dynamic_rule_receiver).to receive(:params).and_return({ foo: "bar" }) }

      context "when negated dynamic rule is nil" do
        let(:negated_dynamic_rule) { nil }

        context "when dynamic rule is nil" do
          let(:dynamic_rule) { nil }

          it { is_expected.to be true }
        end

        context "when dynamic rule is followed" do
          let(:dynamic_rule) { -> { params[:foo] == "bar" } }

          it { is_expected.to be true }
        end

        context "when dynamic rule is not followed" do
          let(:dynamic_rule) { -> { params[:foo] == "baz" } }

          it { is_expected.to be false }
        end
      end

      context "when negated dynamic rule is followed" do
        let(:negated_dynamic_rule) { -> { params[:foo] == "baz" } }

        context "when dynamic rule is nil" do
          let(:dynamic_rule) { nil }

          it { is_expected.to be true }
        end

        context "when dynamic rule is followed" do
          let(:dynamic_rule) { -> { params[:foo] == "bar" } }

          it { is_expected.to be true }
        end

        context "when dynamic rule is not followed" do
          let(:dynamic_rule) { -> { params[:foo] == "baz" } }

          it { is_expected.to be false }
        end
      end

      context "when negated dynamic rule is not followed" do
        let(:negated_dynamic_rule) { -> { params[:foo] == "bar" } }

        context "when dynamic rule is nil" do
          let(:dynamic_rule) { nil }

          it { is_expected.to be false }
        end

        context "when dynamic rule is followed" do
          let(:dynamic_rule) { -> { params[:foo] == "bar" } }

          it { is_expected.to be false }
        end

        context "when dynamic rule is not followed" do
          let(:dynamic_rule) { -> { params[:foo] == "baz" } }

          it { is_expected.to be false }
        end
      end
    end

    context "when dynamic rule is a method name" do
      before do
        allow(dynamic_rule_receiver).to receive(:foo).and_return(true)
        allow(dynamic_rule_receiver).to receive(:bar).and_return(false)
      end

      context "when negated dynamic rule is nil" do
        let(:negated_dynamic_rule) { nil }

        context "when dynamic rule is nil" do
          let(:dynamic_rule) { nil }

          it { is_expected.to be true }
        end

        context "when dynamic rule is followed" do
          let(:dynamic_rule) { :foo }

          it { is_expected.to be true }
        end

        context "when dynamic rule is not followed" do
          let(:dynamic_rule) { :bar }

          it { is_expected.to be false }
        end
      end

      context "when negated dynamic rule is followed" do
        let(:negated_dynamic_rule) { :bar }

        context "when dynamic rule is nil" do
          let(:dynamic_rule) { nil }

          it { is_expected.to be true }
        end

        context "when dynamic rule is followed" do
          let(:dynamic_rule) { :foo }

          it { is_expected.to be true }
        end

        context "when dynamic rule is not followed" do
          let(:dynamic_rule) { :bar }

          it { is_expected.to be false }
        end
      end

      context "when negated dynamic rule is not followed" do
        let(:negated_dynamic_rule) { :foo }

        context "when dynamic rule is nil" do
          let(:dynamic_rule) { nil }

          it { is_expected.to be false }
        end

        context "when dynamic rule is followed" do
          let(:dynamic_rule) { :foo }

          it { is_expected.to be false }
        end

        context "when dynamic rule is not followed" do
          let(:dynamic_rule) { :bar }

          it { is_expected.to be false }
        end
      end
    end
  end
end
