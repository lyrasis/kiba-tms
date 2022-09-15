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
            base = Tms::NameCompile.sources - Tms::NameCompile.empty_sources
            base.reject{ |src| src.to_s['__from_can'] unless Tms::ConAltNames.used? }
            unless Tms::AssocParents.used? && Tms::AssocParents.target_tables.any?('Cconstituents')
              base.delete(:name_compile__from_assoc_parents_for_con)
            end
            base.delete(:name_compile__from_loans) unless Tms::Loans.used?
            base.delete(:name_compile__from_loc_approvers) unless Tms::LocApprovers.used?
            base.delete(:name_compile__from_loc_handlers) unless Tms::LocHandlers.used?
            base.delete(:name_compile__from_obj_accession) unless Tms::ObjAccession.used?
            base.delete(:name_compile__from_obj_incoming) unless Tms::ObjIncoming.used?
            base.delete(:name_compile__from_obj_locations) unless Tms::ObjLocations.used?
            base
          end

          def xforms
            Kiba.job_segment do
              transform Append::NilFields, fields: Tms::NameCompile.multi_source_normalizer.get_fields
              transform Rename::Field, from: Tms::Constituents.preferred_name_field, to: :name 
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituentid contype name relation_type termsource],
                target: :fingerprint,
                sep: ' ',
                delete_sources: false
              transform Cspace::NormalizeForID, source: :name, target: :norm
            end
          end
        end
      end
    end
  end
end
