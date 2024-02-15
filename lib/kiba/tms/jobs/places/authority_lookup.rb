# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module AuthorityLookup
          module_function

          def job
            return unless config.final_cleanup_done

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__final_cleaned_lookup,
                destination: :places__authority_lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :place
              transform Deduplicate::Table,
                field: :place
              transform Cspace::NormalizeForID,
                source: :place,
                target: :norm
              transform Replace::NormWithMostFrequentlyUsedForm,
                normfield: :norm,
                nonnormfield: :place,
                target: :use
            end
          end
        end
      end
    end
  end
end
