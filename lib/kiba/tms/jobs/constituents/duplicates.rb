# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module Duplicates
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__for_compile,
                destination: :constituents__duplicates
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep,
                field: :duplicate
            end
          end
        end
      end
    end
  end
end
