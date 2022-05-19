# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ClassificationNotations
        module Used
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__classification_notations,
                destination: :classification_notations__used,
                lookup: :classification_notations__ids_used
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform do |row|
                cnid = row.fetch(:classificationnotationid, nil)
                next if cnid.blank?

                next row if classification_notations__ids_used.key?(cnid)
              end
            end
          end
        end
      end
    end
  end
end
