# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module ContactPerson
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: :name_compile__contact_person
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :relation_type,
                value: 'contact_person'
            end
          end
        end
      end
    end
  end
end
