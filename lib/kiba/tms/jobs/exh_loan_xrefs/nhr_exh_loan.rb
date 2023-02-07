# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhLoanXrefs
        module NhrExhLoan
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :exh_loan_xrefs__nhr_exh_loan
              },
              transformer: xforms
            )
          end

          def sources
            %i[
               exh_loan_xrefs__nhr_exh_loanin
               exh_loan_xrefs__nhr_exh_loanout
              ].select{ |job| Tms.job_output?(job) }
          end

          def xforms
            Kiba.job_segment do
            end
          end
        end
      end
    end
  end
end
