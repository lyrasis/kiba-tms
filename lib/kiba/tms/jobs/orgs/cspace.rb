# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Orgs
        module Cspace
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :names__orgs,
                destination: :orgs__cspace,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            # org_contacts__to_merge
            # con_alt_names__to_merge_org
            base = %i[
                     ]
            if Tms::ConAddress.used?
              base << :con_address__for_orgs
            end
            if Tms::ConEMail.used?
              base << :con_email__for_orgs
            end
            if Tms::ConPhones.used?
              base << :con_phones__for_orgs
            end
            base
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[migration_action constituenttype alt_names institution
                           contact_person contact_role nametitle firstname
                           middlename lastname suffix salutation fingerprint
                           fp_termsource fp_constituenttype fp_constituentid
                           fp_norm fp_alphasort fp_displayname]

              # transform Tms::Transforms::Org::PrefName
              # transform Tms::Transforms::Org::VariantName
              # transform Tms::Transforms::Org::AltName,
              #   lookup: con_alt_names__to_merge_org
              # transform Tms::Transforms::Names::CompilePrefVarAlt,
              #   authority_type: :org

              # transform Merge::MultiRowLookup,
              #   lookup: org_contacts__to_merge,
              #   keycolumn: :norm,
              #   fieldmap: {
              #     contactname: :merge_contact,
              #     contactrole: :contact_role
              #   },
              #   null_placeholder: '%NULLVALUE%'

              transform Rename::Fields, fieldmap: {
                begindateiso: :foundingdategroup,
                enddateiso: :dissolutiondategroup,
                nationality: :foundingplace,
                culturegroup: Tms::Constituents.culturegroup_target
              }

              if Tms::ConAddress.used?
                transform Tms::Transforms::ConAddress::MergeIntoAuthority,
                  lookup: con_address__for_orgs
              end
              if Tms::ConEMail.used?
                transform Tms::Transforms::ConEmail::MergeIntoAuthority,
                  lookup: con_email__for_orgs
              end
              if Tms::ConPhones.used?
                transform Tms::Transforms::ConPhones::MergeIntoAuthority,
                  lookup: con_phones__for_orgs
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[biography remarks text_entry address_namenote
                            email_web_namenote phone_fax_namenote],
                target: :historynote,
                sep: '%CR%%CR%',
                delete_sources: true

              transform Delete::Fields, fields: :termsource

              transform Clean::DelimiterOnlyFields,
                delim: Tms.delim, use_nullvalue: true
              transform Delete::EmptyFields, usenull: true
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '%CR%%CR%',
                replace: "\n\n"
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '%QUOT%',
                replace: '"'
            end
          end
        end
      end
    end
  end
end
