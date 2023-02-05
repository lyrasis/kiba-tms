# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Lmi
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :obj_locations__lmi
              },
              transformer: xforms
            )
          end

          def sources
            %i[
               obj_locations__inventory
               obj_locations__location
               obj_locations__movement
              ].select{ |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Append::NilFields,
                fields: config.lmi_field_normalizer.get_fields
            end
          end
        end
      end
    end
  end
end
