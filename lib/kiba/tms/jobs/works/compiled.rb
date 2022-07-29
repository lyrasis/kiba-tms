# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Works
        module Compiled
          module_function

          def job
            return if sources.empty?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :works__compiled
              },
              transformer: xforms
            )
          end

          def sources
            base = []
            if Tms::Objects::Config.department_target == :dept_namedcollection
              base << :works__from_object_departments
            end
            base
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table, field: :norm
            end
          end
        end
      end
    end
  end
end
