# frozen_string_literal: true

require "spec_helper"

module Kiba::Tms::WithoutCleanupBaseName
  module_function
end

module Kiba::Tms::WithoutBaseJob
  module_function

  extend Dry::Configurable
  setting :cleanup_base_name, default: :test__me, reader: true
end

module Kiba::Tms::WithSetup
  module_function

  extend Dry::Configurable
  setting :cleanup_base_name, default: "test_cleanup", reader: true
  setting :base_job, default: :base__job, reader: true
  setting :job_tags, default: %i[test cleanup], reader: true
  setting :worksheet_add_fields,
    default: %i[type note],
    reader: true
  setting :worksheet_field_order,
    default: %i[value type note],
    reader: true
  setting :fingerprint_fields,
    default: %i[value type note],
    reader: true
  setting :fingerprint_flag_ignore_fields, default: nil, reader: true
end

RSpec.describe Kiba::Tms::Mixins::IterativeCleanupable do
  let(:subject) { described_class }

  describe ".extended" do
    context "when extended without :cleanup_base_name" do
      let(:mod) { Tms::WithoutCleanupBaseName }

      it "raises error" do
        expect { mod.extend(subject) }.to raise_error(
          Tms::SettingUndefinedError
        )
      end
    end

    context "when extended with required setup" do
      let(:mod) { Tms::WithSetup }

      it "extends IterativeCleanupable" do
        mod.extend(subject)
        expect(mod).to be_a(subject)
        expect(mod).to respond_to(:provided_worksheets, :returned_files,
          :provided_worksheet_jobs, :returned_file_jobs, :cleanup_done?)
      end
    end
  end
end
