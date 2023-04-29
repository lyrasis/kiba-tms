# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module ReturnedCompile
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.returned_file_jobs,
                destination: :locs__returned_compile
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform do |row|
                row[:combine] = row[:fulllocid]
                combine = row[:combine]
                next row unless combine.blank?

                row[:combine] = row[:correct_location_name]
                row
              end
              transform Deduplicate::Table,
                field: :combine,
                delete_field: true
              transform Delete::Fields,
                fields: %i[usage_ct location_name storage_location_authority
                  address term_source]
            end
          end
        end
      end
    end
  end
end
