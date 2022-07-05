# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module StatusFlags
        module NewTables
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__status_flags,
                destination: :status_flags__new_tables
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              Tms::StatusFlags.target_tables.each do |table|
                transform FilterRows::FieldEqualTo, action: :reject, field: :tablename, value: table
              end
            end
          end
        end
      end
    end
  end
end
