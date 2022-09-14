# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjectTypes
        module Prep
          extend self
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__object_types,
                destination: :prep__object_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :objecttype
              transform Rename::Field, from: :objecttype, to: :origtype
              transform Replace::FieldValueWithStaticMapping,
                source: :origtype,
                target: :objecttype,
                mapping: Tms::ObjectTypes.mappings,
                fallback_val: nil,
                delete_source: false
            end
          end
        end
      end
    end
  end
end
