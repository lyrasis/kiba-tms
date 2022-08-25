# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromLocHandlers
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__loc_handlers,
                destination: :name_compile__from_loc_handlers
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::NameCompile::ExtractNamesFromTable,
                table: 'LocHandlers',
                fields: [:handler]              
            end
          end
        end
      end
    end
  end
end
