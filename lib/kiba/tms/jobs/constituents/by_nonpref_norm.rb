# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module ByNonprefNorm
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__prep_clean,
                destination: :constituents__by_nonpref_norm
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              nonpref = config.var_name_field
              pref = config.preferred_name_field

              transform FilterRows::FieldPopulated,
                action: :keep,
                field: nonpref
              transform Delete::Fields, fields: :norm
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: nonpref,
                target: :norm
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype norm],
                target: :combined,
                delim: " ",
                delete_sources: false
              transform Delete::FieldsExcept,
                fields: config.lookup_job_fields
            end
          end
        end
      end
    end
  end
end
