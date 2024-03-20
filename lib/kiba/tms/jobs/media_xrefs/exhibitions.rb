# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaXrefs
        module Exhibitions
          module_function

          def job
            return unless config.used?
            return unless config.for?("Exhibitions")

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_xrefs_for__exhibitions,
                destination: :media_xrefs__exhibitions,
                lookup: %i[
                  media_files__id_lookup
                  exhibitions__shaped
                ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[mediamasterid id]
              transform Merge::MultiRowLookup,
                lookup: exhibitions__shaped,
                keycolumn: :id,
                fieldmap: {item1_id: :exhibitionnumber}
              transform Merge::MultiRowLookup,
                lookup: media_files__id_lookup,
                keycolumn: :mediamasterid,
                fieldmap: {item2_id: :identificationnumber}
              transform Delete::Fields, fields: %i[mediamasterid id]
              transform Merge::ConstantValues, constantmap: {
                item1_type: "exhibitions",
                item2_type: "media"
              }
              transform FilterRows::AllFieldsPopulated,
                action: :keep,
                fields: %i[item1_id item2_id]
              transform CombineValues::FullRecord
              transform Deduplicate::Table,
                field: :index,
                delete_field: true
            end
          end
        end
      end
    end
  end
end
