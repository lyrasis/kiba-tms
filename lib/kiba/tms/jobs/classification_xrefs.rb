# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ClassificationXrefs
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__classification_xrefs,
              destination: :prep__classification_xrefs,
              lookup: :prep__classifications
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::Fields, fields: %i[classificationxrefid displayorder]
            transform Merge::MultiRowLookup,
              keycolumn: :classificationid,
              lookup: prep__classifications,
              fieldmap: {
                classification: :classification
              },
              delim: Kiba::Tms.delim
            transform Delete::Fields, fields: :classificationid
            transform FilterRows::FieldPopulated, action: :keep, field: :classification
          end
        end
      end
    end
  end
end
