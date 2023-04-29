# frozen_string_literal: true

## NOTE: NOT FINISHED YET
module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__reference_master,
                destination: :prep__reference_master,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__ref_formats if Tms::RefFormats.used?
            base << :prep__dd_languages if Tms::DDLanguages.used?
            if Tms::TextEntries.for?("ReferenceMaster")
              base << :text_entries__for_reference_master
            end
            base
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner

              transform Merge::MultiRowLookup,
                lookup: prep__ref_formats,
                keycolumn: :formatid,
                fieldmap: {format: :format}
              transform Delete::Fields, fields: :formatid
              transform Merge::MultiRowLookup,
                lookup: prep__dd_languages,
                keycolumn: :languageid,
                fieldmap: {language: :language}
              transform Delete::Fields, fields: :languageid

              if Tms::TextEntries.for?("ReferenceMaster")
                if Tms::ReferenceMaster.text_entry_merger
                  Tms::ReferenceMaster.config.text_entry_lookup = text_entries_for__reference_master
                  transform Tms::ReferenceMaster.text_entry_merger
                else
                  transform Merge::MultiRowLookup,
                    lookup: text_entries_for__reference_master,
                    keycolumn: :referenceid,
                    fieldmap: {termfullcitation: :textentry}
                end
              end
            end
          end
        end
      end
    end
  end
end
