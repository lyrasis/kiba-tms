# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module ByNormPrep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :names__by_norm_prep
              },
              transformer: xforms
            )
          end

          def sources
            base = [:name_compile__main_terms_for_norm_lookup]
            unless Tms::NameCompile.uncontrolled_name_source_tables.empty?
              if Tms.job_output?(
                :name_compile__persons_uncontrolled_for_norm_lookup
              )
                base << :name_compile__persons_uncontrolled_for_norm_lookup
              end

              if Tms.job_output?(
                :name_compile__orgs_uncontrolled_for_norm_lookup
              )
                base << :name_compile__orgs_uncontrolled_for_norm_lookup
              end

              if Tms.job_output?(
                :name_compile__notes_uncontrolled_for_norm_lookup
              )
                base << :name_compile__notes_uncontrolled_for_norm_lookup
              end
            end
            base
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[contype name prefnormorig]
              transform Rename::Field,
                from: :prefnormorig,
                to: :norm
              transform Tms::Transforms::Constituents::NormalizeContype,
                target: :contype
              transform Tms::Transforms::Constituents::AddDefaultContype
            end
          end
        end
      end
    end
  end
end
