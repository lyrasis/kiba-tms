# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AssocParents
        module NewTables
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__assoc_parents,
                destination: :assoc_parents__new_tables
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
