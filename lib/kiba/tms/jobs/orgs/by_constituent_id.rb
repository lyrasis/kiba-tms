# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Orgs
        module ByConstituentId
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__orgs,
                destination: :orgs__by_constituentid,
                lookup: :orgs__brief
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[constituentid norm]
              transform Merge::MultiRowLookup,
                lookup: orgs__brief,
                keycolumn: :norm,
                fieldmap: {name: :termdisplayname}
              transform Tms::Transforms::Names::CleanExplodedId
            end
          end
        end
      end
    end
  end
end
