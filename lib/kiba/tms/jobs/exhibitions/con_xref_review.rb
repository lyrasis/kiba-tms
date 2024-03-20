# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Exhibitions
        module ConXrefReview
          module_function

          def job
            roles = Tms::Exhibitions.con_ref_role_to_field_mapping[:unmapped]
            if roles.blank?
              puts "No unmapped roles to report for "\
                "exhibitions__con_xref_review"
              return
            end

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_refs_for__exhibitions,
                destination: :exhibitions__con_xref_review,
                lookup: :prep__exhibitions
              },
              transformer: xforms(roles)
            )
          end

          def xforms(roles)
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) { row[:role] && roles.any?(row[:role]) }
              transform Merge::MultiRowLookup,
                lookup: prep__exhibitions,
                keycolumn: :recordid,
                fieldmap: {exhibitionnumber: :exhibitionnumber}
              transform Delete::Fields,
                fields: %i[alt_name_used tablename recordid role_type]
              transform Delete::EmptyFields
            end
          end
        end
      end
    end
  end
end
