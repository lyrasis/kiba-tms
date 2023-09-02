# frozen_string_literal: true

module Kiba::Tms::Jobs::Places::FinalCleanupCorrections
  module_function

  def job
    return unless config.cleanup_done

    Kiba::Extend::Jobs::Job.new(
      files: {
        source: :places__final_returned_compile,
        destination: :places__final_cleanup_corrections
      },
      transformer: xforms
    )
  end

  def xforms
    Kiba.job_segment do
      transform Delete::Fields,
        fields: %i[normalized_variants orig orig_ct clustered]
      transform FilterRows::FieldPopulated,
        action: :keep,
        field: :corrected
    end
  end
end
