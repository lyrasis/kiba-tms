# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAddress
        module CountriesUnmappedBeforeClean
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_address__shaped,
                destination: :con_address__countries_unmapped_before_clean
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  !row[:origcountry].blank? &&
                    row[:init_addresscountry].blank?
                end
            end
          end
        end
      end
    end
  end
end
