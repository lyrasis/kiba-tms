# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Collectionobjects
        module ProductionDates
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__date_prep,
                destination: :collectionobjects__production_dates,
                lookup: :dates_translated__lookup
              },
              transformer: get_xforms
            )
          end

          def get_xforms
            base = [
              Tms::DatesTranslated.merge_xforms(keycolumn: :dated),
              xforms
            ]
            base.unshift(config.sample_xforms) if config.sampleable?
            base.compact
          end

          # @todo extract this to project specific config, since it may
          #   differ between projects
          def xforms
            Kiba.job_segment do
              transform Clean::DowncaseFieldValues,
                fields: %i[dateearliestsinglecertainty datelatestcertainty]

              transform Rename::Fields, fieldmap: {
                dateremarks: :datenote,
                dateeffectiveisodate: :dateperiod
              }
              transform Delete::Fields,
                fields: %i[objectid dated]
              transform Merge::ConstantValue,
                target: :date_field_group,
                value: "objectProductionDateGroup"
            end
          end
        end
      end
    end
  end
end
