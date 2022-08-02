# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module FromReferenceMaster
          module_function

          def job
            return unless Tms::Names.compilation.include_ref_stmt_resp
            
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :tms__reference_master,
                destination: :names__from_reference_master
              },
              transformer: xforms,
              helper: Kiba::Tms::Names.compilation.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[stmtresponsibility]
              transform FilterRows::FieldPopulated, action: :keep, field: :stmtresponsibility
              transform Deduplicate::Table, field: :stmtresponsibility
              transform Cspace::NormalizeForID, source: :stmtresponsibility, target: :norm
              transform Rename::Field, from: :stmtresponsibility, to: Tms::Constituents.preferred_name_field
              transform Merge::ConstantValue, target: :termsource, value: 'TMS ReferenceMaster.stmtresponsibility'
            end
          end
        end
      end
    end
  end
end
