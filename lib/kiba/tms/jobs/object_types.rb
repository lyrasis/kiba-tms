# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjectTypes
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__object_types,
              destination: :prep__object_types
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform FilterRows::FieldMatchRegexp,
              action: :reject,
              field: :objecttype,
              match: '^(\(|\[)[Nn]ot [Dd]efined(\)|\])$'
          end
        end
      end
    end
  end
end
