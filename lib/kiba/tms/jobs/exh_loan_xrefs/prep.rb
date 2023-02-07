# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhLoanXrefs
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__exh_loan_xrefs,
                destination: :prep__exh_loan_xrefs,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
                      prep__exhibitions
                      prep__loans
                     ]
            base.select{ |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields,
                  fields: config.omitted_fields
              end

              if lookups.any?(:prep__exhibitions)
                transform Merge::MultiRowLookup,
                  lookup: prep__exhibitions,
                  keycolumn: :exhibitionid,
                  fieldmap: {
                    exhibitionnumber: :exhibitionnumber
                  },
                  delim: Tms.delim
              end

              if lookups.any?(:prep__loans)
                transform Merge::MultiRowLookup,
                  lookup: prep__loans,
                  keycolumn: :loanid,
                  fieldmap: {
                    loannumber: :loannumber,
                    loantype: :loantype
                  },
                  delim: Tms.delim
              end

              transform Merge::ConstantValue,
                target: :item1_type,
                value: 'exhibitions'
            end
          end
        end
      end
    end
  end
end
