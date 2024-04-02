# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansout
        module DroppedNames
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loansout__prep,
                destination: :loansout__dropped_names
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: %i[borrower_extra borrowerscontact_org
                  borrowerscontact_extra]
            end
          end
        end
      end
    end
  end
end
