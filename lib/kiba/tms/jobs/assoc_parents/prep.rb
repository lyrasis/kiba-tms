# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AssocParents
        module Prep
          module_function

          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__assoc_parents,
                destination: :prep__assoc_parents,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__relationships if Tms::Relationships.used?
            base
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::TmsTableNames

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              
              transform Rename::Fields, fieldmap: {
                id: :recordid
              }

              if Tms::Relationships.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__relationships,
                  keycolumn: :relationshipid,
                  fieldmap: {relationship: :relationship_label}
              end
              transform Delete::Fields, fields: :relationshipid
            end
          end
        end
      end
    end
  end
end
