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
                source: :prep__constituents,
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

              transform FilterRows::FieldPopulated,
                action: :keep,
                field: nonpref
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: nonpref,
                target: :norm
            end
          end
        end
      end
    end
  end
end
