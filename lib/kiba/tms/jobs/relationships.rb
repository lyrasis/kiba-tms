# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Relationships
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__relationships,
              destination: :prep__relationships
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::Fields,
              fields: %i[movecolocated rel1prep rel2prep relation1plural relation2plural transitive]
            transform Tms::Transforms::TmsTableNames
            transform Tms::Transforms::Relationships::AddLabel
          end
        end
      end
    end
  end
end
