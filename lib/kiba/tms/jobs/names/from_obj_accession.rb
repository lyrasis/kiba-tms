# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module FromObjAccession
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :tms__obj_accession,
                destination: :names__from_obj_accession
              },
              transformer: xforms,
              helper: Kiba::Tms::Names.compilation.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[authorizer initiator]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[authorizer initiator], target: :combined,
                delim: "|||", delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep,
                field: :combined
              transform Delete::FieldsExcept, fields: :combined
              transform Explode::RowsFromMultivalField, field: :combined,
                delim: "|||"
              transform Deduplicate::Table, field: :combined
              transform Cspace::NormalizeForID, source: :combined, target: :norm
              transform Rename::Field, from: :combined,
                to: Tms::Constituents.preferred_name_field
              transform Merge::ConstantValue, target: :termsource,
                value: "TMS Objaccession"
            end
          end
        end
      end
    end
  end
end
