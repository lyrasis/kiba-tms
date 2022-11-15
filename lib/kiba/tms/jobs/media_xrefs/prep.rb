# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaXrefs
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__media_xrefs,
                destination: :prep__media_xrefs
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              mod = bind.receiver
              config = mod.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::TmsTableNames
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
