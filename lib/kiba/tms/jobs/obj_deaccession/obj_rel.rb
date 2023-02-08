# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjDeaccession
        module ObjRel
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_deaccession__shaped,
                destination: :obj_deaccession__obj_rel
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :exitnumber
              transform Copy::Field,
                from: :exitnumber,
                to: :objectnumber
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :objectnumber,
                find: '^EX',
                replace: ''
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :objectnumber,
                find: ' \d{3}$',
                replace: ''
              transform Rename::Fields, fieldmap: {
                objectnumber: :item1_id,
                exitnumber: :item2_id
              }
              transform Merge::ConstantValues,
                constantmap: {
                  item1_type: 'collectionobjects',
                  item2_type: 'objectexit'
                }
            end
          end
        end
      end
    end
  end
end
