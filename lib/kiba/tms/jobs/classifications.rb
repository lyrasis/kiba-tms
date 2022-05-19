# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Classifications
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__classifications,
              destination: :prep__classifications
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::EmptyFields
            transform FilterRows::FieldEqualTo, action: :reject, field: :classification, value: '(not assigned)'
          end
        end
      end
    end
  end
end
