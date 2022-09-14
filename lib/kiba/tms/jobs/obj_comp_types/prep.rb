# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjCompTypes
        module Prep
          extend self
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_comp_types,
                destination: :prep__obj_comp_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              if Tms::ObjCompTypes.omitting_fields?
                transform Delete::Fields, fields: Tms::ObjCompTypes.omitted_fields
              end
              transform Rename::Field, from: :objcomptype, to: :origtype
              transform Replace::FieldValueWithStaticMapping,
                source: :origtype,
                target: :objcomptype,
                mapping: Tms::ObjCompTypes.mappings,
                fallback_val: nil,
                delete_source: false
            end
          end
        end
      end
    end
  end
end
