# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Persons
        module Cspace
          module_function

          ITERATION = Tms.names.cleanup_iteration

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: "nameclean#{ITERATION}__persons_kept".to_sym,
                destination: :persons__cspace,
                lookup: %i[
                           con_address__for_persons
                           con_alt_names__to_merge_person
                           con_email__for_persons
                           con_phones__for_persons
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[migration_action constituenttype alt_names institution contact_person contact_role
                           fingerprint fp_termsource fp_constituenttype fp_constituentid fp_norm fp_alphasort
                           fp_displayname]

              transform Tms::Transforms::Person::PrefName
              transform Tms::Transforms::Person::VariantName
              transform Tms::Transforms::ConAddress::MergeIntoAuthority, lookup: con_address__for_persons
            end
          end
        end
      end
    end
  end
end
