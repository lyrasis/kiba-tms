# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Departments
        module Prep
          extend self
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__departments,
                destination: :prep__departments
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::TmsTableNames, source: :maintableid
              transform Delete::Fields, fields: %i[mnemonic inputid numrandomobjs defaultformid maintableid]
              transform Tms::Transforms::DeleteNoValueTypes, field: :department
            end
          end
        end
      end
    end
  end
end
