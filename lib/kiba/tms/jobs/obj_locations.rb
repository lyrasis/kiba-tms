# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        extend self
        
        def prep
          xforms = Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::FieldValueMatchingRegexp,
              fields: %i[approver handler requestedby],
              match: '^(\(|\[)[Nn]ot [Ee]ntered(\)|\])$'
          end
          
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__obj_locations,
              destination: :prep__obj_locations
            },
            transformer: xforms
          )
        end
      end
    end
  end
end
