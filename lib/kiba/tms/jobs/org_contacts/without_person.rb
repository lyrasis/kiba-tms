# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module OrgContacts
        module WithoutPerson
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :org_contacts__prep,
                destination: :org_contacts__without_person
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :reject,
                field: :merge_contact
            end
          end
        end
      end
    end
  end
end
