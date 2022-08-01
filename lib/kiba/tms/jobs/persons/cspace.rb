# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Persons
        module Cspace
          module_function

          ITERATION = Tms::Names.cleanup_iteration

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
                           text_entries__for_constituents
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              sorter = Lookup::RowSorter.new(on: :sort, as: :to_i)
              transform Merge::MultiRowLookup,
                lookup: text_entries__for_constituents,
                keycolumn: :fp_constituentid,
                fieldmap: { text_entry: :text_entry},
                delim: Tms.delim,
                sorter: sorter
              
              transform Delete::Fields,
                fields: %i[migration_action constituenttype alt_names institution contact_person contact_role
                           fingerprint fp_termsource fp_constituenttype fp_constituentid fp_norm fp_alphasort
                           fp_displayname]

              transform Clean::RegexpFindReplaceFieldVals,
                fields: :nametitle,
                find: '\.',
                replace: ''
              transform Tms::Transforms::Person::PrefName
              transform Tms::Transforms::Person::VariantName
              transform Tms::Transforms::Person::AltName, lookup: con_alt_names__to_merge_person
              transform Tms::Transforms::Names::CompilePrefVarAlt, authority_type: :person

              transform Rename::Field, from: :begindateiso, to: :birthdategroup
              transform Rename::Field, from: :enddateiso, to: :deathdategroup
              transform Rename::Field, from: :biography, to: :bionote
              transform Rename::Field, from: :culturegroup, to: Tms::Constituents.culturegroup_target
              
              transform Tms::Transforms::ConAddress::MergeIntoAuthority, lookup: con_address__for_persons
              transform Tms::Transforms::ConEmail::MergeIntoAuthority, lookup: con_email__for_persons
              transform Tms::Transforms::ConPhones::MergeIntoAuthority, lookup: con_phones__for_persons

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[remarks text_entry address_namenote email_web_namenote phone_fax_namenote],
                target: :namenote,
                sep: '%CR%%CR%',
                delete_sources: true

              transform Delete::Fields, fields: :termsource

              transform Clean::DelimiterOnlyFields, delim: Tms.delim, use_nullvalue: true
              transform Delete::EmptyFields, usenull: true
              transform Clean::RegexpFindReplaceFieldVals, fields: :all, find: '%CR%%CR%', replace: "\n\n"
              transform Clean::RegexpFindReplaceFieldVals, fields: :all, find: '%QUOT%', replace: '"'
            end
          end
        end
      end
    end
  end
end
