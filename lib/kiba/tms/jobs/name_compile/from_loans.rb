# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromLoans
          module_function

          def job
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
              namefields = %i[approvedby contact requestedby]
              transform Tms::Transforms::NameCompile::ExtractNamesFromTable, table: 'Loans', fields: namefields
            end
          end
        end
      end
    end
  end
end
