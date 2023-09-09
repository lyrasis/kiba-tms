# frozen_string_literal: true

module Kiba::Tms::Jobs::IterativeCleanup::BaseJobCleaned
  module_function

  def job(mod:)
    Kiba::Extend::Jobs::Job.new(
      files: {
        source: mod.base_job,
        destination: mod.base_job_cleaned_job_key,
        lookup: get_lookups(mod)
      },
      transformer: get_xforms(mod)
    )
  end

  def get_lookups(mod)
    base = []
    base << mod.corrections_job_key if mod.cleanup_done?
    base.select { |job| Kiba::Extend::Job.output?(job) }
  end

  def get_xforms(mod)
    base = []
    if mod.respond_to?(:base_job_cleaned_pre_xforms)
      base << mod.base_job_cleaned_pre_xforms
    end
    base << xforms(mod)
    if mod.respond_to?(:base_job_cleaned_post_xforms)
      base << mod.base_job_cleaned_post_xforms
    end
    base
  end

  def xforms(mod)
    bind = binding

    Kiba.job_segment do
      lookups = bind.receiver.send(:get_lookups, mod)

      transform Append::NilFields,
        fields: mod.worksheet_add_fields

      if mod.cleanup_done? && lookups.any?(mod.corrections_job_key)
        transform Fingerprint::MergeCorrected,
          lookup: method(mod.corrections_job_key).send,
          keycolumn: :fingerprint,
          todofield: :corrected
      end

      transform CombineValues::FromFieldsWithDelimiter,
        sources: mod.fingerprint_fields,
        target: :clean_combined,
        delim: "|||",
        prepend_source_field_name: true,
        delete_sources: false
    end
  end
end
