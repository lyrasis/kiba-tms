# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ThesXrefTypes
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__thes_xref_types,
                destination: :prep__thes_xref_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields, fields: %i[multiselect archivedeletes showguideterms broadesttermfirst
                numlevels alwaysdisplayfullpath]
              transform Tms::Transforms::DeleteNoValueTypes,
                field: :thesxreftype
            end
          end
        end
      end
    end
  end
end
