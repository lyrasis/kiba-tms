# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Persons
        module ByNorm
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :persons__by_norm,
                lookup: :persons__brief
              },
              transformer: xforms
            )
          end

          def sources
            base = [:name_compile__persons]
            unless Tms::NameCompile.uncontrolled_name_source_tables.empty?
              base << :name_compile__persons_uncontrolled_for_norm_lookup
            end
            base << :name_compile__person_from_con_org_name_parts_for_norm_lookup
            base.select{ |job| Tms.job_output?(job) }
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
                lookup: persons__brief,
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
