# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConXrefDetails
        module Prep
          module_function

          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_xref_details,
                destination: :prep__con_xref_details
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              
              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              
              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.fields - [:conxrefdetailid],
                target: :combined,
                sep: ' ',
                delete_sources: false
              transform Deduplicate::Table, field: :combined, delete_field: true
            end
          end
        end
      end
    end
  end
end
