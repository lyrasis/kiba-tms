# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Relationships
        module Prep
          extend self
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__relationships,
                destination: :prep__relationships
              },
              transformer: xforms
            )
          end

          def xforms
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
end
