# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjDates
        module Inactive
          module_function

          def job
            return unless Tms.migration_status == :prelim

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_dates,
                destination: :obj_dates__inactive,
                lookup: :objects__date_prep
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: objects__date_prep,
                keycolumn: :objectid,
                fieldmap: {main_object_dated_value: :dated}
              transform Delete::Fields,
                fields: %i[objdateid objectid datebegsearch
                  dateendsearch daybegsearch dayendsearch
                  monthbegsearch monthendsearch]
              transform do |row|
                row[:check] = nil
                next row unless row[:active].blank?
                next row if row[:datetext] == row[:main_object_dated_value]

                row[:check] = "y"
                row
              end
            end
          end
        end
      end
    end
  end
end
