# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LocsClean
        module HierCspace
          module_function

          AUTH_SUBTYPE = {
            local: 'location',
            offsite: 'offsite_sla'
          }
          def job(type:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: "locclean__#{type}_hier".to_sym,
                destination: "locclean__#{type}_hier_cspace".to_sym
              },
              transformer: xforms(type)
            )
          end

          def xforms(type)
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[location_name parent_location]
              transform FilterRows::FieldPopulated, action: :keep, field: :parent_location
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[location_name parent_location],
                target: :combined,
                sep: ' - ',
                delete_sources: false
              transform Deduplicate::Table, field: :combined, delete_field: true
              transform Merge::ConstantValues, constantmap: {
                term_type: 'locationauthorities',
                term_subtype: AUTH_SUBTYPE[type]
              }
              transform Rename::Fields, fieldmap: {
                location_name: :narrower_term,
                parent_location: :broader_term
              }
            end
          end
        end
      end
    end
  end
end
