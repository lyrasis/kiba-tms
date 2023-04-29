# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaXrefs
        module Nhrs
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :media_xrefs__nhrs
              },
              transformer: xforms
            )
          end

          def sources
            base = []
            base << :media_xrefs__accession_lot if config.for?("AccessionLot")
            base << :media_xrefs__cond_line_items if config.for?("CondLineItems")
            base << :media_xrefs__exhibitions if config.for?("Exhibitions")
            if config.for?("Loans")
              base << :media_xrefs__loansin
              base << :media_xrefs__loansout
            end
            base << :media_xrefs__objects if config.for?("Objects")
            base << :media_xrefs__obj_insurance if config.for?("ObjInsurance")
            base.select{ |job| Tms.job_output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[item1_id item2_id item1_type item2_type]
              transform FilterRows::AllFieldsPopulated,
                action: :keep,
                fields: %i[item1_id item2_id]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[item1_id item2_id item1_type item2_type],
                target: :combined,
                sep: " ",
                delete_sources: false
              transform Deduplicate::Table,
                field: :combined,
                delete_field: true
            end
          end
        end
      end
    end
  end
end
