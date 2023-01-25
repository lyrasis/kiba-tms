# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConPhones
        module ToMerge
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_phones,
                destination: :con_phones__to_merge
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :keeping,
                value: 'y'
              transform Delete::Fields, fields: :keeping
            end
          end
        end
      end
    end
  end
end
