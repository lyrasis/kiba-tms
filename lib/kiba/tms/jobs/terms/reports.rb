# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Terms
        module Reports
          extend self

          def in_mig
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[thes_xrefs__with_notation_uniq_typed
                  thes_xrefs__without_notation_uniq_typed],
                destination: :report__terms_in_mig
              },
              transformer: in_mig_xforms
            )
          end

          def in_mig_xforms
            Kiba.job_segment do
            end
          end
        end
      end
    end
  end
end
