# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaXrefs
        module CondLineItems
          module_function

          def job
            return unless config.used?
            return unless config.for?("CondLineItems")

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_xrefs_for__cond_line_items,
                destination: :media_xrefs__cond_line_items,
                lookup: %i[
                  media_files__id_lookup
                  conditions__cspace
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
                lookup: Tms.get_lookup(
                  jobkey: :tms__cond_line_items,
                  column: :condlineitemid
                ),
                keycolumn: :id,
                fieldmap: {conditionid: :conditionid}

              transform Merge::MultiRowLookup,
                lookup: conditions__cspace,
                keycolumn: :conditionid,
                fieldmap: {item1_id: :conditioncheckrefnumber}
              transform Delete::Fields, fields: :conditionid
              transform Merge::MultiRowLookup,
                lookup: media_files__id_lookup,
                keycolumn: :mediamasterid,
                fieldmap: {item2_id: :identificationnumber}
              transform Merge::ConstantValues, constantmap: {
                item1_type: "conditionchecks",
                item2_type: "media"
              }
            end
          end
        end
      end
    end
  end
end
