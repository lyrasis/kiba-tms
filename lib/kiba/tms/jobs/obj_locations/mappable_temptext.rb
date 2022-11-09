# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module MappableTemptext
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_locations,
                destination: :obj_locations__mappable_temptext,
                lookup: :prep__locations
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :temptext

              transform Delete::FieldsExcept,
                fields: (
                config.fulllocid_fields +
                  %i[objectnumber transdate dateout temptext]
                ).uniq

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[temptext loclevel sublevel],
                target: :combined,
                sep: ' ',
                delete_sources: false,
                prepend_source_field_name: true
              transform Deduplicate::Table,
                field: :combined,
                delete_field: true

              transform Merge::MultiRowLookup,
                lookup: prep__locations,
                keycolumn: :locationid,
                fieldmap: {loc1: :tmslocationstring}
              transform Delete::Fields, fields: :locationid
              transform Append::NilFields,
                fields: %i[mapping corrected_value]
              transform Rename::Fields, fieldmap: {
                loclevel: :loc3,
                sublevel: :loc5
              }
            end
          end
        end
      end
    end
  end
end
