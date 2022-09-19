# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConXrefs
        module Prep
          module_function

          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_xrefs,
                destination: :prep__con_xrefs
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
            end
          end
        end
      end
    end
  end
end
