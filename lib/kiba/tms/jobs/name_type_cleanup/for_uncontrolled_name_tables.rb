# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module ForUncontrolledNameTables
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :name_type_cleanup__for_uncontrolled_name_tables
              },
              transformer: xforms
            )
          end

          def sources
            Tms::NameCompile.uncontrolled_name_source_tables
              .keys
              .map{ |key| Tms.const_get(key) }
              .map{ |mod| "name_type_cleanup_for__#{mod.filekey}".to_sym }
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::NameTypeCleanup::ExtractIdSegment,
                target: :name,
                segment: :name
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :name,
                target: :constituentid
            end
          end
        end
      end
    end
  end
end
