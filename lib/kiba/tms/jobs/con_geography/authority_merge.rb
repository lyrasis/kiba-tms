# frozen_string_literal: true

module Kiba::Tms::Jobs::ConGeography::AuthorityMerge
  module_function

  def job
    return unless config.used?
    return unless lookups.include?(:places__final_cleaned_lookup)

    Kiba::Extend::Jobs::Job.new(
      files: {
        source: :prep__con_geography,
        destination: :con_geography__authority_merge,
        lookup: lookups
      },
      transformer: xforms
    )
  end

  def lookups
    base = []
    base << :places__final_cleaned_lookup
    base.select { |job| Kiba::Extend::Job.output?(job) }
  end

  def xforms
    bind = binding

    Kiba.job_segment do
      config = bind.receiver.send(:config)

      transform FilterRows::WithLambda,
        action: :keep,
        lambda: config.controlled_type_condition

      transform Delete::FieldsExcept,
        fields: %i[congeographyid constituentid geocode orig_combined]
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
    end
  end
end
