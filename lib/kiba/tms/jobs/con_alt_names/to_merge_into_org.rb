# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAltNames
        module ToMergeIntoOrg
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_alt_names__only_alt,
                destination: :con_alt_names__to_merge_org
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :kept, value: 'y'
              transform FilterRows::FieldPopulated, action: :keep, field: :org
            end
          end
        end
      end
    end
  end
end

