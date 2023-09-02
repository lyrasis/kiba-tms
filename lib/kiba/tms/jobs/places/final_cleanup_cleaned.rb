# frozen_string_literal: true

module Kiba::Tms::Jobs::Places::FinalCleanupCleaned
  module_function

  def job
    return unless config.final_cleanup_done

    Kiba::Extend::Jobs::Job.new(
      files: {
        source: :places__final_returned_compile,
        destination: :places__final_cleanup_cleaned,
        lookup: :places__final_cleanup_corrections
      },
      transformer: xforms
    )
  end

  def xforms
    Kiba.job_segment do
      transform Fingerprint::MergeCorrected,
        keycolumn: :fingerprint,
        lookup: places__final_cleanup_corrections,
        todofield: :corrected,
        tag_affected_in: :changes_applied
    end
  end
end
