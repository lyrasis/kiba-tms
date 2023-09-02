# frozen_string_literal: true

module Kiba::Tms::Jobs::Places::FinalReturnedCompile
  module_function

  def job
    return unless config.final_cleanup_done

    Kiba::Extend::Jobs::Job.new(
      files: {
        source: config.final_returned_jobs,
        destination: :places__final_returned_compile
      },
      transformer: xforms
    )
  end

  def xforms
    bind = binding

    Kiba.job_segment do
      config = bind.receiver.send(:config)

      transform Delete::Fields,
        fields: %i[to_review]
      transform Fingerprint::FlagChanged,
        fingerprint: :fingerprint,
        source_fields: config.final_wksht_fp_fields,
        delete_fp: false,
        target: :corrected
      transform Delete::Fields,
        fields: :fp_add_variant
      transform Rename::Field,
        from: :fp_place,
        to: :norm
      transform Clean::EnsureConsistentFields
    end
  end
end
