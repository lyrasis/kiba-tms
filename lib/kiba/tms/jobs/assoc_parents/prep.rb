# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AssocParents
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__assoc_parents,
                destination: :prep__assoc_parents,
                lookup: :prep__relationships
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::TmsTableNames

              unless Tms::AssocParents.delete_fields.empty?
                transform Delete::Fields, fields: Tms::AssocParents.delete_fields
              end
              
              transform Rename::Fields, fieldmap: {
                id: :recordid
              }

              transform Merge::MultiRowLookup,
                lookup: prep__relationships,
                keycolumn: :relationshipid,
                fieldmap: {relationship: :relationship_label}
              transform Delete::Fields, fields: :relationshipid
            end
          end
        end
      end
    end
  end
end
