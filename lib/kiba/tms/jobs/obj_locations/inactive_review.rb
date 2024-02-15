# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module InactiveReview
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__location_names_merged,
                destination: :obj_locations__inactive_review
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :objlocationid,
                value: "-1"
              transform FilterRows::FieldMatchRegexp,
                action: :reject,
                field: :fingerprint,
                match: "^locationid: -1 "
              transform Delete::FieldValueMatchingRegexp,
                fields: %i[inactive],
                match: "^0$"
              transform Delete::FieldValueMatchingRegexp,
                fields: %i[is_temp],
                match: "^n$"
              transform Delete::Fields,
                fields: %i[prevobjlocid nextobjlocid
                  componentid schedobjlocid homelocationid
                  fullhomelocid fingerprint locauth]
            end
          end
        end
      end
    end
  end
end
