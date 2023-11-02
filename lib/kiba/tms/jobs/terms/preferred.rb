# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Terms
        module Preferred
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__terms,
                destination: :terms__preferred
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              pref_term_ids = Tms.get_lookup(
                jobkey: :term_master_thes__used_in_xrefs,
                column: :preferredtermid
              ).keys

              transform do |row|
                next unless pref_term_ids.include?(row[:termid])

                row
              end
            end
          end
        end
      end
    end
  end
end
