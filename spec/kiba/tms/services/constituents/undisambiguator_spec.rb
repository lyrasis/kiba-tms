# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Services::Constituents::Undisambiguator do
  subject { described_class }

  describe ".call" do
    let(:name) { "Saint Louis Art Museum (duplicate 11273)" }
    let(:result) { subject.new.call(name) }

    it "returns name when pattern not set" do
      Kiba::Tms::Constituents.config.duplicate_disambiguation_string = nil
      expect(result).to eq(name)
    end

    it "returns name without disambiguation when default" do
      Kiba::Tms::Constituents.config.duplicate_disambiguation_string =
        " (duplicate %int%)"
      expect(result).to eq("Saint Louis Art Museum")
    end
  end
end
