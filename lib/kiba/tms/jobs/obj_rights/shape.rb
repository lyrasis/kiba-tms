# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjRights
        module Shape
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_rights__external_data_merged,
                destination: :obj_rights__shape
              },
              transformer: transforms
            )
          end

          def transforms
            base = [
              xforms,
              config.shape_xforms
            ].compact
            base << consistent if config.shape_xforms
            base
          end

          def xforms
            Kiba.job_segment do
              # passthrough if no custom xforms
            end
          end

          def consistent
            Kiba.job_segment do
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
