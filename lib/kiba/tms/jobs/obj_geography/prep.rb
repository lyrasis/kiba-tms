# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_geography,
                destination: :prep__obj_geography,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
                      prep__geo_codes
                     ]
            base.select{ |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              lookups = bind.receiver.send(:lookups)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner

              unless config.prep_cleaners.empty?
                config.prep_cleaners.each do |cleaner|
                  transform cleaner
                end
              end

              if lookups.any?(:prep__geo_codes)
                transform Merge::MultiRowLookup,
                  lookup: prep__geo_codes,
                  keycolumn: Tms::GeoCodes.id_field,
                  fieldmap: {Tms::GeoCodes.type_field=>Tms::GeoCodes.type_field}
              end
              transform Delete::Fields, fields: Tms::GeoCodes.id_field

              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.content_fields,
                target: :orig_combined,
                prepend_source_field_name: true,
                delim: " -- ",
                delete_sources: false

              if config.proximity_as_note
                transform Tms::Transforms::SetNoteFromPattern,
                  fields: config.content_fields,
                  patterns: config.proximity_patterns,
                  target: :proximity
              end
              if config.uncertainty_as_note
                transform Tms::Transforms::SetNoteFromPattern,
                  fields: config.content_fields,
                  patterns: config.uncertainty_patterns,
                  target: :uncertainty
              end
              unless config.misc_note_patterns.empty?
                transform Tms::Transforms::SetNoteFromPattern,
                  fields: config.content_fields,
                  patterns: config.misc_note_patterns,
                  target: :misc_note
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
                  patterns: config.delete_patterns
                transform Clean::StripFields,
                  fields: config.content_fields
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.content_fields,
                  target: :norm_combined,
                  prepend_source_field_name: true,
                  delim: " -- ",
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
