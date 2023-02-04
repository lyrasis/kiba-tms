# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module CleanupAddedLocs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locs__returned_compile,
                destination: :locs__cleanup_added_locs
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              # keeps only client-added, new location rows
              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :fulllocid
              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: %i[correct_location_name correct_authority
                           correct_address]
              transform Rename::Fields, fieldmap: {
                correct_location_name: :location_name,
                correct_authority: :storage_location_authority,
                correct_address: :address
              }
              transform Copy::Field,
                from: :location_name,
                to: :fulllocid
              transform Append::NilFields,
                fields: :usage_ct
              transform Merge::ConstantValue,
                target: :term_source,
                value: 'client-added'
            end
          end
        end
      end
    end
  end
end
