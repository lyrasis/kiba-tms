# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConGeography
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_geography,
                destination: :prep__con_geography,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__con_geo_codes if Tms::ConGeoCodes.used
            base
          end
          
          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields,
                fields: [Tms::ConGeography.delete_fields, Tms::ConGeography.empty_fields].flatten
              
              if Tms::ConGeoCodes.used
              transform Merge::MultiRowLookup,
                lookup: prep__con_geo_codes,
                keycolumn: :geocodeid,
                fieldmap: {geocode: :congeocode}
              end
              transform Delete::Fields, fields: :geocodeid
            end
          end
        end
      end
    end
  end
end
