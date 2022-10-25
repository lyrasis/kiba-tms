# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConPhones
        module ForPersons
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_phones,
                destination: :con_phones__for_persons
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
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :person
              transform Delete::Fields, fields: :person
            end
          end
        end
      end
    end
  end
end
