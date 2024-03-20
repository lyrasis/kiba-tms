# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaXrefs
        module ObjRights
          module_function

          def job
            return unless config.used?
            return unless Tms::ObjRights.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_xrefs_for__obj_rights,
                destination: :media_xrefs__obj_rights,
                lookup: %i[
                  media_files__id_lookup
                  prep__obj_rights
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
                lookup: prep__obj_rights,
                keycolumn: :id,
                fieldmap: {objectid: :objectid}
              transform Merge::MultiRowLookup,
                lookup: objects__number_lookup,
                keycolumn: :objectid,
                fieldmap: {item1_id: :objectnumber}
              transform Merge::MultiRowLookup,
                lookup: media_files__id_lookup,
                keycolumn: :mediamasterid,
                fieldmap: {item2_id: :identificationnumber}
              transform Merge::ConstantValues, constantmap: {
                item1_type: "collectionobjects",
                item2_type: "media"
              }
              transform FilterRows::AllFieldsPopulated,
                action: :keep,
                fields: %i[item1_id item2_id]
              transform Delete::FieldsExcept,
                fields: %i[item1_id item2_id item1_type item2_type]
              transform CombineValues::FullRecord,
                prepend_source_field_name: false,
                delim: "--",
                delete_sources: false,
                target: :index
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
