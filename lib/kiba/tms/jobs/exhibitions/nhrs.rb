# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Exhibitions
        module Nhrs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :exhibitions__nhrs
              },
              transformer: xforms
            )
          end

          def sources
            %i[
              exh_loan_xrefs__nhr_exh_loan
              exh_obj_loan_obj_xrefs__nhr_exh_loan
              exh_obj_xrefs__nhr_obj_exh
            ].select { |job| Tms.job_output?(job) }
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
