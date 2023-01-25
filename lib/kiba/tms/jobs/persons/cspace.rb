# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Persons
        module Cspace
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__persons,
                destination: :persons__cspace,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :con_address__to_merge if Tms::ConAddress.used
            base << :con_email__for_persons if Tms::ConEMail.used
            base << :con_phones__for_persons if Tms::ConPhones.used
            base << :name_compile__variant_term
            base << :name_compile__bio_note
            base.select{ |job| Tms.job_output?(job) }
          end

          def merge_name_bio_notes?
            lookups.any?(:name_compile__bio_note)
          end

          def merge_variants?
            lookups.any?(:name_compile__variant_term)
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[sort contype relation_type variant_term
                           variant_qualifier related_term related_role
                           note_text prefnormorig nonprefnormorig
                           termsource altnorm alttype mainnorm]

              transform Tms::Transforms::Person::PrefName
              if bind.receiver.send(:merge_variants?)
                transform Tms::Transforms::Person::VariantName,
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

              transform Clean::RegexpFindReplaceFieldVals,
                fields: %i[pref_title var_title],
                find: '\.',
                replace: ''

              term_targets = %i[termdisplayname salutation title forename
                                middlename surname nameadditions termflag
                                termsourcenote]
              if Tms::Names.set_term_source
                term_targets << :termsource
              end
              if Tms::Names.set_term_pref_for_lang
                term_targets << :termprefforlang
              end
              transform Collapse::FieldsToRepeatableFieldGroup,
                sources: %i[pref var],
                targets: term_targets,
                delim: Tms.delim

              # transform Rename::Field, from: :biography, to: :bionote
              # transform Rename::Field,
              #   from: :culturegroup,
              #   to: Tms::Constituents.culturegroup_target

              if Tms::ConAddress.used
                transform Tms::Transforms::ConAddress::MergeIntoAuthority,
                  lookup: con_address__to_merge
              end
              if Tms::ConEMail.used
                transform Tms::Transforms::ConEmail::MergeIntoAuthority,
                  lookup: con_email__for_persons
              end
              if Tms::ConPhones.used
              transform Tms::Transforms::ConPhones::MergeIntoAuthority,
                lookup: con_phones__for_persons
              end

              # transform CombineValues::FromFieldsWithDelimiter,
              #   sources: %i[remarks text_entry address_namenote
              #               email_web_namenote phone_fax_namenote],
              #   target: :namenote,
              #   sep: '%CR%%CR%',
              #   delete_sources: true

              transform Delete::Fields, fields: :termsource

              transform Delete::DelimiterOnlyFieldValues,
                delim: Tms.delim,
                treat_as_null: Tms.nullvalue
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
