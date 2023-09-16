# frozen_string_literal: true

require "spec_helper"

module Kiba::Tms::MtmNoCleanup
  extend Dry::Configurable
  setting :for_table_source_job_key, default: :mtm__no_cleanup, reader: true
  include Kiba::Tms::AltNums
end

module Kiba::Tms::MtmCleanupSetup
  extend Dry::Configurable
  setting :for_table_source_job_key, default: :mtm__cleanup, reader: true
  setting :target_table_type_cleanup_needed, default: ["Objects"], reader: true
  setting :type_field, default: :type, reader: true
  include Kiba::Tms::AltNums
end

module Kiba::Tms::MtmCleanupNoTypeField
  extend Dry::Configurable
  setting :for_table_source_job_key, default: :mtm__cleanup, reader: true
  setting :target_table_type_cleanup_needed, default: ["Objects"], reader: true
  include Kiba::Tms::AltNums
end

RSpec.describe Kiba::Tms::Mixins::MultiTableMergeable do
  subject(:mixin) { described_class }

  describe ".type_cleanable?" do
    let(:result) { mod.type_cleanable? }

    context "when no cleanup needed" do
      let(:mod) { Kiba::Tms::MtmNoCleanup }

      it "returns false" do
        mod.extend(subject)
        expect(result).to be false
      end
    end

    context "when cleanup needed and set up" do
      let(:mod) { Kiba::Tms::MtmCleanupSetup }

      it "returns true" do
        mod.extend(subject)
        expect(result).to be true
      end
    end

    context "when cleanup needed but not set up" do
      let(:mod) { Kiba::Tms::MtmCleanupNoTypeField }

      it "returns false and warns" do
        mod.extend(subject)
        msg = "You need to define `:type_field` in #{mod} to enable "\
               "for-table type cleanup for Objects"
        expect(mod).to receive(:warn).with(msg)
        expect(result).to be false
      end
    end
  end
end
