# frozen_string_literal: true

module Kiba
  module Tms
    module Departments
      extend self
      
      def prep
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :tms__departments,
            destination: :prep__departments
          },
          transformer: prep_xforms
        )
      end

      def prep_xforms
        Kiba.job_segment do
          transform Tms::Transforms::DeleteTmsFields
          transform Delete::Fields, fields: %i[mnemonic inputid numrandomobjs defaultformid maintableid]
          transform FilterRows::FieldMatchRegexp,
            action: :reject,
            field: :department,
            match: '^(\(|\[)[Nn]ot [Aa]ssigned(\)|\])$'
        end
      end
    end
  end
end
