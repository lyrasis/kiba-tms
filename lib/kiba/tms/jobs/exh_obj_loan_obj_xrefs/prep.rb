# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhObjLoanObjXrefs
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__exh_obj_loan_obj_xrefs,
                destination: :prep__exh_obj_loan_obj_xrefs,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = [:prep__exh_obj_xrefs]
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

              if Tms.job_output?(:prep__loan_obj_xrefs)
                transform Merge::MultiRowLookup,
                  lookup: Tms.get_lookup(
                    jobkey: :prep__loan_obj_xrefs,
                    column: :loanobjxrefid
                  ),
                  keycolumn: :loanobjxrefid,
                  fieldmap: {
                    loannumber: :loannumber,
                    loanid: :loanid
                  },
                  delim: Tms.delim
              end

              if lookups.any?(:prep__exh_obj_xrefs)
                transform Merge::MultiRowLookup,
                  lookup: prep__exh_obj_xrefs,
                  keycolumn: :exhobjxrefid,
                  fieldmap: {
                    exhibitionnumber: :exhibitionnumber
                  },
                  delim: Tms.delim
              end
            end
          end
        end
      end
    end
  end
end
