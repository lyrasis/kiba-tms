# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAddress
        module Duplicates
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_address__shaped,
                destination: :con_address__duplicates
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :duplicate,
                value: "y"
              transform Delete::Fields,
                fields: :duplicate
            end
          end
        end
      end
    end
  end
end
