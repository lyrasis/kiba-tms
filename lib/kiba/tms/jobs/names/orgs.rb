# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module Orgs
          module_function

          def desc
              <<~DESC
                With lookup on :constituentid gives :person and :org columns
                from which to merge authorized form of name. Also gives a
                :prefname and :nonprefname columns for use if type of name does
                not matter. Only name values are retained in this table.
              DESC
          end

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__prep_clean,
                destination: :names__orgs
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              prefname = Tms::Constituents.preferred_name_field

              transform FilterRows::FieldMatchRegexp,
                action: :keep,
                field: :contype,
                match: '^Org'
            end
          end
        end
      end
    end
  end
end
