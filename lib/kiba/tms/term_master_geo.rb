# frozen_string_literal: true

module Kiba
  module Tms
    module TermMasterGeo
      extend self
      
      def prep
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :tms__term_master_geo,
            destination: :prep__term_master_geo
          },
          transformer: prep_xforms
        )
      end

      def prep_xforms
        Kiba.job_segment do
          transform Tms::Transforms::DeleteTmsFields
        end
      end
    end
  end
end
