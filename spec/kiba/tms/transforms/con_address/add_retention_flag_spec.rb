# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::ConAddress::AddRetentionFlag do
  subject(:xform) { described_class.new }
  let(:result) { input.map { |row| xform.process(row) } }
  let(:input) do
    [
      {matches_constituent: "1", streetline1: "1", active: "1"},
      {matches_constituent: "1", streetline1: "1", active: "0"},
      {matches_constituent: "", streetline1: "1", active: "1"},
      {matches_constituent: "1", streetline1: "", active: "1"},
      {foo: "bar"}
    ]
  end

  context "when migrate_inactive true" do
    before(:all) { Tms::ConAddress.config.migrate_inactive = true }
    after(:all) { Tms::ConAddress.reset_config }
    let(:expected) do
      [
        {streetline1: "1", active: "1", keeping: "y"},
        {streetline1: "1", active: "0", keeping: "y"},
        {streetline1: "1", active: "1",
         keeping: "n - associated constituent not migrating"},
        {streetline1: "", active: "1", keeping: "n - no address data in row"},
        {foo: "bar", keeping: "n - associated constituent not migrating"}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end

  context "when migrate_inactive false" do
    before(:all) { Tms::ConAddress.config.migrate_inactive = false }
    after(:all) { Tms::ConAddress.reset_config }
    let(:expected) do
      [
        {streetline1: "1", active: "1", keeping: "y"},
        {streetline1: "1", active: "0", keeping: "n - inactive address"},
        {streetline1: "1", active: "1",
         keeping: "n - associated constituent not migrating"},
        {streetline1: "", active: "1", keeping: "n - no address data in row"},
        {foo: "bar", keeping: "n - associated constituent not migrating"}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end
end
