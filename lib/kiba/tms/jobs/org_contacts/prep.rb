# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module OrgContacts
        module Prep
          module_function

          ITERATION = Tms.names.cleanup_iteration

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: "nameclean#{ITERATION}__prep".to_sym,
                destination: :org_contacts__prep,
                lookup: :persons__by_norm
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[constituenttype contact_person contact_role norm]
              transform FilterRows::FieldEqualTo, action: :keep, field: :constituenttype, value: 'Organization'
              transform Delete::Fields, fields: :constituenttype
              transform FilterRows::FieldPopulated, action: :keep, field: :contact_person
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID, source: :contact_person, target: :contact_norm
              transform Merge::MultiRowLookup,
                lookup: persons__by_norm,
                keycolumn: :contact_norm,
                fieldmap: { merge_contact: Tms.constituents.preferred_name_field }
            end
          end
        end
      end
    end
  end
end
