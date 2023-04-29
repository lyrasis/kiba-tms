# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module ByAllNorms
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[
                  constituents__by_norm
                  constituents__by_norm_orig
                  constituents__by_nonpref_norm
                ],
                destination: :constituents__by_all_norms
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :combined,
                delete_field: false
            end
          end
        end
      end
    end
  end
end
