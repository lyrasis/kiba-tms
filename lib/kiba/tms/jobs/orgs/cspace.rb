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
                source: :name_compile__orgs,
                destination: :orgs__cspace,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :con_address__to_merge if Tms::ConAddress.used
            base << :con_email__to_merge if Tms::ConEMail.used
            base << :con_phones__to_merge if Tms::ConPhones.used
            base << :name_compile__variant_term
            base << :name_compile__bio_note
            base << :name_compile__contact_person
            if Tms::TextEntries.for?('Constituents')
              base << :text_entries_for__constituents
            end
            base.select{ |job| Tms.job_output?(job) }
          end

          def merge_name_bio_notes?
            lookups.any?(:name_compile__bio_note)
          end

          def merge_name_contact_persons?
            lookups.any?(:name_compile__contact_person)
          end

          def merge_variants?
            lookups.any?(:name_compile__variant_term)
          end


          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::Names::RemoveDropped
              transform Delete::Fields,
                fields: %i[sort contype relation_type variant_term
                           variant_qualifier related_term related_role
                           note_text prefnormorig nonprefnormorig
                           altnorm alttype mainnorm]

              transform Tms::Transforms::Org::PrefName
              if bind.receiver.send(:merge_variants?)
                transform Tms::Transforms::Org::VariantName,
                  lookup: name_compile__variant_term
              end
              if bind.receiver.send(:merge_name_bio_notes?)
                transform Merge::MultiRowLookup,
                  lookup: name_compile__bio_note,
                  keycolumn: :namemergenorm,
                  conditions: ->(_pref, rows) do
                    rows.select{ |row| row[:contype] &&
                        row[:contype].start_with?('Person') }
                  end,
                  fieldmap: {rel_name_bio_note: :note_text},
                  delim: '%CR%'
              end
              if bind.receiver.send(:merge_name_contact_persons?)
              end
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

              # transform Rename::Fields, fieldmap: {
              #   begindateiso: :foundingdategroup,
              #   enddateiso: :dissolutiondategroup,
              #   nationality: :foundingplace,
              #   culturegroup: Tms::Constituents.culturegroup_target
              # }

              # if Tms::ConAddress.used?
              #   transform Tms::Transforms::ConAddress::MergeIntoAuthority,
              #     lookup: con_address__for_orgs
              # end
              # if Tms::ConEMail.used?
              #   transform Tms::Transforms::ConEmail::MergeIntoAuthority,
              #     lookup: con_email__for_orgs
              # end
              # if Tms::ConPhones.used?
              #   transform Tms::Transforms::ConPhones::MergeIntoAuthority,
              #     lookup: con_phones__for_orgs
              # end

              # transform CombineValues::FromFieldsWithDelimiter,
              #   sources: %i[biography remarks text_entry address_namenote
              #               email_web_namenote phone_fax_namenote],
              #   target: :historynote,
              #   sep: '%CR%%CR%',
              #   delete_sources: true

              # transform Delete::Fields, fields: :termsource

              # transform Clean::DelimiterOnlyFields,
              #   delim: Tms.delim, use_nullvalue: true
              # transform Delete::EmptyFields, usenull: true
              # transform Clean::RegexpFindReplaceFieldVals,
              #   fields: :all,
              #   find: '%CR%%CR%',
              #   replace: "\n\n"
              # transform Clean::RegexpFindReplaceFieldVals,
              #   fields: :all,
              #   find: '%QUOT%',
              #   replace: '"'
            end
          end
        end
      end
    end
  end
end
