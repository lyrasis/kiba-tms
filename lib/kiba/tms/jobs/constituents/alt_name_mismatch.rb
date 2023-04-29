# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module AltNameMismatch
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__constituents,
                destination: :constituents__alt_name_mismatch,
                lookup: %i[prep__con_alt_names]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              prefname = Tms::Constituents.preferred_name_field

              # Merge in the default name from the alternate name table and add a column comparing it
              #   to the preferred name. We expect this to be
              transform Kiba::Tms::Transforms::Constituents::MergeDefaultAltName,
                alt_names: prep__con_alt_names
              transform Compare::FieldValues,
                fields: [prefname, "alt_#{prefname}".to_sym], target: :name_alt_compare
              transform Delete::FieldValueContainingString,
                fields: :name_alt_compare, match: "same"
              transform FilterRows::FieldPopulated, action: :keep,
                field: :name_alt_compare
            end
          end
        end
      end
    end
  end
end
