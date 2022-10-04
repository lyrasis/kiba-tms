# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module NumberLookup
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__objects,
                destination: :objects__number_lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[objectid objectnumber]
            end
          end
        end
      end
    end
  end
end
