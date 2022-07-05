# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module ForTableable
          module_function

          def xforms(table:)
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :tablename, value: table
            end
          end
        end
      end
    end
  end
end
