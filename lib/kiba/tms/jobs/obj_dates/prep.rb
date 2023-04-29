# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjDates
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_dates,
                destination: :prep__obj_dates,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            %i[
              objects__numbers_cleaned
            ]
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if config.drop_inactive
                transform FilterRows::FieldEqualTo,
                  action: :keep,
                  field: :active,
                  value: "1"
              end
              transform Delete::Fields, fields: :active

              transform Tms::Transforms::DeleteTmsFields

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              transform Tms.data_cleaner if Tms.data_cleaner

              transform Clean::RegexpFindReplaceFieldVals,
                fields: :eventtype,
                find: '^[(\[]not entered[)\]]$',
                replace: "",
                casesensitive: false

              transform Clean::RegexpFindReplaceFieldVals,
                fields: %i[datebegsearch dateendsearch daybegsearch dayendsearch
                  monthbegsearch monthendsearch dateeffectiveisodate],
                find: "^0$",
                replace: ""

              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: config.content_fields
              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :objectid,
                fieldmap: {objectnumber: :objectnumber}
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :objectnumber
            end
          end
        end
      end
    end
  end
end
