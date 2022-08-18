# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromLocApprovers
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__loc_approvers,
                destination: :name_compile__from_loc_approvers
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: :approver
              transform Deduplicate::Table, field: :approver
              transform Rename::Field, from: :approver, to: Tms::Constituents.preferred_name_field
              transform Merge::ConstantValue, target: :contype, value: 'Person'
              transform Merge::ConstantValue, target: :termsource, value: 'TMS LocApprovers'
              transform Merge::ConstantValue, target: :relation_type, value: '_main term'
            end
          end
        end
      end
    end
  end
end
