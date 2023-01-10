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
            if Tms::Objects.named_coll_fields.any?(:dept_namedcollection)
              base << :works__from_object_departments
            end
            if Tms::Objects.named_coll_fields.any?(:period)
              base << :works__from_object_period
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
