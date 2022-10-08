# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module ForConstituents
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_type_cleanup__returned_prep,
                destination: :name_type_cleanup__for_constituents
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldMatchRegexp,
                action: :keep,
                field: :termsource,
                match: '^TMS Constituents\.(orgs|persons)$'

              transform Delete::Fields, fields: :termsource
            end
          end
        end
      end
    end
  end
end
