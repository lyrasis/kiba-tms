# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAddress
        module ForOrgs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_address__to_merge,
                destination: :con_address__for_orgs
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep, field: :org
            end
          end
        end
      end
    end
  end
end
