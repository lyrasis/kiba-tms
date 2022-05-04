# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module Cleanup0
          module PersonsNotKept
            module_function

            def job
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: :nameclean0__prep,
                  destination: :nameclean0__persons_not_kept,
                  lookup: :nameclean0__persons_kept
                },
                transformer: xforms
              )
            end

            def xforms
              Kiba.job_segment do
                transform Tms::Transforms::Names::NotKept
                transform FilterRows::FieldEqualTo, action: :keep, field: :constituenttype, value: 'Person'
                transform Merge::MultiRowLookup,
                  lookup: nameclean0__persons_kept,
                  keycolumn: :norm,
                  fieldmap: {
                    keptname: Tms.constituents.preferred_name_field,
                    target_id: :fp_constituentid
                  }
              end
            end
          end
        end
      end
    end
  end
end
