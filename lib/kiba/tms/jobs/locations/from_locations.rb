# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module FromLocations
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__locations,
                destination: :locs__from_locations
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)

              keepfields = %i[locationid location_name parent_location
                storage_location_authority locationtype address]
              keepfields << :tmslocationstring if config.terms_abbreviated

              transform Delete::FieldsExcept,
                fields: keepfields
              transform Tms::Transforms::ObjLocations::AddFulllocid
              transform Delete::Fields, fields: :locationid
              transform Merge::ConstantValue,
                target: :term_source,
                value: "Locations"
            end
          end
        end
      end
    end
  end
end
