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
            if Tms::ConGeography.used?
              base << :con_geography__for_authority
              base << :con_geography__for_non_authority
            end
            if Tms::TextEntries.for?("Constituents")
              base << :text_entries_for__constituents
            end
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              lookups = bind.receiver.send(:lookups)

              transform Tms::Transforms::Names::RemoveDropped
              transform Tms::Transforms::Names::CleanExplodedId
              transform Delete::Fields,
                fields: %i[sort contype relation_type variant_term
                  variant_qualifier related_term related_role
                  note_text prefnormorig nonprefnormorig
                  altnorm alttype mainnorm]
              # transform Deduplicate::Table,
              #   field: :namemergenorm,
              #   delete_field: false

              transform Tms::Transforms::Org::PrefName
              if lookups.any?(:name_compile__variant_term)
                transform Tms::Transforms::Org::VariantName,
                  lookup: name_compile__variant_term
              end

              if lookups.any?(:name_compile__bio_note)
                transform Merge::MultiRowLookup,
                  lookup: name_compile__bio_note,
                  keycolumn: :namemergenorm,
                  conditions: ->(_pref, rows) do
                    rows.select { |row|
                      row[:contype] &&
                        row[:contype].start_with?("Org")
                    }
                  end,
                  fieldmap: {rel_name_bio_note: :note_text},
                  delim: "%CR%"
              end

              if lookups.any?(:name_compile__contact_person)
                transform Tms::Transforms::Org::ContactName,
                  lookup: name_compile__contact_person
              end

              unless Tms::Names.set_term_source
                transform Delete::Fields, fields: :termsource
              end

              transform Collapse::FieldsToRepeatableFieldGroup,
                sources: %i[pref var],
                targets: config.term_targets,
                delim: Tms.delim,
                enforce_evenness: false

              if Tms::ConAddress.used?
                transform Tms::Transforms::ConAddress::MergeIntoAuthority,
                  lookup: con_address__to_merge
              end
              if Tms::ConEMail.used?
                transform Tms::Transforms::ConEmail::MergeIntoAuthority,
                  lookup: con_email__to_merge
              end
              if Tms::ConPhones.used?
                transform Tms::Transforms::ConPhones::MergeIntoAuthority,
                  lookup: con_phones__to_merge
              end
              if Tms::ConDisplayBios.used?
                transform Tms::ConDisplayBios.merger
              end
              if Tms::TextEntries.for?("Constituents") &&
                  Tms::TextEntries.for_constituents_merge
                transform Tms::TextEntries.for_constituents_merge,
                  lookup: text_entries_for__constituents
              end
              if lookups.any?(:con_geography__for_authority) &&
                  Tms::ConGeography.auth_merger
                transform Tms::ConGeography.auth_merger,
                  auth: :org,
                  lookup: con_geography__for_authority
              end
              if lookups.any?(:con_geography__for_non_authority) &&
                  Tms::ConGeography.non_auth_merger
                transform Tms::ConGeography.non_auth_merger,
                  auth: :org,
                  lookup: con_geography__for_non_authority
              end

              transform Rename::Fields, fieldmap: {
                birth_foundation_date: :foundingdategroup,
                death_dissolution_date: :dissolutiondategroup
              }

              transform Delete::Fields,
                fields: %i[constituentid]

              unless config.historynote_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.historynote_sources,
                  target: :historynote,
                  delim: "%CR%",
                  delete_sources: true
              end

              unless config.group_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.group_sources,
                  target: :group,
                  delim: Tms.delim,
                  delete_sources: true
              end

              unless config.organizationrecordtype_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.organizationrecordtype_sources,
                  target: :organizationrecordtype,
                  delim: Tms.delim,
                  delete_sources: true
              end

              transform Delete::Fields,
                fields: Tms::NameCompile.org_nil

              transform Delete::DelimiterOnlyFieldValues,
                treat_as_null: Tms.nullvalue
              transform Delete::EmptyFields, usenull: true
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
