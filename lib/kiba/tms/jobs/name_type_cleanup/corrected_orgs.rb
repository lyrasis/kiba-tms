# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module CorrectedOrgs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_type_cleanup__returned_prep,
                destination: :name_type_cleanup__corrected_orgs
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :correctname
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row){
                  at = row[:authoritytype]
                  cat = row[:correctauthoritytype]
                  (!at.blank? &&
                   at.start_with?('Org')) ||
                    cat == 'o'
                }
              transform FilterRows::FieldMatchRegexp,
                action: :reject,
                field: :correctauthoritytype,
                match: '^[pdn]$'
            end
          end
        end
      end
    end
  end
end
