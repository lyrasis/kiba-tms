# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Nhrs
        module ObjectObjectexit
          module_function

          def job
            config.config.rectype1 = "Collectionobjects"
            config.config.rectype2 = "Objectexit"
            config.config.sample_from = :rectype1
            config.config.job_xforms = xforms

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_deaccession,
                destination: :nhrs__object_objectexit
              },
              transformer: config.transformers
            )
          end

          def xforms
            case Tms::ObjDeaccession.treatment
            when :one_to_one then one_to_one_xforms
            when :per_sale then per_sale_xforms
            else raise("No NHR xforms for #{Tms::ObjDeaccession.treatment} "\
                       "treatment")
            end
          end

          def one_to_one_xforms
            raise("Not yet implemented")
          end

          def per_sale_xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[salenumber objectnumber]
              transform Rename::Field,
                from: :objectnumber,
                to: :item1_id
              transform Merge::MultiRowLookup,
                lookup: Tms.get_lookup(
                  jobkey: :obj_deaccession__shape,
                  column: :salenumber
                ),
                keycolumn: :salenumber,
                fieldmap: {item2_id: :exitnumber}
              transform Delete::Fields,
                fields: :salenumber
            end
          end
        end
      end
    end
  end
end
