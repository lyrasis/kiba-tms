# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module ForUncontrolledNameTable
          extend Tms::Mixins::ForTable
          module_function

          def job(mod:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_type_cleanup__returned_prep,
                destination: "name_type_cleanup_for__#{mod.filekey}".to_sym
              },
              transformer: xforms(mod)
            )
          end

          def xforms(mod)
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  ts = row[:termsource]
                  ts.include?("TMS #{mod.table_name}")
                end
              transform Delete::Fields, fields: :termsource
            end
          end
        end
      end
    end
  end
end
