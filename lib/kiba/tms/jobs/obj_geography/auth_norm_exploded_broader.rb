# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module AuthNormExplodedBroader
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_geography__auth_norm_exploded_report,
                destination: :obj_geography__auth_norm_exploded_broader

              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform CombineValues::FromFieldsWithDelimiter,
               sources: %i[key left_combined],
               target: :broaderkey,
               delim: " ",
               delete_sources: false
             transform Deduplicate::Table,
               field: :broaderkey,
               delete_field: false
             transform Delete::Fields,
               fields: %i[rightcombined rightcat]
            end
          end
        end
      end
    end
  end
end
