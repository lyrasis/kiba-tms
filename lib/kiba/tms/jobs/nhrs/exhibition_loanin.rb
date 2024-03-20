# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Nhrs
        module ExhibitionLoanin
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[
                  nhrs__exhibition_loanin_direct
                  nhrs__exhibition_loanin_indirect
                ],
                destination: :nhrs__exhibition_loanin
              },
              transformer: config.finalize_xforms
            )
          end
        end
      end
    end
  end
end
