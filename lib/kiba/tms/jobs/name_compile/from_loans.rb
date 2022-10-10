# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromLoans
          module_function

          def job
            return unless config.used?
            return unless Tms::Loans.used?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :tms__loans,
                destination: :name_compile__from_loans
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::NameCompile::ExtractNamesFromTable,
                table: 'Loans',
                fields: Tms::Loans.name_fields
            end
          end
        end
      end
    end
  end
end
