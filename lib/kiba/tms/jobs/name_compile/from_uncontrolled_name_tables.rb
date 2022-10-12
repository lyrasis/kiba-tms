# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromUncontrolledNameTables
          module_function

          def job
            return unless Tms::NameCompile.used?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: sources,
                destination: :name_compile__from_uncontrolled_name_tables
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def sources
            Tms::NameCompile.uncontrolled_name_source_tables
              .keys
              .map{ |key| Tms.const_get(key) }
              .map{ |mod| "name_compile_from__#{mod.filekey}".to_sym }
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::NameTypeCleanup::ExtractIdSegment,
                target: :name,
                segment: :name
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :name,
                target: :constituentid
              transform Deduplicate::Table, field: :constituentid
            end
          end
        end
      end
    end
  end
end
