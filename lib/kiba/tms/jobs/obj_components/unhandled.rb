# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module Unhandled
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_components,
                destination: :obj_components__unhandled
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :reject, field: :componentid, value: '-1'
              chkfields = Tms::ObjComponents.unhandled_fields
              transform Delete::FieldsExcept, fields: chkfields
              transform Clean::RegexpFindReplaceFieldVals, fields: chkfields, find: '^0$', replace: ''
              transform CombineValues::FromFieldsWithDelimiter,
                sources: chkfields,
                target: :field_vals,
                sep: '; ',
                prepend_source_field_name: true
              transform FilterRows::FieldPopulated, action: :keep, field: :field_vals
            end
          end
        end
      end
    end
  end
end
