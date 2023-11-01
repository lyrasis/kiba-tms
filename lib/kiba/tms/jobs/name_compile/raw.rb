# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module Raw
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :name_compile__raw
              },
              transformer: xforms
            )
          end

          def sources
            base = Tms::NameCompile.sources
            unless Tms::ConAltNames.used?
              base.reject! { |src| src.to_s["__from_can"] }
            end
            unless Tms::AssocParents.used? &&
                Tms::AssocParents.target_tables.any?("Constituents")
              base.delete(:name_compile__from_assoc_parents_for_con)
            end
            base.select { |job| Tms.job_output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform Rename::Field,
                from: Tms::Constituents.preferred_name_field,
                to: :name
              transform FilterRows::AllFieldsPopulated,
                action: :keep,
                fields: %i[contype name]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituentid contype name relation_type
                  termsource],
                target: :fingerprint,
                delim: " ",
                delete_sources: false
              transform Cspace::NormalizeForID, source: :name, target: :norm
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
