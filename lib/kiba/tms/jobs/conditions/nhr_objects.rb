# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Conditions
        module NhrObjects
          module_function

          def job
            return unless config.used?

          Kiba::Extend::Jobs::Job.new(
              files: {
                source: :conditions__cspace,
                destination: :conditions__nhr_objects
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[tablename recordnumber conditioncheckrefnumber]

              transform Replace::FieldValueWithStaticMapping,
                source: :tablename,
                mapping: {
                  'Objects'=>'collectionobjects'
                }
              transform Rename::Fields, fieldmap: {
                recordnumber: :item1_id,
                conditioncheckrefnumber: :item2_id,
                tablename: :item1_type
              }
              transform Merge::ConstantValue,
                target: :item2_type,
                value: 'conditionchecks'

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
