# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Terms
        module UsedInXrefs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__terms,
                destination: :terms__used_in_xrefs,
                lookup: :thes_xrefs__term_ids_used
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform do |row|
                tid = row.fetch(:termid, nil)
                next if tid.blank?

                next row if thes_xrefs__term_ids_used.key?(tid)
              end
            end
          end
        end
      end
    end
  end
end
