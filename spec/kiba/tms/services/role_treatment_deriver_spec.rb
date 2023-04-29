# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Services::RoleTreatmentDeriver do
  subject(:klass){ described_class }

  describe ".new" do
    it "implicitly ineligible mod returns barely initialized instance" do
      mod = class_double("ImplicitlyIneligibleMod").as_stubbed_const
      instance = klass.new(mod: mod)
      expect(instance.send(:mod)).to eq(mod)
      expect(instance.send(:colobj)).to be_nil
    end

    it "explicitly ineligible mod returns barely initialized instance" do
      mod = class_double("ExplicitlyIneligibleMod").as_stubbed_const
      allow(mod).to receive(:gets_roles_merged_in?).and_return(false)
      instance = klass.new(mod: mod)
      expect(instance.send(:mod)).to eq(mod)
      expect(instance.send(:colobj)).to be_nil
    end

    it "eligible mod returns fully initialized instance" do
      mapping = {
        owner: ["Donor", "Owner"], unmapped: ["Unknown"]
      }
      mod = class_double("EligibleMod").as_stubbed_const
      allow(mod).to receive(:gets_roles_merged_in?).and_return(true)
      allow(mod).to receive(:con_ref_role_to_field_mapping).and_return(mapping)
      instance = klass.new(mod: mod)
      expect(instance.send(:mod)).to eq(mod)
      expect(instance.send(:colobj)).to eq(Tms::Data::Column)
      expect(instance.send(:current_mapping)).to eq(mapping)
      expect(instance.send(:known_roles)).to eq(mapping[:owner])
    end
  end

  describe ".call" do
    it "returns failure for implicitly ineligible module" do
      mod = class_double("ImplicitlyIneligibleMod").as_stubbed_const
      result = klass.call(mod: mod)

      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure.mod).to eq(mod)
      expect(result.failure.name).to eq(:con_ref_role_to_field_mapping)
      expect(result.failure.sym).to eq(:missing_eligibility_setting)
    end

    it "returns failure for explicitly ineligible module" do
      mod = class_double("ExplicitlyIneligibleMod").as_stubbed_const
      allow(mod).to receive(:gets_roles_merged_in?).and_return(false)
      result = klass.call(mod: mod)

      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure.mod).to eq(mod)
      expect(result.failure.name).to eq(:con_ref_role_to_field_mapping)
      expect(result.failure.sym).to eq(:not_eligible)
    end

    it "eligible module with no new values returns same mapping (sorted)" do
      mapping = {
        owner: ["Owner", "Donor"], unmapped: ["Unknown"]
      }
      mod = class_double("EligibleMod").as_stubbed_const
      allow(mod).to receive(:gets_roles_merged_in?).and_return(true)
      allow(mod).to receive(:con_ref_role_to_field_mapping).and_return(mapping)
      allow(mod).to receive(:table_name).and_return("Objects")

      rolemod = class_double("ConRefsForObjects").as_stubbed_const
      allow(Tms).to receive(:const_get).and_return(rolemod)

      colklass = class_double("Column").as_stubbed_const
      col = instance_double("Column")
      allow(colklass).to receive(:new).and_return(col)
      allow(col).to receive(:unique_values).and_return(
        Dry::Monads::Success(["Donor", "Owner", "Unknown"])
      )

      result = klass.call(mod: mod, col: colklass)

      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!).to be_a(Tms::Data::ConfigSetting)
      expect(result.value!.mod).to eq(mod)
      expect(result.value!.name).to eq(:con_ref_role_to_field_mapping)
      expect(result.value!.value).to eq({
        owner: ["Donor", "Owner"], unmapped: ["Unknown"]
      })
    end

    it "eligible module with new values returns additional unmapped value" do
      mapping = {
        owner: ["Donor"], unmapped: ["Unknown"]
      }
      mod = class_double("EligibleMod").as_stubbed_const
      allow(mod).to receive(:gets_roles_merged_in?).and_return(true)
      allow(mod).to receive(:con_ref_role_to_field_mapping).and_return(mapping)
      allow(mod).to receive(:table_name).and_return("Objects")

      rolemod = class_double("ConRefsForObjects").as_stubbed_const
      allow(Tms).to receive(:const_get).and_return(rolemod)

      colklass = class_double("Column").as_stubbed_const
      col = instance_double("Column")
      allow(colklass).to receive(:new).and_return(col)
      allow(col).to receive(:unique_values).and_return(
        Dry::Monads::Success(["Donor", "Owner", "Unknown"])
      )

      result = klass.call(mod: mod, col: colklass)

      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!).to be_a(Tms::Data::ConfigSetting)
      expect(result.value!.mod).to eq(mod)
      expect(result.value!.name).to eq(:con_ref_role_to_field_mapping)
      expect(result.value!.value).to eq({
        owner: ["Donor"], unmapped: ["Owner", "Unknown"]
      })
    end

    it "eligible module without rolemod returns failure" do
      mapping = {
        owner: ["Donor"], unmapped: ["Unknown"]
      }
      mod = class_double("WeirdMod").as_stubbed_const
      allow(mod).to receive(:gets_roles_merged_in?).and_return(true)
      allow(mod).to receive(:con_ref_role_to_field_mapping).and_return(mapping)
      allow(mod).to receive(:table_name).and_return("Object")

      allow(Tms).to receive(:const_get).and_raise(StandardError)

      result = klass.call(mod: mod)

      expect(result).to be_a(Dry::Monads::Failure)
    end

    it "eligible module when can't get column" do
      mapping = {
        owner: ["Donor"], unmapped: ["Unknown"]
      }
      mod = class_double("EligibleMod").as_stubbed_const
      allow(mod).to receive(:gets_roles_merged_in?).and_return(true)
      allow(mod).to receive(:con_ref_role_to_field_mapping).and_return(mapping)
      allow(mod).to receive(:table_name).and_return("Objects")

      rolemod = class_double("ConRefsForObjects").as_stubbed_const
      allow(Tms).to receive(:const_get).and_return(rolemod)

      colklass = class_double("Column").as_stubbed_const
      allow(colklass).to receive(:new).and_raise(StandardError)

      result = klass.call(mod: mod, col: colklass)

      expect(result).to be_a(Dry::Monads::Failure)
    end
  end
end
