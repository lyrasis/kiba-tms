# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module ForUncontrolledNameTable
          module_function

          def job(mod:)
            return unless Tms::NameCompile.used?
            return unless mod.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source(mod),
                destination: "name_compile_from__#{mod.filekey}".to_sym
              },
              transformer: xforms(mod)
            )
          end

          def source(mod)
            lkup = Tms::NameCompile.uncontrolled_name_source_tables
            lkup[mod.name.split("::").last]
          end

          def xforms(mod)
            Kiba.job_segment do
              transform Tms::Transforms::NameCompile::ExtractNamesFromTable,
                table: mod.table_name,
                fields: mod.name_fields
            end
          end
        end
      end
    end
  end
end
