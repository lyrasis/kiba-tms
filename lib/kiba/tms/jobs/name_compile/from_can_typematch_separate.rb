# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromCanTypematchSeparate
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__from_can_typematch,
                destination: :name_compile__from_can_typematch_separate
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :treatment, value: "separate_name"
              transform Delete::Fields, fields: :treatment
            end
          end
        end
      end
    end
  end
end
