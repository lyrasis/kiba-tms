# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module Prep
          module_function

          # The logic of this looks flipped, but the field is named "inactive"
          STATUS = {
            '0' => 'active',
            '1' => 'inactive'
          }

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_components,
                destination: :prep__obj_components,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            if Tms.obj_components.used
              %i[tms__obj_comp_types tms__obj_comp_statuses]
            else
              []
            end
          end
          
          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields, fields: %i[sortnumber injurisdiction]
              transform FilterRows::FieldEqualTo, action: :reject, field: :componentid, value: '-1'

              if Tms.obj_components.used
                transform Merge::MultiRowLookup,
                  lookup: tms__obj_comp_types,
                  keycolumn: :componenttype,
                  fieldmap: {
                    component_type: :objcomptype,
                  },
                  delim: Tms.delim
                transform Delete::Fields, fields: :componenttype

                transform Merge::MultiRowLookup,
                  lookup: tms__obj_comp_statuses,
                  keycolumn: :objcompstatusid,
                  fieldmap: {
                    objcompstatus: :objcompstatus,
                  },
                  delim: Tms.delim
                transform Delete::Fields, fields: :objcompstatusid
              end
              
              transform Replace::FieldValueWithStaticMapping,
                source: :inactive,
                target: :active,
                mapping: STATUS
              transform Delete::Fields, fields: :inactive

            end
          end
        end
      end
    end
  end
end
