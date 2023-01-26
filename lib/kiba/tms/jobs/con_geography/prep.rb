# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConGeography
        module Prep
          module_function

          def job
            return unless config.used?

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
            base << :prep__con_geo_codes if Tms::ConGeoCodes.used?
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              if Tms::ConGeoCodes.used
                transform Merge::MultiRowLookup,
                  lookup: prep__con_geo_codes,
                  keycolumn: :geocodeid,
                  fieldmap: {geocode: :congeocode}
              end
              transform Delete::Fields, fields: :geocodeid

              if config.cleaner
                transform config.cleaner
              end
            end
          end
        end
      end
    end
  end
end
