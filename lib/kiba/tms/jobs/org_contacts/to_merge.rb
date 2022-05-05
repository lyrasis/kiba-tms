# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module OrgContacts
        module ToMerge
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :org_contacts__prep,
                destination: :org_contacts__to_merge
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep, field: :merge_contact
              transform Delete::FieldsExcept, fields: %i[norm merge_contact contact_role]
            end
          end
        end
      end
    end
  end
end
