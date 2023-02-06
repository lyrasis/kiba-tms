# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhObjXrefs
        module NhrObjExh
          module_function

          def job
            return unless config.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__exh_obj_xrefs,
                destination: :exh_obj_xrefs__nhr_obj_exh
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[objectnumber exhibitionnumber]
              transform Rename::Fields, fieldmap: {
                objectnumber: :item1_id,
                exhibitionnumber: :item2_id
              }
              transform Merge::ConstantValues,
                constantmap: {
                  item1_type: 'collectionobjects',
                  item2_type: 'exhibitions'
                }
              transform CombineValues::FullRecord, target: :index
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
