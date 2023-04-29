# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module FromLocApprovers
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__loc_approvers,
                destination: :names__from_loc_approvers
              },
              transformer: xforms,
              helper: Kiba::Tms::Names.compilation.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: :approver
              transform Deduplicate::Table, field: :approver
              transform Rename::Field, from: :approver,
                to: Tms::Constituents.preferred_name_field
              transform Merge::ConstantValue, target: :constituenttype,
                value: "Person"
              transform Merge::ConstantValue, target: :termsource,
                value: "TMS LocApprovers"
              transform Cspace::NormalizeForID,
                source: Tms::Constituents.preferred_name_field, target: :norm
            end
          end
        end
      end
    end
  end
end
