# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Relationships
        module UnknownTables
          extend self
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__relationships,
                destination: :relationships__unknown_tables
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :reject, field: :tablename
            end
          end
        end
      end
    end
  end
end
