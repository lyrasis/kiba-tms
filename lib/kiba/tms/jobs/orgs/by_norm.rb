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
                source: sources,
                destination: :orgs__by_norm,
                lookup: :orgs__brief
              },
              transformer: xforms
            )
          end

          def sources
            base = [:name_compile__orgs]
            unless Tms::NameCompile.uncontrolled_name_source_tables.empty?
              if Tms.job_output?(
                :name_compile__orgs_uncontrolled_for_norm_lookup
              )
                base << :name_compile__orgs_uncontrolled_for_norm_lookup
              end
            end
            base
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[name prefnormorig contype]
              transform Deduplicate::Table,
                field: :prefnormorig
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :name,
                target: :namenorm
              transform Merge::MultiRowLookup,
                lookup: orgs__brief,
                keycolumn: :namenorm,
                fieldmap: {finalname: :termdisplayname}
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
