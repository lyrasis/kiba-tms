# frozen_string_literal: true

module Kiba
  module Tms
    module ConAltNames
      extend self
      
      def prep
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :tms__con_alt_names,
            destination: :prep__con_alt_names,
            lookup: :prep__constituents
          },
          transformer: prep_xforms
        )
      end

      def prep_xforms
        Kiba.job_segment do
          transform Tms::Transforms::DeleteTmsFields
          transform Merge::MultiRowLookup,
            keycolumn: :constituentid,
            lookup: prep__constituents,
            fieldmap: {
              constituentdisplayname: :displayname,
              constituenttype: :constituenttype,
              constituentdefaultnameid: :defaultnameid
            }
        end
      end
    end
  end
end
