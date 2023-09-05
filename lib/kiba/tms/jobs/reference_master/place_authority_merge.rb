# frozen_string_literal: true

module Kiba::Tms::Jobs::ReferenceMaster::PlaceAuthorityMerge
  module_function

  def job
    return unless config.used?
    return unless lookups.include?(:places__final_cleaned_lookup)

    Kiba::Extend::Jobs::Job.new(
      files: {
        source: :reference_master__places,
        destination: :reference_master__place_authority_merge,
        lookup: lookups
      },
      transformer: xforms
    )
  end

  def lookups
    base = %i[
      places__final_cleaned_lookup
    ]
    base.select { |job| Kiba::Extend::Job.output?(job) }
  end

  def xforms
    Kiba.job_segment do
      transform Merge::MultiRowLookup,
        lookup: places__final_cleaned_lookup,
        keycolumn: :orig_combined,
        fieldmap: {
          place: :place,
          note: :note
        },
        null_placeholder: "%NULLVALUE%"
      transform FilterRows::FieldPopulated,
        action: :keep,
        field: :place
      transform Deduplicate::FieldValues,
        fields: %i[place note],
        sep: "|"
      transform Delete::EmptyFieldValues,
        fields: :note,
        usenull: true
    end
  end
end
