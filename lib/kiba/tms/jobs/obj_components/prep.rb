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
            base = []
            base << %i[tms__obj_comp_types prep__obj_comp_statuses] if Tms::ObjComponents.actual_components
            base.flatten
          end
          
          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              delete_fields = [
                  Tms::ObjComponents.out_of_scope_fields,
                  Tms::ObjComponents.unhandled_fields,
                  Tms::ObjComponents.other_delete_fields
                ].flatten
              delete_fields << :conservationentityid unless Tms.conservationentity_used
              transform Delete::Fields,
                fields: delete_fields
              transform FilterRows::FieldEqualTo, action: :reject, field: :componentid, value: '-1'

              if Tms::ObjComponents.actual_components
                transform Merge::MultiRowLookup,
                  lookup: tms__obj_comp_types,
                  keycolumn: :componenttype,
                  fieldmap: {
                    component_type: :objcomptype,
                  },
                  delim: Tms.delim
                transform Merge::MultiRowLookup,
                  lookup: prep__obj_comp_statuses,
                  keycolumn: :objcompstatusid,
                  fieldmap: {
                    objcompstatus: :objcompstatus,
                  },
                  delim: Tms.delim
              end
              transform Delete::Fields, fields: %i[componenttype objcompstatusid]

              
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
