# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Associations
        module ToTableSplit
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__associations,
                destination: :associations__to_table_split
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::AllFieldsPopulated,
                action: :keep,
                fields: %i[val1 val2]
              transform Tms::Transforms::Associations::Explode
            end
          end
        end
      end
    end
  end
end
