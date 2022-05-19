# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Terms
        module UsedRowData
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__terms,
                destination: :terms__used_row_data,
                lookup: :term_master_thes__used_in_xrefs
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform do |row|
                tmid = row.fetch(:termmasterid, nil)
                next if tmid.blank?

                next row if term_master_thes__used_in_xrefs.key?(tmid)
              end
            end
          end
        end
      end
    end
  end
end
