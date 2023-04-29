# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module FulllocidLookup
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_locations,
                destination: :obj_locations__fulllocid_lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: :fulllocid
            end
          end
        end
      end
    end
  end
end
