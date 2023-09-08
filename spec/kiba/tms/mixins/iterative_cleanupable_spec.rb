# frozen_string_literal: true

require "spec_helper"

module Kiba::Tms::WithoutSourceJobKey
  module_function
end

module Kiba::Tms::WithSetup
  module_function

  extend Dry::Configurable
  setting :source_job_key, default: :test__me, reader: true
end

RSpec.describe Kiba::Tms::Mixins::IterativeCleanupable do
  let(:subject) { described_class }

  describe ".extended" do
    context "when extended without :source_job_key" do
      let(:mod) { Tms::WithoutSourceJobKey }

      it "raises error" do
        expect { mod.extend(subject) }.to raise_error(
          Tms::SourceJobKeyUndefinedError
        )
      end
    end

    context "when extended with required setup" do
      let(:mod) { Tms::WithSetup }

      it "extends Tableable and IterativeCleanupable" do
        mod.extend(subject)
        expect(mod).to be_a(Tms::Mixins::Tableable)
        expect(mod).to be_a(subject)
      end
    end
  end
end
