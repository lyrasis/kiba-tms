# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AssocParents
        module ForConstituents
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__assoc_parents,
                destination: :assoc_parents__for_constituents
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :tablename, value: 'Constituents'
              transform Delete::Fields, fields: :tablename
            end
          end
        end
      end
    end
  end
end
