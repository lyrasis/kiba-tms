# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Citations
        module Lookup
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :citations__main,
                destination: :citations__lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :termdisplayname
              transform Cspace::NormalizeForID,
                source: :termdisplayname,
                target: :norm
            end
          end
        end
      end
    end
  end
end
