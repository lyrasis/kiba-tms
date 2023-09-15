# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Works
        module FromObjectPeriod
          module_function

          def job
            return unless Tms::Objects.named_coll_fields.any?(:period)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_context,
                destination: :works__from_object_period
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :period
              transform Delete::FieldsExcept, fields: :period
              transform Explode::RowsFromMultivalField,
                field: :period,
                delim: Tms.delim
              transform Deduplicate::Table, field: :period
              transform Cspace::NormalizeForID, source: :period, target: :norm
              transform Rename::Field, from: :period, to: :termdisplayname
              transform Merge::ConstantValue,
                target: :worktype,
                value: "Collection"
              if Tms::Names.set_term_source
                transform Merge::ConstantValue,
                  target: :termsource,
                  value: "TMS ObjContext.period"
              end
            end
          end
        end
      end
    end
  end
end
