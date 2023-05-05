# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromReferenceMaster
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__reference_master,
                destination: :name_compile__from_reference_master
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[stmtresponsibility]
              transform FilterRows::FieldPopulated, action: :keep,
                field: :stmtresponsibility
              transform Deduplicate::Table, field: :stmtresponsibility
              transform Rename::Field, from: :stmtresponsibility,
                to: Tms::Constituents.preferred_name_field
              transform Merge::ConstantValue, target: :termsource,
                value: "TMS ReferenceMaster.stmtresponsibility"
              transform Merge::ConstantValue, target: :relation_type,
                value: "_main term"
            end
          end
        end
      end
    end
  end
end
