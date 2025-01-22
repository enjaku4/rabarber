# frozen_string_literal: true

RSpec.describe Rabarber::Core::Rule do
  describe "#verify_access" do
    subject { rule.verify_access(roleable, DummyController) }

    let(:roleable) { double }
    let(:rule) { described_class.new(:admin, -> { Project }, -> { true }, nil) }

    context "if all conditions are met" do
      before do
        allow(rule).to receive(:roles_permitted?).with(roleable, DummyController).and_return(true)
        allow(rule).to receive(:dynamic_rules_followed?).with(DummyController).and_return(true)
      end

      it { is_expected.to be true }
    end

    context "if one condition is not met" do
      context "if roles are not permitted" do
        before do
          allow(rule).to receive(:roles_permitted?).with(roleable, DummyController).and_return(false)
          allow(rule).to receive(:dynamic_rules_followed?).with(DummyController).and_return(true)
        end

        it { is_expected.to be false }
      end

      context "if dynamic rules are not followed" do
        before do
          allow(rule).to receive(:roles_permitted?).with(roleable, DummyController).and_return(true)
          allow(rule).to receive(:dynamic_rules_followed?).with(DummyController).and_return(false)
        end

        it { is_expected.to be false }
      end
    end
  end

  describe "#roles_permitted?" do
    subject { rule.roles_permitted?(roleable, DummyController.new) }

    let(:rule) { described_class.new(roles, { context_type: "Project", context_id: nil }, nil, nil) }

    context "when roleable is a User" do
      let(:roleable) { User.create! }

      before { roleable.assign_roles(*user_roles, context: Project) }

      context "if roles are permitted" do
        let(:roles) { :admin }
        let(:user_roles) { [:manager, :admin] }

        it { is_expected.to be true }
      end

      context "if roles are empty" do
        let(:roles) { [] }

        context "if must_have_roles is false" do
          context "if user has roles" do
            let(:user_roles) { [:manager] }

            it { is_expected.to be true }
          end

          context "if user does not have roles" do
            let(:user_roles) { [] }

            it { is_expected.to be true }
          end
        end

        context "if must_have_roles is true" do
          before { Rabarber::Configuration.instance.must_have_roles = true }

          context "if user has roles" do
            let(:user_roles) { [:manager] }

            it { is_expected.to be true }
          end

          context "if user does not have roles" do
            let(:user_roles) { [] }

            it { is_expected.to be false }
          end
        end
      end

      context "if roles are not permitted" do
        let(:roles) { :admin }
        let(:user_roles) { [:accountant, :manager] }

        it { is_expected.to be false }
      end
    end

    context "when roleable is NullRoleable" do
      let(:roleable) { Rabarber::Core::NullRoleable.new }

      context "if rule has roles" do
        let(:roles) { :admin }

        it { is_expected.to be false }
      end

      context "if rule doesn't have roles" do
        let(:roles) { [] }

        context "if must_have_roles is false" do
          it { is_expected.to be true }
        end

        context "if must_have_roles is true" do
          before { Rabarber::Configuration.instance.must_have_roles = true }

          it { is_expected.to be false }
        end
      end
    end
  end

  describe "#dynamic_rules_followed?" do
    subject { rule.dynamic_rules_followed?(controller_instance) }

    let(:controller_instance) { double }
    let(:rule) { described_class.new(:manager, nil, dynamic_rule, negated_dynamic_rule) }

    context "both dynamic rules are empty" do
      let(:dynamic_rule) { nil }
      let(:negated_dynamic_rule) { nil }

      it { is_expected.to be true }
    end

    context "when dynamic rule is a proc" do
      before { allow(controller_instance).to receive(:params).and_return({ foo: "bar" }) }

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
      before { allow(controller_instance).to receive_messages(foo: true, bar: false) }

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
