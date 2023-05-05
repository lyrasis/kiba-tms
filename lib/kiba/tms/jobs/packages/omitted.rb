# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Packages
        module Omitted
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :packages__flag_omitting,
                destination: :packages__omitted
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[omit packageid]
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :omit
            end
          end
        end
      end
    end
  end
end
