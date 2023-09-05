# frozen_string_literal: true

module Kiba::Tms::Jobs::Places::OrigNormalized
  module_function

  def job
    Kiba::Extend::Jobs::Job.new(
      files: {
        source: :places__notes_extracted,
        destination: :places__orig_normalized
      },
      transformer: xforms
    )
  end

  def xforms
    bind = binding

    Kiba.job_segment do
      config = bind.receiver.send(:config)

      if config.delete_patterns.empty?
        transform Copy::Field,
          from: :orig_combined,
          to: :norm_combined
        transform Append::NilFields,
          fields: :normalized
      else
        transform Tms::Transforms::DeletePatterns,
          fields: config.source_fields,
          patterns: config.delete_patterns
        transform Clean::StripFields,
          fields: config.source_fields
        if Tms.final_data_cleaner
          transform Tms.final_data_cleaner,
            fields: config.source_fields
        end
        transform CombineValues::FromFieldsWithDelimiter,
          sources: config.source_fields,
          target: :norm_combined,
          prepend_source_field_name: true,
          delim: "|||",
          delete_sources: false
        # Add :normalized column with "y" if :norm_combined does not
        #   equal :orig_combined
        transform do |row|
          row[:normalized] = nil
          orig = row[:orig_combined]
          norm = row[:norm_combined]
          next row if orig == norm

          row[:normalized] = "y"
          row
        end
      end
    end
  end
end
