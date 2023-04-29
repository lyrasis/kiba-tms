# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaXrefs
        module Objects
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_xrefs_for__objects,
                destination: :media_xrefs__objects,
                lookup: %i[
                           media_files__id_lookup
                           objects__number_lookup
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[mediamasterid id]
              transform Merge::MultiRowLookup,
                lookup: objects__number_lookup,
                keycolumn: :id,
                fieldmap: {item1_id: :objectnumber}
              transform Merge::MultiRowLookup,
                lookup: media_files__id_lookup,
                keycolumn: :mediamasterid,
                fieldmap: {item2_id: :identificationnumber}
              transform Merge::ConstantValues, constantmap: {
                item1_type: "collectionobjects",
                item2_type: "media"
              }
            end
          end
        end
      end
    end
  end
end
