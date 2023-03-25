# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TextEntries
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__text_entries,
                destination: :prep__text_entries,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[names__by_constituentid]
            base << :prep__text_types if Tms::TextTypes.used
            base << :prep__text_statuses if Tms::TextStatuses.used
            base.select{ |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: %i[purpose remarks textentry]
              transform Delete::Fields, fields: :combined

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner

              transform Rename::Fields, fieldmap: {
                id: :recordid,
                textentryid: :sort
              }
              transform Tms::Transforms::TmsTableNames

              if Tms::TextTypes.used
                transform Merge::MultiRowLookup,
                  lookup: prep__text_types,
                  keycolumn: :texttypeid,
                  fieldmap: { texttype: :texttype }
              end
              transform Delete::Fields, fields: :texttypeid

              if Tms::TextStatuses.used
                transform Merge::MultiRowLookup,
                  lookup: prep__text_statuses,
                  keycolumn: :textstatusid,
                  fieldmap: { textstatus: :textstatus }
              end
              transform Delete::Fields, fields: :textstatusid

              transform Tms::Transforms::Constituents::Merger,
                lookup: names__by_constituentid,
                keycolumn: :authorconid,
                targets: {
                  org_author: :org,
                  person_author: :person
                }
            end
          end
        end
      end
    end
  end
end
