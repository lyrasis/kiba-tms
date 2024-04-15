# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Valuationcontrols
        module NhrObj
          module_function

          def job
            return unless Tms::ObjInsurance.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :valuationcontrols__from_obj_insurance,
                destination: :valuationcontrols__nhr_obj
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[objectnumber]
              transform Deduplicate::Table, field: :objectnumber
              transform Merge::MultiRowLookup,
                lookup: Tms.get_lookup(
                  jobkey: :valuationcontrols__all,
                  column: :objectnumber
                ),
                keycolumn: :objectnumber,
                fieldmap: {vcnum: :valuationcontrolrefnumber},
                delim: Tms.delim
              transform Explode::RowsFromMultivalField,
                field: :vcnum,
                delim: Tms.delim
              transform Rename::Fields, fieldmap: {
                objectnumber: :item1_id,
                vcnum: :item2_id
              }
              transform Merge::ConstantValues, constantmap: {
                item1_type: "collectionobjects",
                item2_type: "valuationcontrols"
              }
            end
          end
        end
      end
    end
  end
end
