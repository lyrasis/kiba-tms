# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Nhrs
        module ExhibitionLoanout
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[
                  nhrs__exhibition_loanout_direct
                  nhrs__exhibition_loanout_indirect
                ],
                destination: :nhrs__exhibition_loanout
              },
              transformer: config.finalize_xforms
            )
          end
        end
      end
    end
  end
end
