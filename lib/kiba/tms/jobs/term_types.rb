# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TermTypes
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__term_types,
              destination: :prep__term_types
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::Fields, fields: %i[termtypemnemonic]
          end
        end
      end
    end
  end
end
