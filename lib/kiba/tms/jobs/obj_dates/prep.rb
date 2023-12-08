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
              transformer: [
                narrow,
                config.prep_initial_cleaners,
                xforms,
                config.prep_final_cleaners
              ].compact
            )
          end

          def lookups
            %i[
              objects__number_lookup
            ]
          end

          def narrow
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              unless Tms.migration_status == :prelim
                unless config.migrate_inactive
                  transform FilterRows::FieldEqualTo,
                    action: :keep,
                    field: :active,
                    value: "1"
                end
                transform Delete::Fields, fields: :active
              end

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
            end
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: objects__number_lookup,
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
