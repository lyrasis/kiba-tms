# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhObjLoanObjXrefs
        module NhrExhLoan
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__exh_obj_loan_obj_xrefs,
                destination: :exh_obj_loan_obj_xrefs__nhr_exh_loan,
                lookup: :loans__in_lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: loans__in_lookup,
                keycolumn: :loanid,
                fieldmap: {loanin: :loanid}

              transform do |row|
                loanin = row[:loanin]
                if loanin.blank?
                  row[:item2_type] = 'loansout'
                else
                  row[:item2_type] = 'loansin'
                end
                row
              end

              transform Delete::FieldsExcept,
                fields: %i[exhibitionnumber loannumber item2_type]
              transform Merge::ConstantValue,
                target: :item1_type,
                value: 'exhibitions'
              transform Rename::Fields, fieldmap: {
                exhibitionnumber: :item1_id,
                loannumber: :item2_id
              }
              transform CombineValues::FullRecord, target: :index
              transform Deduplicate::Table,
                field: :index,
                delete_field: true
            end
          end
        end
      end
    end
  end
end
