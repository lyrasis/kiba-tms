# frozen_string_literal: true

module Kiba
  module Tms
    module TermMaster
      extend self
      
      def prep
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :tms__term_master,
            destination: :prep__term_master
          },
          transformer: prep_xforms
        )
      end

      def prep_xforms
        Kiba.job_segment do
          transform Tms::Transforms::DeleteTmsFields
          transform Delete::Fields, fields: %i[dateentered datemodified termclassid displaydescriptorid]
        end
      end
    end
  end
end
