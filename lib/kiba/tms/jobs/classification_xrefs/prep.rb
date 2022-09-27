# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ClassificationXRefs
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__classification_xrefs,
                destination: :prep__classification_xrefs,
                lookup: :prep__classifications
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields, fields: %i[classificationxrefid]

              transform Rename::Fields, fieldmap: {
                id: :recordid,
                displayorder: :sort
              }
              transform Replace::FieldValueWithStaticMapping,
                source: :tableid, target: :table, mapping: Tms::TABLES, fallback_val: nil, delete_source: false

              # transform Merge::MultiRowLookup,
              #   keycolumn: :classificationid,
              #   lookup: prep__classifications,
              #   fieldmap: Tms.classifications.fieldmap,
              #   null_placeholder: '%NULLVALUE%',
              #   delim: Kiba::Tms.delim
              # transform Delete::Fields, fields: :classificationid
              # transform FilterRows::FieldPopulated, action: :keep, field: :classification
            end
          end
        end
      end
    end
  end
end
