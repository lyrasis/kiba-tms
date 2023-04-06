# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module Hierarchy
          module_function

          AUTH_SUBTYPE = {
            'Local'=>'location',
            'Offsite'=>'offsite_sla'
          }
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locs__compiled_hierarchy,
                destination: :locs__hierarchy
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :storage_location_authority,
                value: 'Organization'
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :parent_location
              transform Delete::FieldsExcept,
                fields: %i[location_name parent_location
                           storage_location_authority]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[location_name parent_location],
                target: :combined,
                sep: ' - ',
                delete_sources: false
              transform Deduplicate::Table, field: :combined, delete_field: true
              transform Merge::ConstantValues, constantmap: {
                term_type: 'locationauthorities'
              }
              transform do |row|
                auth = row[:storage_location_authority]
                row[:term_subtype] = AUTH_SUBTYPE[auth]
                row
              end
              transform Delete::Fields, fields: :storage_location_authority
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
