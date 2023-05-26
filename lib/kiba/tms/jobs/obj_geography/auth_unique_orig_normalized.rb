# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module AuthUniqueOrigNormalized
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_geography__auth_unique_orig,
                destination: :obj_geography__auth_unique_orig_normalized
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if config.proximity_as_note
                transform Tms::Transforms::SetNoteFromPattern,
                  fields: config.content_fields,
                  patterns: config.proximity_patterns,
                  target: :proximity,
                  conditions: config.controlled_type_condition
              end
              if config.uncertainty_as_note
                transform Tms::Transforms::SetNoteFromPattern,
                  fields: config.content_fields,
                  patterns: config.uncertainty_patterns,
                  target: :uncertainty,
                  conditions: config.controlled_type_condition
              end
              unless config.misc_note_patterns.empty?
                transform Tms::Transforms::SetNoteFromPattern,
                  fields: config.content_fields,
                  patterns: config.misc_note_patterns,
                  target: :misc_note,
                  conditions: config.controlled_type_condition
              end

              if config.delete_patterns.empty?
                transform Copy::Field,
                  from: :orig_combined,
                  to: :norm_combined
                transform Append::NilFields,
                  fields: :normalized
              else
                transform Tms::Transforms::DeletePatterns,
                  fields: config.content_fields,
                  patterns: config.delete_patterns,
                  conditions: config.controlled_type_condition
                transform Clean::StripFields,
                  fields: config.content_fields
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.content_fields,
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
      end
    end
  end
end
