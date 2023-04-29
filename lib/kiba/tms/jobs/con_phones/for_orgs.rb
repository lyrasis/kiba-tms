# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConPhones
        module ForOrgs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_phones,
                destination: :con_phones__for_orgs
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :keeping,
                value: "y"
              transform FilterRows::FieldPopulated, action: :keep, field: :org
              transform Delete::Fields, fields: :org
            end
          end
        end
      end
    end
  end
end
