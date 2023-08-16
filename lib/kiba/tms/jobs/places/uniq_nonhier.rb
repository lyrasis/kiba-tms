# frozen_string_literal: true

module Kiba::Tms::Jobs::Places::UniqNonhier
  module_function

  def job
    return unless config.used?

    Kiba::Extend::Jobs::Job.new(
      files: {
        source: :places__build_nonhier,
        destination: :places__uniq_nonhier,
        lookup: :places__build_nonhier
      },
      transformer: xforms
    )
  end

  def xforms
    bind = binding

    Kiba.job_segment do
      config = bind.receiver.send(:config)

      transform Delete::FieldsExcept,
        fields: :norm
      transform Deduplicate::Table,
        field: :norm
      transform Merge::MultiRowLookup,
        lookup: places__build_nonhier,
        keycolumn: :norm,
        fieldmap: {norm_combineds: :norm_combineds},
        delim: config.norm_fingerprint_delim
      transform Merge::MultiRowLookup,
        lookup: places__build_nonhier,
        keycolumn: :norm,
        fieldmap: {orig: :place}
      transform do |row|
        orig = row[:orig]
        vals = orig.split(Tms.delim)
          .uniq
        row[:orig] = vals.join(Tms.delim)
        row[:orig_ct] = vals.length
        row
      end
      if config.qualify_non_hierarchical_terms
        transform Kiba::Tms::Transforms::Places::QualifyMultifieldNonhier
      end
    end
  end
end
