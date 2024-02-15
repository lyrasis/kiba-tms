# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module NameCompile
        module_function

        def register
          Kiba::Tms.registry.namespace("name_compile") do
            register :raw, {
              creator: Kiba::Tms::Jobs::NameCompile::Raw,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_raw.csv"
              ),
              desc: "Initial compiled terms from all sources\n"\
                "- Adds fingerprint field for main name deduplication merge",
              tags: %i[names],
              dest_special_opts: {
                initial_headers:
                %i[
                  contype name relation_type
                  variant_term variant_qualifier
                  related_term related_role
                  note_text
                  birth_foundation_date death_dissolution_date datenote
                  salutation nametitle firstname middlename lastname suffix
                ]
              },
              lookup_on: :norm
            }
            register :worksheet, {
              creator: Kiba::Tms::Jobs::NameCompile::Worksheet,
              path: File.join(
                Kiba::Tms.datadir,
                "to_client",
                "names_worksheet.csv"
              ),
              desc: "Compiles unique name compile split by relation type",
              tags: %i[names],
              dest_special_opts: {
                initial_headers: Tms::NameCompile.initial_headers
              }
            }
            {main: "_main term",
             note: "bio_note",
             contact: "contact_person",
             variant: "variant term"}.each do |reltype, typevalue|
              register "unique_split_#{reltype}".to_sym, {
                creator: {
                  callee: Kiba::Tms::Jobs::NameCompile::UniqueByReltype,
                  args: {reltype: reltype, value: typevalue}
                },
                path: File.join(Kiba::Tms.datadir, "working",
                  "names_compiled_uniq_split_#{reltype}.csv"),
                desc: "Rows from :name_compile__unique with `relation_type` "\
                  "value: #{typevalue}. Derives two fingerprint fields, one "\
                  "of editable field values, and one of non-editable field "\
                  "values. Fills in non-editable fields with "\
                  "#{Tms::NameCompile.na_in_migration_value}"
              }
            end
            if Tms::NameCompile.done
              Tms::NameCompile.provided_worksheet_jobs
                .each_with_index do |job, idx|
                  jobname = job.to_s
                    .delete_prefix("name_compile__")
                    .to_sym
                  register jobname, {
                    path: Tms::NameCompile.provided_worksheets[idx],
                    desc: "NameCompile cleanup worksheet provided to client",
                    tags: %i[names cleanup worksheetprovided],
                    supplied: true
                  }
                end
              register :previous_worksheet_compile, {
                creator:
                Kiba::Tms::Jobs::NameCompile::PreviousWorksheetCompile,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "names_compiled_previous_worksheet_compile.csv"
                ),
                tags: %i[names cleanup],
                desc: "- Joins completed supplied worksheets\n"\
                  "- Deduplicates on :authority + :name + "\
                  ":constituentid + :relation_type + :termsource",
                lookup_on: :cleanupid
              }
              Tms::NameCompile.returned_file_jobs
                .each_with_index do |job, idx|
                  jobname = job.to_s
                    .delete_prefix("name_compile__")
                    .to_sym
                  register jobname, {
                    path: Tms::NameCompile.returned_files[idx],
                    desc: "Completed name cleanup worksheet",
                    tags: %i[names cleanup],
                    supplied: true
                  }
                end
              register :returned_compile, {
                creator: Kiba::Tms::Jobs::NameCompile::ReturnedCompile,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "names_compiled_returned_compiled.csv"
                ),
                tags: %i[names cleanup],
                desc: "- Joins completed cleanup worksheets\n"\
                  "- If :cleanupid does not exist:\n"\
                  "-- Set :termsource to `clientcleanup`\n"\
                  "-- Set :constituentid to value of populated "\
                  ":variant_term, :related_term, or :note_text "\
                  "value\n"\
                  "-- Populate :cleanupid\n"\
                  "-- Populate :sort\n"\
                  "- Deduplicate on :cleanupid\n"\
                  "- Removes #{Tms::NameCompile.na_in_migration_value} "\
                  "values\n"\
                  "- Converts :authority field back to :contype",
                lookup_on: :cleanupid
              }
              {main: "_main term",
               note: "bio_note",
               contact: "contact_person",
               variant: "variant term"}.each do |reltype, typevalue|
                register "returned_split_#{reltype}".to_sym, {
                  creator: {
                    callee: Kiba::Tms::Jobs::NameCompile::ReturnedByReltype,
                    args: {reltype: reltype, value: typevalue}
                  },
                  path: File.join(Kiba::Tms.datadir, "working",
                    "names_compiled_returned_split_#{reltype}.csv"),
                  desc: "Rows from returned worksheet with `relation_type` "\
                    "value: #{typevalue}.\n"\
                    "- Reverts any edited non-editable field to original "\
                    "value\n"\
                    "- Adds :discarded_edit warning field (containing edited "\
                    "values replaced with original values"
                }
              end
              register :returned_checked, {
                creator: Kiba::Tms::Jobs::NameCompile::ReturnedChecked,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "names_compiled_returned_checked.csv"
                ),
                tags: %i[names cleanup],
                desc: "Recompiles returned rows after checking split files "\
                  "and reverting non-editable values. :discarded_edit column "\
                  "is present for reporting"
              }
              register :returned_to_merge, {
                creator: Kiba::Tms::Jobs::NameCompile::ReturnedToMerge,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "names_compiled_returned_to_merge.csv"
                ),
                tags: %i[names cleanup],
                desc: "Removes fingerprint field"
              }
            end
            register :main_duplicates, {
              creator: Kiba::Tms::Jobs::NameCompile::MainDuplicates,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_main_duplicates.csv"
              ),
              desc: "Only main terms from initial compiled terms flagged as "\
                "duplicates",
              tags: %i[names],
              lookup_on: :fingerprint
            }
            register :typed_main_duplicates, {
              creator: Kiba::Tms::Jobs::NameCompile::TypedMainDuplicates,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_typed_main_duplicates.csv"),
              desc: "Only typed (person/org) main terms from initial compiled "\
                "terms flagged as duplicates",
              tags: %i[names],
              lookup_on: :fingerprint
            }
            register :untyped_main_duplicates, {
              creator: Kiba::Tms::Jobs::NameCompile::UntypedMainDuplicates,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_untyped_main_duplicates.csv"),
              desc: "Only untyped main terms from initial compiled terms "\
                "flagged as duplicates",
              tags: %i[names],
              lookup_on: :fingerprint
            }
            register :variant_duplicates, {
              creator: Kiba::Tms::Jobs::NameCompile::VariantDuplicates,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_variant_duplicates.csv"),
              desc: "Only variant terms from initial compiled terms flagged "\
                "as duplicates",
              tags: %i[names],
              lookup_on: :fingerprint
            }
            register :related_duplicates, {
              creator: Kiba::Tms::Jobs::NameCompile::RelatedDuplicates,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_related_duplicates.csv"),
              desc: "Only related terms from initial compiled terms flagged "\
                "as duplicates",
              tags: %i[names],
              lookup_on: :fingerprint
            }
            register :note_duplicates, {
              creator: Kiba::Tms::Jobs::NameCompile::NoteDuplicates,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_note_duplicates.csv"),
              desc: "Only note terms from initial compiled terms flagged "\
                "as duplicates",
              tags: %i[names],
              lookup_on: :fingerprint
            }
            register :duplicates_flagged, {
              creator: Kiba::Tms::Jobs::NameCompile::DuplicatesFlagged,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_duplicates_flagged.csv"),
              desc: Kiba::Tms::Jobs::NameCompile::DuplicatesFlagged.send(:desc),
              tags: %i[names],
              dest_special_opts: {initial_headers: %i[sort]}
            }
            register :unique, {
              creator: Kiba::Tms::Jobs::NameCompile::Unique,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_unique.csv"),
              desc: Kiba::Tms::Jobs::NameCompile::Unique.send(:desc),
              tags: %i[names],
              dest_special_opts: {initial_headers: %i[sort]}
            }
            register :from_con_org_plain, {
              creator: Kiba::Tms::Jobs::NameCompile::FromConOrgPlain,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_con_org_plain.csv"),
              desc: "Org MAIN TERMS from Constituents",
              tags: %i[names con]
            }
            register :from_con_org_with_inst, {
              creator: Kiba::Tms::Jobs::NameCompile::FromConOrgWithInst,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_con_org_with_inst.csv"),
              desc: "From Constituents orgs with institution field",
              tags: %i[names con]
            }
            register :from_con_org_with_name_parts, {
              creator: Kiba::Tms::Jobs::NameCompile::FromConOrgWithNameParts,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_con_org_with_name_parts.csv"),
              desc: "From Constituents orgs with multipe core name detail "\
                "elements OR (a single core name detail element AND a "\
                "position value)",
              tags: %i[names con]
            }
            register :from_con_org_with_single_name_part_no_position, {
              creator: Kiba::Tms::Jobs::NameCompile::FromConOrgWithSingleNamePartNoPosition,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_con_org_with_single_name_part_no_position.csv"),
              desc: "From Constituents orgs with a single core name detail "\
                "element, and no position value",
              tags: %i[names con]
            }
            register :from_con_person_plain, {
              creator: Kiba::Tms::Jobs::NameCompile::FromConPersonPlain,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_con_person_plain.csv"),
              desc: "Person MAIN TERMS from Constituents",
              tags: %i[names con]
            }
            register :from_con_person_with_inst, {
              creator: Kiba::Tms::Jobs::NameCompile::FromConPersonWithInst,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_con_person_with_inst.csv"),
              desc: "From Constituents persons with institution value",
              tags: %i[names con]
            }
            register :from_con_person_with_position_no_inst, {
              creator: Kiba::Tms::Jobs::NameCompile::FromConPersonWithPositionNoInst,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_con_person_with_position_no_inst.csv"),
              desc: "From Constituents persons with position value but no institution value",
              tags: %i[names con]
            }
            register :from_can_typematch_alt_established, {
              creator: Kiba::Tms::Jobs::NameCompile::FromCanTypematchAltEstablished,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_can_typematch_alt_established.csv"),
              desc: "From ConAltNames where type is same for main and alt name, and alt name matches an established constituent name",
              tags: %i[names con_alt_names]
            }
            register :from_can_main_person_alt_org_established, {
              creator: Kiba::Tms::Jobs::NameCompile::FromCanMainPersonAltOrgEstablished,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_can_main_person_alt_org_established.csv"),
              desc: "From ConAltNames where main name is Person, and alt name matches an established organization name",
              tags: %i[names con_alt_names]
            }
            register :from_can_main_org_alt_person_established, {
              creator: Kiba::Tms::Jobs::NameCompile::FromCanMainOrgAltPersonEstablished,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_can_main_org_alt_person_established.csv"),
              desc: "From ConAltNames where main name is Organization, and alt name matches an established person name",
              tags: %i[names con_alt_names]
            }
            register :from_can_typematch, {
              creator: Kiba::Tms::Jobs::NameCompile::FromCanTypematch,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_can_typematch.csv"),
              desc: "Adds :treatment field to rows from ConAltNames where main and alt name types match AND altname is not established as separate constituent name",
              tags: %i[names con_alt_names]
            }
            register :from_can_typematch_variant, {
              creator: Kiba::Tms::Jobs::NameCompile::FromCanTypematchVariant,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_can_typematch_variant.csv"),
              desc: "name_compile__from_can_typematch variants",
              tags: %i[names con_alt_names]
            }
            register :from_can_typematch_separate, {
              creator: Kiba::Tms::Jobs::NameCompile::FromCanTypematchSeparate,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_can_typematch_separate.csv"),
              desc: "name_compile__from_can_typematch separates",
              tags: %i[names con_alt_names]
            }
            register :from_can_typematch_separate_names, {
              creator: Kiba::Tms::Jobs::NameCompile::FromCanTypematchSeparateNames,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_can_typematch_separate_names.csv"),
              desc: "output main name rows from alt names in name_compile__from_can_typematch separates",
              tags: %i[names con_alt_names]
            }
            register :from_can_typematch_separate_notes, {
              creator: Kiba::Tms::Jobs::NameCompile::FromCanTypematchSeparateNotes,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_can_typematch_separate_notes.csv"),
              desc: "output related name note rows from alt names in name_compile__from_can_typematch separates",
              tags: %i[names con_alt_names]
            }
            register :from_can_typemismatch_main_person, {
              creator: Kiba::Tms::Jobs::NameCompile::FromCanTypemismatchMainPerson,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_can_typemismatch_main_person.csv"),
              desc: "ConAltNames rows where altname is not established, alt name type is Organization, and main name type is Person",
              tags: %i[names con_alt_names]
            }
            register :from_can_typemismatch_main_org, {
              creator: Kiba::Tms::Jobs::NameCompile::FromCanTypemismatchMainOrg,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_can_typemismatch_main_org.csv"),
              desc: "ConAltNames rows where altname is not established, alt name type is Person, and main name type is Organization",
              tags: %i[names con_alt_names]
            }
            register :from_can_no_altnametype, {
              creator: Kiba::Tms::Jobs::NameCompile::FromCanNoAltnametype,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_can_no_altnametype.csv"),
              desc: "ConAltNames rows where altname is not established, alt name type is empty",
              tags: %i[names con_alt_names]
            }
            register :from_assoc_parents_for_con, {
              creator: Kiba::Tms::Jobs::NameCompile::FromAssocParentsForCon,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_assoc_parents_for_con.csv"),
              desc: "Names extracted from AssocParents (for constituents) table",
              tags: %i[names assoc_parents]
            }
            register :from_associations, {
              creator: Kiba::Tms::Jobs::NameCompile::FromAssociations,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_associations.csv"),
              desc: "Names extracted from Associations (for constituents) table",
              tags: %i[names associations]
            }
            register :from_reference_master, {
              creator: Kiba::Tms::Jobs::NameCompile::FromReferenceMaster,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_compiled_from_reference_master.csv"),
              desc: "Names extracted from reference_master table",
              tags: %i[names reference_master]
            }
            register :from_uncontrolled_name_tables, {
              creator: Kiba::Tms::Jobs::NameCompile::FromUncontrolledNameTables,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_from_uncontrolled_name_tables.csv"
              ),
              desc: "Names from uncontrolled fields in tables, compiled, "\
                'normalized, termsource changed to "Uncontrolled field '\
                "value. Normalized value is in :constituentid field",
              tags: %i[names],
              lookup_on: :constituentid
            }
            register :orgs, {
              creator: Kiba::Tms::Jobs::NameCompile::Orgs,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_orgs.csv"
              ),
              tags: %i[names],
              desc: "Main terms tagged as orgs from :name_compile__unique"
            }
            register :persons, {
              creator: Kiba::Tms::Jobs::NameCompile::Persons,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_persons.csv"
              ),
              tags: %i[names],
              desc: "Main terms tagged as persons from :name_compile__unique"
            }
            register :non_name_notes, {
              creator: Kiba::Tms::Jobs::NameCompile::NonNameNotes,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_non_name_notes.csv"
              ),
              tags: %i[names],
              desc: "Main terms tagged as notes from :name_compile__unique",
              lookup_on: :constituentid
            }
            register :non_name_notes_uncontrolled, {
              creator: Kiba::Tms::Jobs::NameCompile::NonNameNotesUncontrolled,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_non_name_notes_uncontrolled.csv"
              ),
              tags: %i[names],
              desc: "Main terms tagged as notes from :name_compile__unique "\
                "with termsource = uncontrolled"
            }
            register :bio_note, {
              creator: Kiba::Tms::Jobs::NameCompile::BioNote,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_bio_notes.csv"
              ),
              tags: %i[names],
              lookup_on: :namemergenorm
            }
            register :contact_person, {
              creator: Kiba::Tms::Jobs::NameCompile::ContactPerson,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_contact_persons.csv"
              ),
              tags: %i[names],
              lookup_on: :namemergenorm
            }
            register :variant_term, {
              creator: Kiba::Tms::Jobs::NameCompile::VariantTerm,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_variant_terms.csv"
              ),
              tags: %i[names],
              lookup_on: :namemergenorm
            }
            register :main_terms_for_norm_lookup, {
              creator:
              Kiba::Tms::Jobs::NameCompile::MainTermsForNormLookup,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_main_terms_for_norm_lookup.csv"
              ),
              tags: %i[names]
            }
            register :persons_uncontrolled_for_norm_lookup, {
              creator:
              Kiba::Tms::Jobs::NameCompile::PersonsUncontrolledForNormLookup,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_persons_uncontrolled_for_norm_lookup.csv"
              ),
              tags: %i[names]
            }
            register :orgs_uncontrolled_for_norm_lookup, {
              creator:
              Kiba::Tms::Jobs::NameCompile::OrgsUncontrolledForNormLookup,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_orgs_uncontrolled_for_norm_lookup.csv"
              ),
              tags: %i[names]
            }
            register :person_from_con_org_name_parts_for_norm_lookup, {
              creator:
              Kiba::Tms::Jobs::NameCompile::PersonFromConOrgNamePartsForNormLookup,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_compiled_persons_from_con_org_name_parts_for_norm_lookup.csv"
              ),
              tags: %i[names]
            }
            register :variants_from_duplicate_constituents, {
              creator:
              Kiba::Tms::Jobs::NameCompile::VariantsFromDuplicateConstituents,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_variants_from_duplicate_constituents.csv"),
              desc: "Variant names from duplicate (after normalization!) "\
                "constituent names that are not literally duplicates",
              tags: %i[names con]
            }
            if Tms::NameTypeCleanup.migration_added_names
              register :from_migration_added, {
                creator:
                Kiba::Tms::Jobs::NameCompile::FromMigrationAdded,
                path: File.join(Kiba::Tms.datadir, "working",
                  "names_compiled_from_migration_added.csv"),
                desc: "Names manually added to name type cleanup worksheet(s)",
                tags: %i[names]
              }
            end
          end
        end
      end
    end
  end
end
