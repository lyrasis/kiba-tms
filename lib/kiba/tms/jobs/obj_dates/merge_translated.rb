# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjDates
        module MergeTranslated
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_dates,
                destination: :obj_dates__merge_translated,
                lookup: :dates_translated__lookup
              },
              transformer: [
                Tms::DatesTranslated.merge_xforms(keycolumn: :datetext),
                xforms
              ]
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: :datetext
              transform Clean::DowncaseFieldValues,
                fields: %i[dateearliestsinglecertainty datelatestcertainty]
              transform do |row|
                per = row[:dateperiod]
                eff = row[:dateeffectiveisodate]
                row[:dateperiod] = nil
                row.delete(:dateeffectiveisodate)
                next row if per.blank? && eff.blank?

                val = per.blank? ? eff : [eff, per].compact.join("; ")
                row[:dateperiod] = val
                row
              end

              nv_pad_fields = Tms::DatesTranslated.cs_date_fields +
                %i[assocdatetype assocdatenote]
              transform Replace::EmptyFieldValues,
                fields: nv_pad_fields, value: "%NULLVALUE%"
            end
          end
        end
      end
    end
  end
end
