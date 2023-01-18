# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Orgs
        module ByNorm
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: :orgs__by_norm,
                lookup: :orgs__brief
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  contype = row[:contype]
                  reltype = row[:relation_type]
                  contype &&
                    reltype &&
                    contype.start_with?('Organization') &&
                    reltype == '_main term'
                end
              transform Delete::FieldsExcept,
                fields: %i[name prefnormorig]
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :name,
                target: :namenorm
              transform Merge::MultiRowLookup,
                lookup: orgs__brief,
                keycolumn: :namenorm,
                fieldmap: {name: :termdisplayname}
              transform Delete::Fields, fields: :namenorm
              transform Rename::Field, from: :prefnormorig, to: :norm
              transform Deduplicate::FieldValues,
                fields: %i[name],
                sep: Tms.delim
            end
          end
        end
      end
    end
  end
end
