# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TermMasterThes
        module UsedInXrefs
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__term_master_thes,
                destination: :term_master_thes__used_in_xrefs,
                lookup: :terms__used_in_xrefs
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform do |row|
                tmid = row.fetch(:termmasterid, nil)
                next if tmid.blank?

                next row if terms__used_in_xrefs.key?(tmid)
              end
            end
          end
        end
      end
    end
  end
end
