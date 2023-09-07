# frozen_string_literal: true

require "spec_helper"

module Kiba::Tms::UsedMod
  module_function

  def used?
    "cat"
  end

  extend Tms::Mixins::CsTargetable
end

module Kiba::Tms::Csrec
  extend Tms::Mixins::CsTargetable
end

module Kiba::Tms::UnusedCs
  extend Tms::Mixins::CsTargetable
end

RSpec.describe Kiba::Tms::Mixins::CsTargetable do
  before(:all) { Tms.config.cspace_target_records = ["Csrec"] }
  after(:all) { Tms.reset_config }
  it "does not redefine existing :used? method" do
    expect(Tms::UsedMod.used?).to eq("cat")
  end

  it "defines missing :used? method" do
    expect(Tms::Csrec.respond_to?(:used?)).to be true
    expect(Tms::Csrec.used?).to be true
    expect(Tms::UnusedCs.used?).to be false
  end
end
