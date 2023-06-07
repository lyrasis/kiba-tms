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
              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: config.content_fields - [:geocodeid]
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
                delim: "|||",
                delete_sources: false
            end
          end
        end
      end
    end
  end
end
