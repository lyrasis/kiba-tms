# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ThesXrefs
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__thes_xrefs,
                destination: :prep__thes_xrefs,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = [:prep__terms]
            base << :prep__thes_xref_types if Tms::ThesXrefTypes.used?
            base.select { |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Tms::Transforms::DeleteTmsFields,
                except: %i[entereddate]
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              if config.drop_inactive
                transform FilterRows::FieldEqualTo,
                  action: :reject,
                  field: :active,
                  value: "0"
                transform Delete::Fields,
                  fields: :active
              end
              transform Tms.data_cleaner if Tms.data_cleaner

              transform Replace::FieldValueWithStaticMapping,
                source: :thesxreftableid,
                target: :thesxreftable,
                mapping: Tms::ThesXrefs.table_aliases,
                delete_source: true

              transform Tms::Transforms::DeleteTimestamps,
                fields: :entereddate

              if lookups.any?(:prep__thes_xref_types)
                transform Merge::MultiRowLookup,
                  keycolumn: :thesxreftypeid,
                  lookup: prep__thes_xref_types,
                  fieldmap: {thesxreftype: :thesxreftype}
              end
              transform Delete::Fields, fields: :thesxreftypeid

              transform Tms::Transforms::TmsTableNames
              transform Rename::Field, from: :id, to: :recordid

              transform Merge::MultiRowLookup,
                keycolumn: :termid,
                lookup: prep__terms,
                fieldmap: {
                  termused: :termused,
                  termpreferred: :termpreferred,
                  termtype: :termtype,
                  termsource: :termsource
                }

              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: %i[termused termpreferred]

              if lookups.any?(:prep__classification_notations)
                transform Merge::MultiRowLookup,
                  keycolumn: :primarycnid,
                  lookup: prep__classification_notations,
                  fieldmap: {notation: :cn}
              end
              transform Delete::Fields, fields: :primarycnid
            end
          end
        end
      end
    end
  end
end
