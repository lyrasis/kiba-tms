# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConRefs
        module TypeMismatch
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_refs__prep,
                destination: :con_refs__type_mismatch
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform do |row|
                vals = [row[:detail_role_type],
                  row[:xref_role_type],
                  row[:role_role_type]]
                result = vals.uniq.length
                next if result == 1

                row
              end
            end
          end
        end
      end
    end
  end
end
