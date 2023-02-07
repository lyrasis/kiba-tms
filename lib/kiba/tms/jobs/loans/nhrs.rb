# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loans
        module Nhrs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :loans__nhrs
              },
              transformer: xforms
            )
          end

          def sources
            %i[
               loansin__rel_obj
               loansout__rel_obj
              ].select{ |job| Tms.job_output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform CombineValues::FullRecord, target: :index
              transform Deduplicate::Table,
                field: :index,
                delete_field: true
            end
          end
        end
      end
    end
  end
end
