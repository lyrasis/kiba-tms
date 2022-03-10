# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module InBetween
        # Namespace for jobs that compile names into cleanup reports
        module NameCompilation
          module_function

          def from_constituents
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__constituents,
                destination: :names__from_constituents
              },
              transformer: from_constituents_xforms,
              helper: Kiba::Tms.config.name_compilation.multi_source_normalizer
            )
          end

          def from_constituents_xforms
            Kiba.job_segment do
              unless Kiba::Tms.config.constituents.date_append.to_types == [:none]
                transform Kiba::Tms::Transforms::Constituents::AppendDatesToNames
              end
              transform Delete::Fields, fields: %i[namedata constituentid]
              transform Cspace::NormalizeForID,
                source: Tms.config.constituents.preferred_name_field,
                target: :norm
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Constituents'
            end
          end

          def from_loans
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__loans,
                destination: :names__from_loans
              },
              transformer: from_loans_xforms,
              helper: Kiba::Tms.config.name_compilation.multi_source_normalizer
            )
          end

          def from_loans_xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[approvedby contact requestedby]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[approvedby contact requestedby], target: :combined,
                sep: '|||', delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep, field: :combined
              transform Delete::FieldsExcept, fields: :combined
              transform Explode::RowsFromMultivalField, field: :combined, delim: '|||'
              transform Deduplicate::Table, field: :combined
              transform Cspace::NormalizeForID, source: :combined, target: :norm
              transform Rename::Field, from: :combined, to: Tms.config.constituents.preferred_name_field
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Loans'
            end
          end

          def from_obj_accession
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__obj_accession,
                destination: :names__from_obj_accession
              },
              transformer: from_obj_accession_xforms,
              helper: Kiba::Tms.config.name_compilation.multi_source_normalizer
            )
          end

          def from_obj_accession_xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[authorizer initiator]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[authorizer initiator], target: :combined,
                sep: '|||', delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep, field: :combined
              transform Delete::FieldsExcept, fields: :combined
              transform Explode::RowsFromMultivalField, field: :combined, delim: '|||'
              transform Deduplicate::Table, field: :combined
              transform Cspace::NormalizeForID, source: :combined, target: :norm
              transform Rename::Field, from: :combined, to: Tms.config.constituents.preferred_name_field
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Objaccession'
            end
          end

          def from_obj_locations
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__obj_locations,
                destination: :names__from_obj_locations
              },
              transformer: from_obj_locations_xforms,
              helper: Kiba::Tms.config.name_compilation.multi_source_normalizer
            )
          end

          def from_obj_locations_xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[approver handler requestedby]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[approver handler requestedby], target: :combined,
                sep: '|||', delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep, field: :combined
              transform Delete::FieldsExcept, fields: :combined
              transform Explode::RowsFromMultivalField, field: :combined, delim: '|||'
              transform Deduplicate::Table, field: :combined
              transform Cspace::NormalizeForID, source: :combined, target: :norm
              transform Rename::Field, from: :combined, to: Tms.config.constituents.preferred_name_field
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Obj_Locations'
            end
          end

          def compiled
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[names__from_constituents names__from_loans names__from_obj_accession names__from_obj_locations],
                destination: :names__compiled
              },
              transformer: compiled_xforms
            )
          end

          def compiled_xforms
            Kiba.job_segment do
              @deduper = {}
              transform Deduplicate::Flag, on_field: :norm, in_field: :duplicate, using: @deduper
              transform Append::NilFields, fields: Tms.config.name_compilation.multi_source_normalizer.get_fields
            end
          end
        end
      end
    end
  end
end
