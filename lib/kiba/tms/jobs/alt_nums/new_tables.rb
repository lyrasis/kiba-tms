# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module NewTables
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__alt_nums,
                destination: :alt_nums__new_tables
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldMatchRegexp,
                action: :reject,
                field: :tablename,
                match: '^(Constituents|Objects|ReferenceMaster)$'
            end
          end
        end
      end
    end
  end
end
