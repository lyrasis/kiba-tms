# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module ForCompile
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__prep_clean,
                destination: :constituents__for_compile
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :namedata
              transform Delete::Fields,
                fields: %i[constituenttype derivedcontype inconsistent_org_names
                  defaultnameid defaultdisplaybioid namedata norm]
              # remove non-preferred form of name if not including flipped as
              #   variant
              unless config.include_flipped_as_variant
                transform Delete::Fields,
                  fields: config.var_name_field
              end
            end
          end
        end
      end
    end
  end
end
