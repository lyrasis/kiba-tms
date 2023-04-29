# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module PersonFromConOrgNamePartsForNormLookup
          module_function

          def job
            return unless config.used?
            return unless treatment == :contact_person

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sourcejob,
                destination: :name_compile__person_from_con_org_name_parts_for_norm_lookup
              },
              transformer: xforms
            )
          end

          def sourcejob
            :name_compile__from_con_org_with_name_parts
          end

          def treatment
            config.source_treatment[sourcejob]
          end

          def xforms
            Kiba.job_segment do
              prefname = Tms::Constituents.preferred_name_field

              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  contype = row[:contype]
                  contype && contype.start_with?("Person")
                end
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: prefname,
                target: :prefnormorig
              transform Rename::Field, from: prefname, to: :name
              transform Delete::FieldsExcept,
                fields: %i[name prefnormorig contype]
            end
          end
        end
      end
    end
  end
end
