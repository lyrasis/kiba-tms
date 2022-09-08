# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AccessionMethods
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__accession_methods,
                destination: :prep__accession_methods
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :accessionmethod

              transform Replace::FieldValueWithStaticMapping,
                source: :accessionmethod,
                mapping: Tms::AccessionMethods.mappings
            end
          end
        end
      end
    end
  end
end
