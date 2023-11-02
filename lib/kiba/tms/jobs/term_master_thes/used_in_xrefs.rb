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
                destination: :term_master_thes__used_in_xrefs
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              lookup = Tms.get_lookup(
                jobkey: :terms__used_in_xrefs,
                column: :termmasterid
              )
              transform do |row|
                tmid = row[:termmasterid]
                next if tmid.blank?

                next row if lookup.key?(tmid)
              end
            end
          end
        end
      end
    end
  end
end
