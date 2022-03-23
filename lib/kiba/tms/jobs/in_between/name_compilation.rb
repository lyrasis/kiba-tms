# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module InBetween
        # Namespace for jobs that compile names into cleanup reports
        module NameCompilation
          module_function

          def from_constituents
            xforms = Kiba.job_segment do              
              transform Delete::Fields, fields: %i[namedata defaultdisplaybioid defaultnameid displaydate]
              unless Kiba::Tms.constituents.date_append.to_types == [:none]
                transform Kiba::Tms::Transforms::Constituents::AppendDatesToNames
              end
              transform Rename::Field, from: :position, to: :contact_role
              transform Cspace::NormalizeForID,
                source: Tms.constituents.preferred_name_field,
                target: :norm
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Constituents'
            end

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :constituents__alt_names_merged,
                destination: :names__from_constituents
              },
              transformer: xforms,
              helper: Kiba::Tms.name_compilation.multi_source_normalizer
            )
          end

          def from_constituents_orgs_from_persons
            xforms = Kiba.job_segment do
              prefname = Tms.constituents.preferred_name_field
              transform Delete::FieldsExcept, fields: [:institution, prefname, :contact_role, :constituenttype]
              transform FilterRows::FieldPopulated, action: :keep, field: :institution
              transform FilterRows::FieldEqualTo, action: :keep, field: :constituenttype, value: 'Person'
              transform Rename::Field, from: prefname, to: :contact_person
              transform Rename::Field, from: :institution, to: prefname
              transform Cspace::NormalizeForID,
                source: prefname,
                target: :norm
              transform CombineValues::FromFieldsWithDelimiter, sources: %i[norm contact_person contact_role], target: :combined,
                sep: ' - ', delete_sources: false
              transform Deduplicate::Table, field: :combined, delete_field: true
              transform Merge::ConstantValue, target: :constituenttype, value: 'Organization'
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Constituents.org_with_contact_person'
            end

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__constituents,
                destination: :names__from_constituents_orgs_from_persons
              },
              transformer: xforms,
              helper: Kiba::Tms.name_compilation.multi_source_normalizer
            )
          end

          def from_constituents_persons_from_orgs
            xforms = Kiba.job_segment do
              @alphasorter = Tms::Services::Constituents::PersonNameAlphasortConstructor.new
              @displaynamer = Tms::Services::Constituents::PersonDisplaynameConstructor.new
              @fields = %i[constituenttype lastname firstname nametitle middlename suffix salutation nationality culturegroup]
              
              transform Delete::FieldsExcept, fields: @fields
              
              transform CombineValues::FromFieldsWithDelimiter, sources: @fields, target: :combined,
                sep: ' - ', delete_sources: false
              transform Deduplicate::Table, field: :combined, delete_field: true

              transform Tms::Transforms::Constituents::KeepOrgsWithPersonNameParts
              transform do |row|
                row[:alphasort] = @alphasorter.call(row)
                row
              end

              transform do |row|
                row[:displayname] = @displaynamer.call(row)
                row
              end
              
              transform Merge::ConstantValue, target: :constituenttype, value: 'Person'
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Constituents.orgs_with_person_names'
              transform Cspace::NormalizeForID, source: Tms.constituents.preferred_name_field, target: :norm
            end

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__constituents,
                destination: :names__from_constituents_persons_from_orgs
              },
              transformer: xforms,
              helper: Kiba::Tms.name_compilation.multi_source_normalizer
            )
          end


          def from_loans
            xforms = Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[approvedby contact requestedby]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[approvedby contact requestedby], target: :combined,
                sep: '|||', delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep, field: :combined
              transform Delete::FieldsExcept, fields: :combined
              transform Explode::RowsFromMultivalField, field: :combined, delim: '|||'
              transform Deduplicate::Table, field: :combined
              transform Cspace::NormalizeForID, source: :combined, target: :norm
              transform Rename::Field, from: :combined, to: Tms.constituents.preferred_name_field
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Loans'
            end
            
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__loans,
                destination: :names__from_loans
              },
              transformer: xforms,
              helper: Kiba::Tms.name_compilation.multi_source_normalizer
            )
          end

          def from_obj_accession
            xforms = Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[authorizer initiator]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[authorizer initiator], target: :combined,
                sep: '|||', delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep, field: :combined
              transform Delete::FieldsExcept, fields: :combined
              transform Explode::RowsFromMultivalField, field: :combined, delim: '|||'
              transform Deduplicate::Table, field: :combined
              transform Cspace::NormalizeForID, source: :combined, target: :norm
              transform Rename::Field, from: :combined, to: Tms.constituents.preferred_name_field
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Objaccession'
            end
            
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__obj_accession,
                destination: :names__from_obj_accession
              },
              transformer: xforms,
              helper: Kiba::Tms.name_compilation.multi_source_normalizer
            )
          end

          def from_obj_locations
            xforms = Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[approver handler requestedby]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[approver handler requestedby], target: :combined,
                sep: '|||', delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep, field: :combined
              transform Delete::FieldsExcept, fields: :combined
              transform Explode::RowsFromMultivalField, field: :combined, delim: '|||'
              transform Deduplicate::Table, field: :combined
              transform Cspace::NormalizeForID, source: :combined, target: :norm
              transform Rename::Field, from: :combined, to: Tms.constituents.preferred_name_field
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Obj_Locations'
            end

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__obj_locations,
                destination: :names__from_obj_locations
              },
              transformer: xforms,
              helper: Kiba::Tms.name_compilation.multi_source_normalizer
            )
          end

          def initial_compile
            xforms = Kiba.job_segment do
              @deduper = {}

              transform Fingerprint::Add,
                fields: Tms::Services::FingerprintFields.names,
                delim: '|||',
                target: :fingerprint,
                override_app_delim_check: true
              transform Deduplicate::Flag, on_field: :norm, in_field: :duplicate, using: @deduper,
                explicit_no: false
              transform Append::NilFields, fields: Tms.name_compilation.multi_source_normalizer.get_fields
              transform Append::NilFields, fields: %i[migration_action approx_normalized]
            end
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[names__from_constituents names__from_constituents_orgs_from_persons
                           names__from_constituents_persons_from_orgs names__from_loans
                           names__from_obj_accession names__from_obj_locations],
                destination: :names__initial_compile
              },
              transformer: xforms
            )
          end

          def flagged_duplicates
            xforms = Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep, field: :duplicate
              transform Deduplicate::Table, field: :norm, delete_field: false
              transform Delete::FieldsExcept, fields: :norm
              transform Merge::ConstantValue, target: :duplicate, value: 'y'
            end
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[names__initial_compile],
                destination: :names__flagged_duplicates
              },
              transformer: xforms
            )
          end

          def compiled
            xforms = Kiba.job_segment do
              transform Tms::Transforms::Constituents::CleanPersonNamePartsFromOrg
              transform Tms::Transforms::Constituents::CleanOrgNameInfoFromPerson
              transform Tms::Transforms::Constituents::FlagPersonNamesLackingNameDetails

              # This marks all rows with duplicate values as duplicates, not just subsequent rows
              transform Merge::MultiRowLookup,
                fieldmap: {normnew: :norm},
                lookup: names__flagged_duplicates,
                keycolumn: :norm,
                constantmap: {duplicate: 'y'}
              transform Delete::Fields, fields: %i[normnew constituentid]

              transform Rename::Field, from: Kiba::Tms.constituents.preferred_name_field, to: :preferred_name_form
              transform Rename::Field, from: Kiba::Tms.constituents.alt_name_field, to: :variant_name_form
              transform Rename::Field, from: :norm, to: :normalized_form
              
            end
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[names__initial_compile],
                destination: :names__compiled,
                lookup: :names__flagged_duplicates
              },
              transformer: xforms
            )
          end
        end
      end
    end
  end
end
