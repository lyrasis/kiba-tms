# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Persons
        module ByConstituentId
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__persons,
                destination: :persons__by_constituentid
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              prefname = Tms::Constituents.preferred_name_field

              transform Delete::FieldsExcept,
                fields: [:constituentid, prefname]
              transform Rename::Field,
                from: prefname,
                to: :name
              transform Tms::Transforms::Names::CleanExplodedId
            end
          end
        end
      end
    end
  end
end
