# frozen_string_literal: true

## NOTE: NOT FINISHED YET
module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module Prep
          module_function
          
          def job
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
            base = %i[
                      prep__ref_formats
                      prep__dd_languages
                     ]
            base << :text_entries__for_reference_master if Tms::TextEntries.for?('ReferenceMaster')
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: Tms::ReferenceMaster.delete_fields
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

              if Tms::TextEntries.target_tables.any?('ReferenceMaster')
                transform Merge::MultiRowLookup,
                  lookup: text_entries__for_reference_master,
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
