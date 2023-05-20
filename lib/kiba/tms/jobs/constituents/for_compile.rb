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
              unless config.include_flipped_as_variant
                transform Delete::Fields,
                  fields: config.var_name_field
                transform Deduplicate::Flag,
                  on_field: :combined,
                  in_field: :dropping,
                  using: {}

                # Avoid confusion by marking manually dropped names as such
                if Tms.migration_status == :dev
                  pref = Tms::Constituents.preferred_name_field
                  transform do |row|
                    name = row[pref]
                    next row if name.blank?
                    next row unless name ==
                      Tms::Names.dropped_name_indicator
                    next row unless row[:dropping] == "n"

                    row[:dropping] = "y"
                    row
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
