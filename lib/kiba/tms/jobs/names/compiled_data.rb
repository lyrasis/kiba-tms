# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module CompiledData
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[names__initial_compile],
                destination: :names__compiled,
                lookup: :names__flagged_duplicates
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::Constituents::CleanPersonNamePartsFromOrg
              transform Tms::Transforms::Constituents::CleanOrgNameInfoFromPerson
              transform Tms::Transforms::Constituents::FlagPersonNamesLackingNameDetails

              # This marks all rows with duplicate values as duplicates, not just subsequent rows
              transform Merge::MultiRowLookup,
                fieldmap: {normnew: :norm},
                lookup: names__flagged_duplicates,
                keycolumn: :norm,
                constantmap: {duplicate: "y"}
              transform Delete::Fields, fields: %i[normnew constituentid]

              transform Rename::Field, from: Kiba::Tms::Constituents.preferred_name_field, to: :preferred_name_form
              transform Rename::Field, from: Kiba::Tms::Constituents.var_name_field, to: :variant_name_form
              transform Rename::Field, from: :norm, to: :normalized_form
              transform Delete::EmptyFields
            end
          end
        end
      end
    end
  end
end
