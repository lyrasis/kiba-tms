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
                lookup: %i[
                           prep__ref_formats
                           prep__dd_languages
                          ]
              },
              transformer: xforms
            )
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
            end
          end
        end
      end
    end
  end
end
