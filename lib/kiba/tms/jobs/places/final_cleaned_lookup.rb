# frozen_string_literal: true

module Kiba::Tms::Jobs::Places::FinalCleanedLookup
  module_function

  def job
    return unless config.final_cleanup_done

    Kiba::Extend::Jobs::Job.new(
      files: {
        source: :places__init_cleaned_lookup,
        destination: :places__final_cleaned_lookup,
        lookup: %i[
          places__final_cleanup_cleaned
          places__orig_normalized
          places__cleaned_notes
        ]
      },
      transformer: xforms
    )
  end

  def xforms
    bind = binding

    Kiba.job_segment do
      config = bind.receiver.send(:config)

      transform Merge::MultiRowLookup,
        lookup: places__final_cleanup_cleaned,
        keycolumn: :norm,
        fieldmap: {place: :place}
      config.worksheet_added_fields.each do |field|
        transform Merge::MultiRowLookup,
          lookup: places__cleaned_notes,
          keycolumn: :norm_combined,
          fieldmap: {field => field}
      end
      transform Merge::MultiRowLookup,
        lookup: places__orig_normalized,
        keycolumn: :norm_combined,
        fieldmap: {orig_combined: :orig_combined},
        delim: config.norm_fingerprint_delim
      config.worksheet_added_fields.each do |field|
        transform Tms::Transforms::Places::UniquifyWorksheetPlaceNote,
          notefield: field
      end
      transform Delete::FieldsExcept,
        fields: [:place, :orig_combined,
          config.worksheet_added_fields].flatten
      transform Explode::RowsFromMultivalField,
        field: :orig_combined,
        delim: config.norm_fingerprint_delim
    end
  end
end
