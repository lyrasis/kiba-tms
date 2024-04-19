# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Nhrs
        module ObjectexitValuation
          module_function

          def job
            config.config.rectype1 = "Objectexit"
            config.config.rectype2 = "Valuationcontrols"
            config.config.sample_from = :rectype1
            config.config.job_xforms = xforms

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :valuationcontrols__all,
                destination: :nhrs__objectexit_valuation
              },
              transformer: config.transformers
            )
          end

          def xforms
            case Tms::ObjDeaccession.treatment
            when :one_to_one
              [filter_xforms, one_to_one_xforms]
            when :per_sale
              [filter_xforms, per_sale_xforms]
            else raise("No NHR xforms for #{Tms::ObjDeaccession.treatment} "\
                       "treatment")
            end
          end

          def filter_xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :deaccessionid
              transform Delete::FieldsExcept,
                fields: %i[valuationcontrolrefnumber deaccessionid]
            end
          end

          def one_to_one_xforms
            raise("Not yet implemented")
          end

          def per_sale_xforms
            Kiba.job_segment do
              transform Rename::Field,
                from: :valuationcontrolrefnumber,
                to: :item2_id
              transform Merge::MultiRowLookup,
                lookup: Tms.get_lookup(
                  jobkey: :prep__obj_deaccession,
                  column: :deaccessionid
                ),
                keycolumn: :deaccessionid,
                fieldmap: {salenumber: :salenumber}

              transform Merge::MultiRowLookup,
                lookup: Tms.get_lookup(
                  jobkey: :obj_deaccession__shape,
                  column: :salenumber
                ),
                keycolumn: :salenumber,
                fieldmap: {item1_id: :exitnumber}
              transform Delete::Fields,
                fields: %i[salenumber deaccessionid]
            end
          end
        end
      end
    end
  end
end
