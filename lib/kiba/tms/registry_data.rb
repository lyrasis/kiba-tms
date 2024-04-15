# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module_function

      def register
        register_supplied_files
        register_prep_files
        register_sample_files if Tms.migration_status == :dev
        Tms::NameCompile.register_uncontrolled_name_compile_jobs
        Tms::Utils::ForTableJobRegistrar.call
        Kiba::Extend::Utils::IterativeCleanupJobRegistrar.call
        register_files
      end

      def register_prep_files
        tables = Kiba::Tms::Table::List.call.map { |table|
          Kiba::Tms::Table::Obj.new(table)
        }
          .select(&:included)

        Kiba::Tms.registry.namespace("prep") do
          tables.each do |table|
            reghash = Tms::Table::Prep::RegistryHashCreator.call(table)
            next unless reghash

            register table.filekey, reghash
          end
        end
      end
      private_class_method :register_prep_files

      def register_supplied_files
        tables = Kiba::Tms::Table::List.call.map { |table|
          Kiba::Tms::Table::Obj.new(table)
        }
          .select(&:included)

        Kiba::Tms.registry.namespace("tms") do
          tables.each do |table|
            register table.filekey,
              Tms::Table::Supplied::RegistryHashCreator.call(table)
          end
        end
      end
      private_class_method :register_supplied_files

      def register_sample_files
        Kiba::Tms.registry.namespace("sample") do
          dirpath = File.join(Kiba::Tms.datadir, "sample")
          Dir.children(dirpath).select { |file|
            File.extname(file) == ".csv"
          }.each do |csvfile|
            base = csvfile.delete_suffix(".csv")
            key = base.to_sym
            modname = base.split("_").map(&:capitalize).join("")
            mod = Tms.const_get(modname)

            register key, {
              path: File.join(dirpath, csvfile),
              supplied: true,
              tags: [key, :sample],
              lookup_on: mod.cs_record_id_field
            }
          end
        end
      end
      private_class_method :register_sample_files

      def register_files
        Kiba::Tms.registry.namespace("report") do
          register :terms_in_mig, {
            creator: Kiba::Tms::Jobs::Terms::Reports.method(:in_mig),
            path: File.join(Kiba::Tms.datadir, "reports",
              "terms_in_migration.csv"),
            desc: "Unique terms in migration",
            tags: %i[termdata reports]
          }
        end

        Kiba::Tms.registry.namespace("alt_nums") do
          # Handled by MultiTableMergeable and config transforms.
          # Do `thor jobs tagged alt_nums to see all jobs`
          register :for_objects_dropping_data, {
            creator: Kiba::Tms::Jobs::AltNums::ForObjectsDroppingData,
            path: File.join(Kiba::Tms.datadir, "postmigcleanup",
              "alt_nums_for_objects_dropping_data.csv"),
            desc: "Rows with other number treatment that have data other "\
            "than the altnum value and type",
            tags: %i[alt_nums postmigcleanup],
            dest_special_opts: {
              initial_headers: %i[object_number other_number_value
                orig_alt_number_type]
            }
          }
        end

        Kiba::Tms.registry.namespace("associations") do
          register :in_migration, {
            creator: Kiba::Tms::Jobs::Associations::InMigration,
            path: File.join(Kiba::Tms.datadir, "working",
              "associations_in_migration.csv"),
            desc: "Drops omitted types",
            tags: %i[associations]
          }
          register :not_in_migration, {
            creator: Kiba::Tms::Jobs::Associations::NotInMigration,
            path: File.join(Kiba::Tms.datadir, "postmigcleanup",
              "associations_not_in_migration.csv"),
            desc: "Report of omitted types",
            tags: %i[associations postmigcleanup],
            dest_special_opts: {
              initial_headers: %i[tablename dropreason relationtype rel1 rel2
                val1 val2 type1 type2]
            }
          }
          register :unmigrated_field_values, {
            creator: Kiba::Tms::Jobs::Associations::UnmigratedFieldValues,
            path: File.join(Kiba::Tms.datadir, "postmigcleanup",
              "associations_unmigrated_field_values.csv"),
            desc: "Report of omitted types",
            tags: %i[associations postmigcleanup],
            dest_special_opts: {
              initial_headers: %i[tablename relationtype rel1 rel2
                val1 val2 type1 type2]
            }
          }
        end

        Kiba::Tms.registry.namespace("chronology_era") do
          register :lookup, {
            creator: Kiba::Tms::Jobs::ChronologyEra::Lookup,
            path: File.join(Kiba::Tms.datadir, "working",
              "chronology_era_lookup.csv"),
            tags: %i[chronology eras],
            lookup_on: :termused,
            desc: "Preferred term is in :use field"
          }
          register :ingest, {
            creator: Kiba::Tms::Jobs::ChronologyEra::Ingest,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "chronology_era.csv"),
            tags: %i[chronology eras ingest]
          }
        end

        Kiba::Tms.registry.namespace("chronology_event") do
          register :lookup, {
            creator: Kiba::Tms::Jobs::ChronologyEvent::Lookup,
            path: File.join(Kiba::Tms.datadir, "working",
              "chronology_event_lookup.csv"),
            tags: %i[chronology events],
            lookup_on: :termused,
            desc: "Preferred term is in :use field"
          }
          register :ingest, {
            creator: Kiba::Tms::Jobs::ChronologyEvent::Ingest,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "chronology_event.csv"),
            tags: %i[chronology events ingest]
          }
        end

        # "citations"
        Kiba::Tms::RegistryData::Citations.register

        Kiba::Tms.registry.namespace("classification_notations") do
          register :ids_used, {
            creator: Kiba::Tms::Jobs::ClassificationNotations::IdsUsed,
            path: File.join(Kiba::Tms.datadir, "reference",
              "classification_notation_ids_used.csv"),
            desc: "Extracts list of unique classification notation ids in "\
              "used TermMasterThes rows",
            lookup_on: :primarycnid,
            tags: %i[termdata terms reference]
          }
          register :used, {
            creator: Kiba::Tms::Jobs::ClassificationNotations::Used,
            path: File.join(Kiba::Tms.datadir, "reference",
              "classification_notation_ids_used.csv"),
            desc: "ClassificationNotation rows in used TermMasterThes rows",
            lookup_on: :classificationnotationid,
            tags: %i[termdata terms reference]
          }
        end

        Kiba::Tms.registry.namespace("collectionobjects") do
          register :for_ingest, {
            creator: Kiba::Tms::Jobs::Collectionobjects::ForIngest,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "objects.csv"),
            tags: %i[collectionobjects ingest],
            dest_special_opts: {
              initial_headers: %i[objectnumber publishto inventorystatus
                namedcollection title]
            }
          }
          register :hierarchy, {
            creator: Kiba::Tms::Jobs::Collectionobjects::Hierarchy,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "object_hierarchy.csv"),
            tags: %i[collectionobjects ingest hierarchy]
          }
          register :production_dates, {
            creator: Kiba::Tms::Jobs::Collectionobjects::ProductionDates,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "object_production_dates.csv"),
            tags: %i[collectionobjects ingest dates]
          }
          register :assoc_dates, {
            creator: Kiba::Tms::Jobs::Collectionobjects::AssocDates,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "object_assoc_dates.csv"),
            tags: %i[collectionobjects ingest dates]
          }
        end

        Kiba::Tms.registry.namespace("concept_associated") do
          register :lookup, {
            creator: Kiba::Tms::Jobs::ConceptAssociated::Lookup,
            path: File.join(Kiba::Tms.datadir, "working",
              "concept_associated_lookup.csv"),
            tags: %i[concepts associated],
            lookup_on: :termused,
            desc: "Preferred term is in :use field"
          }
          register :ingest, {
            creator: Kiba::Tms::Jobs::ConceptAssociated::Ingest,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "concept_associated.csv"),
            tags: %i[concepts associated ingest]
          }
        end

        if Tms::ConceptEthnographicCulture.used?
          Kiba::Tms.registry.namespace("concept_ethnographic_culture") do
            case Tms.cspace_profile
            when :fcart
              Tms::ConceptEthnographicCulture.compile_fields.each do |field|
                register "from_#{field}".to_sym, {
                  creator: {
                    callee:
                    Kiba::Tms::Jobs::ConceptEthnographicCulture::FromObjMergePrep,
                    args: {field: field}
                  },
                  path: File.join(Kiba::Tms.datadir, "working",
                    "concept_ethculture_from_#{field}.csv"),
                  tags: %i[concepts ethnographic_culture]
                }
              end
            end
            register :lookup, {
              creator: Kiba::Tms::Jobs::ConceptEthnographicCulture::Lookup,
              path: File.join(Kiba::Tms.datadir, "working",
                "concept_ethculture_lookup.csv"),
              tags: %i[concepts ethnographic_culture],
              lookup_on: :culture
            }
            register :ingest, {
              creator: Kiba::Tms::Jobs::ConceptEthnographicCulture::Ingest,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "concept_ethnographic_culture.csv"),
              tags: %i[concepts ethnographic_culture ingest]
            }
          end
        end

        Kiba::Tms.registry.namespace("concept_material") do
          register :from_papersupport, {
            creator: Kiba::Tms::Jobs::ConceptMaterial::FromPapersupport,
            path: File.join(Kiba::Tms.datadir, "working",
              "concept_material_from_papersupport.csv"),
            tags: %i[concepts material]
          }
          register :lookup, {
            creator: Kiba::Tms::Jobs::ConceptMaterial::Lookup,
            path: File.join(Kiba::Tms.datadir, "working",
              "concept_material_lookup.csv"),
            tags: %i[concepts material],
            lookup_on: :material
          }
          register :ingest, {
            creator: Kiba::Tms::Jobs::ConceptMaterial::Ingest,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "concept_material.csv"),
            tags: %i[concepts material ingest]
          }
        end

        Kiba::Tms.registry.namespace("concept_nomenclature") do
          register :from_objectname, {
            creator: Kiba::Tms::Jobs::ConceptNomenclature::FromObjectname,
            path: File.join(Kiba::Tms.datadir, "working",
              "concept_nomenclature_from_objectname.csv"),
            tags: %i[concepts nomenclature]
          }
          if Tms::ObjectNames.used? &&
              Tms::Objects.objectnamecontrolled_source_fields.include?(:on)
            register :from_object_names_table, {
              creator:
              Tms::Jobs::ConceptNomenclature::FromObjectNamesTable,
              path: File.join(Kiba::Tms.datadir, "working",
                "concept_nomenclature_from_objectnames_table.csv"),
              tags: %i[concepts nomenclature]
            }
          end
          register :lookup, {
            creator: Kiba::Tms::Jobs::ConceptNomenclature::Lookup,
            path: File.join(Kiba::Tms.datadir, "working",
              "concept_nomenclature_lookup.csv"),
            tags: %i[concepts nomenclature],
            lookup_on: :objectname
          }
          register :ingest, {
            creator: Kiba::Tms::Jobs::ConceptNomenclature::Ingest,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "concept_nomenclature.csv"),
            desc: "Extracts unique strings used as objectname",
            tags: %i[concepts nomenclature ingest]
          }
        end

        Kiba::Tms.registry.namespace("cond_line_items") do
          register :to_conservation, {
            creator: Kiba::Tms::Jobs::CondLineItems::ToConservation,
            path: File.join(Kiba::Tms.datadir, "working",
              "condlineitems_conservation.csv"),
            desc: "Limits to rows which, based on attribute type value, need"\
              "to be mapped to conservation treatment record, as well as "\
              "mentioned in condition check record",
            tags: %i[conditions conservation_treatments],
            lookup_on: :conditionid
          }
        end

        Kiba::Tms.registry.namespace("conservation_treatments") do
          register :from_cond_line_items, {
            creator: Kiba::Tms::Jobs::ConservationTreatments::FromCondLineItems,
            path: File.join(Kiba::Tms.datadir, "working",
              "conservation_from_condlineitems.csv"),
            desc: "Conservation treatment records derived from CondLineItems "\
              "rows",
            tags: %i[conservation_treatments]
          }
          register :all, {
            creator: Kiba::Tms::Jobs::ConservationTreatments::All,
            path: File.join(Kiba::Tms.datadir, "working",
              "conservation_all.csv"),
            desc: "Conservation treatment records from all sources. Finalizes "\
              ":conservationnumber",
            tags: %i[conservation_treatments]
          }
          register :nhrs_cond_line_items, {
            creator: Kiba::Tms::Jobs::ConservationTreatments::NhrsCondLineItems,
            path: File.join(Kiba::Tms.datadir, "working",
              "nhrs_conservation_from_condlineitems.csv"),
            desc: "Nonhierarchical relationships between conservation records "\
              "derived from CondLineItems and a) object or other record type; "\
              "and b) related Condition Check record",
            tags: %i[conservation_treatments conditions nhrs objects]
          }
          register :nhrs_all, {
            creator: Kiba::Tms::Jobs::ConservationTreatments::NhrsAll,
            path: File.join(Kiba::Tms.datadir, "working",
              "nhrs_conservation_all.csv"),
            desc: "Compiled and deduplicated nhrs for conservation records",
            tags: %i[conservation_treatments conditions nhrs objects]
          }
          register :cspace, {
            creator: Kiba::Tms::Jobs::ConservationTreatments::Cspace,
            path: File.join(Kiba::Tms.datadir, "working",
              "conservation_cspace.csv"),
            desc: ":conservation_treatment__all with non-CS fields removed ",
            tags: %i[conservation_treatments]
          }
        end

        Kiba::Tms.registry.namespace("conditions") do
          # NOTE: The handling here seems a bit over-convoluted, but the way TMS
          #   has Conditions table set up as a multi-table mergeable table
          #   implies that there may ever be Conditions associated with
          #   ObjComponent rows or other tables. The extra complexity here will
          #   make it simpler to handle that if/when it ever comes up in client
          #   data.
          register :shaped, {
            creator: Kiba::Tms::Jobs::Conditions::Shaped,
            path: File.join(Kiba::Tms.datadir, "working",
              "conditions_shaped.csv"),
            desc: "Reshapes to CS data model as closely as possible without "\
              "introducing source-record-type specifics",
            tags: %i[conditions]
          }
          register :objects, {
            creator: Kiba::Tms::Jobs::Conditions::Objects,
            path: File.join(Kiba::Tms.datadir, "working",
              "conditions_objects.csv"),
            desc: "Renames :objectnumber to :recordnumber",
            tags: %i[conditions objects]
          }
          register :nhr_objects, {
            creator: Kiba::Tms::Jobs::Conditions::NhrObjects,
            path: File.join(Kiba::Tms.datadir, "working",
              "nhr_conditions_objects.csv"),
            desc: "Creates Object<->Conditioncheck NHRs",
            tags: %i[conditions objects nhr]
          }
          register :nhrs, {
            creator: Kiba::Tms::Jobs::Conditions::Nhrs,
            path: File.join(Kiba::Tms.datadir, "working",
              "nhr_conditions_nhrs.csv"),
            desc: "All Conditioncheck NHRs",
            tags: %i[conditions objects nhr]
          }
          register :cspace, {
            creator: Kiba::Tms::Jobs::Conditions::Cspace,
            path: File.join(Kiba::Tms.datadir, "working",
              "conditions_for_cspace.csv"),
            desc: "Adds :conditioncheckrefnumber based on :recordnumber",
            tags: %i[conditions objects],
            lookup_on: :conditionid
          }
        end

        Kiba::Tms.registry.namespace("con_address") do
          register :shaped, {
            creator: Kiba::Tms::Jobs::ConAddress::Shaped,
            path: File.join(Kiba::Tms.datadir, "working",
              "con_address_shaped.csv"),
            desc: "Removes rows with no address data, merges in coded values, "\
              "shapes for CS, flags duplicate address data rows",
            tags: %i[con con_address]
          }
          register :countries_unmapped_before_clean, {
            creator: Kiba::Tms::Jobs::ConAddress::CountriesUnmappedBeforeClean,
            path: File.join(Kiba::Tms.datadir, "reports",
              "con_address_countries_clean_review.csv"),
            desc: "Addresses with country values that cannot be exactly or "\
              "cleanly mapped to CS countries vocabulary.",
            tags: %i[con con_address reports postmigcleanup]
          }
          register :to_merge, {
            creator: Kiba::Tms::Jobs::ConAddress::ToMerge,
            path: File.join(Kiba::Tms.datadir, "working",
              "con_address_to_merge.csv"),
            desc: "Removes rows with no address data, merges in coded values,"\
              "shapes for CS",
            tags: %i[con con_address],
            lookup_on: :constituentid
          }
          register :dropping, {
            creator: Kiba::Tms::Jobs::ConAddress::Dropping,
            path: File.join(Kiba::Tms.datadir, "reports",
              "con_address_dropping.csv"),
            desc: "Addresses dropped from migration because (1) they are for "\
              "constituents that are not migrating; (2) they are marked "\
              "inactive and the migration is set to omit inactive addresses; "\
              "or (3) there was no address data in the row. The :keeping "\
              "field will include an indication of reason for drop.",
            tags: %i[con con_address reports postmigcleanup]
          }
          register :duplicates, {
            creator: Kiba::Tms::Jobs::ConAddress::Duplicates,
            path: File.join(Kiba::Tms.datadir, "reports",
              "con_address_duplicates.csv"),
            desc: "Addresses dropped from migration because, once data was "\
              "processed/shaped, the address duplicated another address for "\
              "the same constituent. Remarks/notes for the address were NOT "\
              "included in deduplication process, so this report is given in "\
              "case any important info was dropped from those fields.",
            tags: %i[con con_address reports postmigcleanup]
          }
          register :add_counts, {
            creator: Kiba::Tms::Jobs::ConAddress::AddCounts,
            path: File.join(Kiba::Tms.datadir, "working",
              "constituents_with_address_counts.csv"),
            desc: "Merge in count of how many addresses for each constituent",
            tags: %i[con con_address],
            lookup_on: :constituentid
          }
          register :multi, {
            creator: Kiba::Tms::Jobs::ConAddress::Multi,
            path: File.join(Kiba::Tms.datadir, "reports",
              "constituents_with_multiple_address.csv"),
            tags: %i[con con_address reports],
            dest_special_opts: {
              initial_headers:
              %i[
                addresscount type termdisplayname rank address_notes
                addressplace1 addressplace2 city state zipcode addresscountry
              ]
            },
            desc: "Address data for names that will have more than one "\
              "address merged in the migration. Clients may want to review "\
              "and clean these up post migration."
          }
        end

        Kiba::Tms.registry.namespace("con_alt_names") do
          register :prep_clean, {
            creator: Kiba::Tms::Jobs::ConAltNames::PrepClean,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "con_alt_names_prepped_clean.csv"
            ),
            tags: %i[con prep],
            desc: "Merged cleanup into prepped ConAltNames, merges cleaned up "\
              "Constituent data into that, and re-preps using cleaned data"
          }
          register :by_constituent, {
            creator: Kiba::Tms::Jobs::ConAltNames::PrepClean,
            path: File.join(Kiba::Tms.datadir, "prepped", "con_alt_names.csv"),
            tags: %i[con prep],
            lookup_on: :constituentid,
            desc: "Removes rows where altname is the same as linked name in "\
              "constituents table. If preferred name field = alphasort, move "\
              "org names from displayname to alphasort."
          }
          register :remarks_dropped, {
            creator: Kiba::Tms::Jobs::ConAltNames::RemarksDropped,
            path: File.join(Kiba::Tms.datadir, "postmigcleanup",
              "con_alt_names_remarks_dropped.csv"),
            tags: %i[con postmigcleanup],
            desc: "Due to the CollectionSpace data model and the complexity "\
              "of the name processing in the migration, remarks made on "\
              "individual alternate names in TMS are dropped in the "\
              "migration. This report contains the remarks that were dropped, "\
              "in case you wish to deal with them manually, post-migration.",
            dest_special_opts: {
              initial_headers: %i[name name_type altname remarks]
            }
          }
        end

        Kiba::Tms.registry.namespace("con_dates") do
          register :compiled, {
            creator: Kiba::Tms::Jobs::ConDates::Compiled,
            path: File.join(Kiba::Tms.datadir, "working",
              "con_dates_compiled.csv"),
            tags: %i[con con_dates],
            desc: "Combines data from constituents__clean_dates and, if used, "\
              "prep__con_dates; Reduces to unique value per date type, as "\
              "much as possible",
            dest_special_opts: {
              initial_headers:
              %i[constituentid datasource datedescription date remarks]
            }

          }
          register :prep_compiled, {
            creator: Kiba::Tms::Jobs::ConDates::PrepCompiled,
            path: File.join(Kiba::Tms.datadir, "working",
              "con_dates_compiled_prep.csv"),
            tags: %i[con con_dates],
            desc: "Adds warnings to be pulled into review; creates "\
              ":datenotes; adds CS mappable fields",
            dest_special_opts: {
              initial_headers:
              %i[constituentid datasource warn datedescription date remarks
                birth_foundation_date death_dissolution_date datenote	]
            }
          }
          register :to_merge, {
            creator: Kiba::Tms::Jobs::ConDates::ToMerge,
            path: File.join(Kiba::Tms.datadir, "working",
              "con_dates_to_merge.csv"),
            tags: %i[con con_dates],
            desc: "Keeps only fields from :prep_compiled to be merged back "\
            "into Constituents.",
            lookup_on: :constituentid
          }
          register :for_review, {
            creator: Kiba::Tms::Jobs::ConDates::ForReview,
            path: File.join(Kiba::Tms.datadir, "reports",
              "con_dates_for_review.csv"),
            tags: %i[con con_dates reports cleanup],
            dest_special_opts: {
              initial_headers:
              %i[constituentname constituentid datasource warn datedescription
                date remarks birth_foundation_date death_dissolution_date
                datenote]
            }
          }
          register :postmig, {
            creator: Kiba::Tms::Jobs::ConDates::Postmig,
            path: File.join(Kiba::Tms.datadir, "reports",
              "con_dates_for_post_mig_handling.csv"),
            tags: %i[con con_dates reports postmigcleanup]
          }
        end

        Kiba::Tms.registry.namespace("con_email") do
          register :dropping, {
            creator: Kiba::Tms::Jobs::ConEMail::Dropping,
            path: File.join(Kiba::Tms.datadir, "reports",
              "con_email_dropping.csv"),
            tags: %i[con con_email prep postmigcleanup],
            desc: "Rows from TMS ConEMail table that are omitted from the "\
              "migration because the associated constituent is not migrating"
          }
          register :to_merge, {
            creator: Kiba::Tms::Jobs::ConEMail::ToMerge,
            path: File.join(Kiba::Tms.datadir, "working",
              "con_email_to_merge.csv"),
            tags: %i[con con_email],
            lookup_on: :constituentid
          }
        end

        Kiba::Tms.registry.namespace("con_geography") do
          register :for_authority, {
            creator: Kiba::Tms::Jobs::ConGeography::ForAuthority,
            path: File.join(Kiba::Tms.datadir, "working",
              "con_geography_for_authority.csv"),
            tags: %i[con con_geography places],
            lookup_on: :constituentid
          }
          register :authority_merge, {
            creator: Kiba::Tms::Jobs::ConGeography::AuthorityMerge,
            path: File.join(Kiba::Tms.datadir, "working",
              "con_geography_authority_merge.csv"),
            tags: %i[con con_geography places],
            lookup_on: :constituentid
          }
          register :for_non_authority, {
            creator: Kiba::Tms::Jobs::ConGeography::ForNonAuthority,
            path: File.join(Kiba::Tms.datadir, "working",
              "con_geography_for_non_authority.csv"),
            tags: %i[con con_geography],
            lookup_on: :constituentid
          }
        end

        Kiba::Tms.registry.namespace("con_phones") do
          register :dropping, {
            creator: Kiba::Tms::Jobs::ConPhones::Dropping,
            path: File.join(Kiba::Tms.datadir, "reports",
              "con_phones_dropping.csv"),
            tags: %i[con con_phones prep not_migrating reports]
          }
          register :to_merge, {
            creator: Kiba::Tms::Jobs::ConPhones::ToMerge,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "con_phones_to_merge.csv"
            ),
            tags: %i[con con_phones],
            lookup_on: :constituentid
          }
          register :for_orgs, {
            creator: Kiba::Tms::Jobs::ConPhones::ForOrgs,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "con_phones_for_orgs.csv"
            ),
            tags: %i[con con_phones],
            lookup_on: :constituentid
          }
        end

        Kiba::Tms.registry.namespace("con_refs") do
          register :create, {
            creator: Kiba::Tms::Jobs::ConRefs::Create,
            path: File.join(Kiba::Tms.datadir, "tms", "ConRefs.csv"),
            tags: %i[con_xrefs]
          }
          register :prep, {
            creator: Kiba::Tms::Jobs::ConRefs::Prep,
            path: File.join(Kiba::Tms.datadir, "working",
              "con_refs_prepped.csv"),
            tags: %i[con_xrefs]
          }
          register :type_mismatch, {
            creator: Kiba::Tms::Jobs::ConRefs::TypeMismatch,
            path: File.join(Kiba::Tms.datadir, "reports",
              "con_refs_type_mismatch.csv"),
            desc: "Role type values from role, con_xrefs, and con_xref_details do not match",
            tags: %i[con_xrefs]
          }
          register :type_match, {
            creator: Kiba::Tms::Jobs::ConRefs::TypeMatch,
            path: File.join(Kiba::Tms.datadir, "working",
              "con_refs_type_match.csv"),
            desc: "Role type values from role, con_xrefs, and con_xref_details do match; redundant fields removed",
            tags: %i[con_xrefs]
          }
        end

        Kiba::Tms.registry.namespace("constituents") do
          register :prep_clean, {
            creator: Kiba::Tms::Jobs::Constituents::PrepClean,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "constituents_prepped_clean.csv"
            ),
            tags: %i[con],
            lookup_on: :constituentid,
            desc: <<~TXT
              SOURCE: prep__constituents
              Moves orig :norm to :prefnormorig
              Moves orig :nonprefnorm to :nonprefnormorig
              Merges in constituent name type cleanup if cleanup is done
              Re-normalizes :contype
              Generates new :norm field
            TXT
          }
          register :early_lookup, {
            creator: Kiba::Tms::Jobs::Constituents::PrepClean,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "constituents_prepped_clean.csv"
            ),
            tags: %i[con],
            lookup_on: :normid,
            desc: "Alias to prep_clean, with different lookup_on"
          }
          register :merge_external_tables, {
            creator: Kiba::Tms::Jobs::Constituents::MergeExternalTables,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "constituents_merge_external_tables.csv"
            ),
            tags: %i[con]
          }
          register :by_norm, {
            creator: Kiba::Tms::Jobs::Constituents::ByNorm,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "constituents_by_norm.csv"
            ),
            desc: "Cleaned constituent name lookup by norm (cleaned) prefname"\
              "\nNOTE: This job's output is for use in name_compile "\
              "processing only. Do not use to lookup final, authorized name "\
              "formsname. Use :names__by_norm for that lookup.",
            tags: %i[con],
            lookup_on: :norm
          }
          register :by_norm_orig, {
            creator: Kiba::Tms::Jobs::Constituents::ByNormOrig,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "constituents_by_norm_orig.csv"
            ),
            desc: "Cleaned constituent name lookup by uncleaned norm "\
              "prefname"\
              "\nNOTE: This job's output is for use in name_compile "\
              "processing only. Do not use to lookup final, authorized name "\
              "formsname. Use :names__by_norm for that lookup.",
            tags: %i[con],
            lookup_on: :norm
          }
          register :by_nonpref_norm, {
            creator: Kiba::Tms::Jobs::Constituents::ByNonprefNorm,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "constituents_by_nonpref_norm.csv"
            ),
            desc: "Cleaned constituent name lookup by norm form of "\
              "nonpreferred name field"\
              "\nNOTE: This job's output is for use in name_compile "\
              "processing only. Do not use to lookup final, authorized name "\
              "formsname. Use :names__by_norm for that lookup.",
            tags: %i[con],
            lookup_on: :norm
          }
          register :by_all_norms, {
            creator: Kiba::Tms::Jobs::Constituents::ByAllNorms,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "constituents_by_all_norms.csv"
            ),
            desc: "Combined table for lookup of cleaned constituent "\
              "name by cleaned norm, orig norm, or nonpref norm."\
              "\nNOTE: This job's output is for use in name_compile "\
              "processing only. Do not use to lookup final, authorized name "\
              "formsname. Use :names__by_norm for that lookup.",
            tags: %i[con],
            lookup_on: :norm
          }
          register :clean_dates, {
            creator: Kiba::Tms::Jobs::Constituents::CleanDates,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "constituents_clean_dates.csv"
            ),
            desc: "Just begin/end dates extracted from displaydate, and "\
              "resulting :datenote values, for reconciliation with ConDates, "\
              "if using, or otherwise merging back into Constituents",
            tags: %i[con],
            lookup_on: :constituentid
          }
          register :for_compile, {
            creator: Kiba::Tms::Jobs::Constituents::ForCompile,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "constituents_for_compile.csv"
            ),
            desc: "Removes fields not needed for NameCompile; removes fields "\
              "with no name data",
            tags: %i[con],
            lookup_on: :combined
          }
          register :duplicates, {
            creator: Kiba::Tms::Jobs::Constituents::Duplicates,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "constituents_duplicates.csv"
            ),
            desc: "Duplicate constituent rows. Normalized preferred name "\
              "value is not unique within the target authority (person/org). "\
              "One authority term will be created in CS for each group of "\
              "names identified here, using the row with :dropping = n.\n"\
              "The preferred name will be merged into any field where any of "\
              "the :constituentid values in the group is "\
              "referenced in other records. However, name details, notes, "\
              "and any other values in rows with :dropping = y will not "\
              "migrate into the name's authority record.\n"\
              "*If client wants to disambiguate the preferred names "\
              "in any of these rows, so they are not treated as duplicates, "\
              "they must request a new name_type_cleanup worksheet.*\n"\
              "Client may opt to manually add name details or other values "\
              "from dropped rows to the appropriate CS name records after the "\
              "migration is complete.",
            tags: %i[con reports postmigcleanup],
            lookup_on: :combined,
            dest_special_opts: {
              initial_headers: %i[constituentid combined dropping]
            }
          }
          register :persons, {
            creator: Kiba::Tms::Jobs::Constituents::Persons,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "constituents_persons.csv"
            ),
            desc: "Orig (not cleaned up) constituent values mapped to "\
              ":constituenttype or :derivedcontype = Person",
            tags: %i[con],
            lookup_on: :constituentid
          }
          register :orgs, {
            creator: Kiba::Tms::Jobs::Constituents::Orgs,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "constituents_orgs.csv"
            ),
            desc: "Orig (not cleaned up) constituent values mapped to "\
              ":constituenttype or :derivedcontype = Organization",
            tags: %i[con],
            lookup_on: :constituentid
          }
          register :alt_name_mismatch, {
            creator: Kiba::Tms::Jobs::Constituents::AltNameMismatch,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "constituents_alt_name_mismatch.csv"
            ),
            desc: "Constituents where value looked up on defaultnameid (in "\
              "con_alt_names table) does not match value of preferred name "\
              "field in constituents table",
            tags: %i[con reports]
          }
          register :with_type, {
            creator: Kiba::Tms::Jobs::Constituents::WithType,
            path: File.join(Kiba::Tms.datadir, "reports",
              "constituents_with_type.csv"),
            desc: "Constituents with a constituent type entered",
            tags: %i[con reports]
          }
          register :without_type, {
            creator: Kiba::Tms::Jobs::Constituents::WithoutType,
            path: File.join(Kiba::Tms.datadir, "working",
              "constituents_without_type.csv"),
            desc: "Constituents without a constituent type entered",
            tags: %i[con]
          }
          register :with_name_data, {
            creator: Kiba::Tms::Jobs::Constituents::WithNameData,
            path: File.join(Kiba::Tms.datadir, "working",
              "constituents_with_name_data.csv"),
            desc: "Constituents with displayname or alphasort name",
            tags: %i[con]
          }
          register :without_name_data, {
            creator: Kiba::Tms::Jobs::Constituents::WithoutNameData,
            path: File.join(Kiba::Tms.datadir, "reports",
              "constituents_without_name_data.csv"),
            desc: "Constituents without displayname or alphasort name",
            tags: %i[con reports]
          }
          register :derived_type, {
            creator: Kiba::Tms::Jobs::Constituents::DerivedType,
            path: File.join(Kiba::Tms.datadir, "reports",
              "constituents_with_derived_type.csv"),
            desc: "Constituents with a derived type",
            tags: %i[con reports]
          }
          register :no_derived_type, {
            creator: Kiba::Tms::Jobs::Constituents::NoDerivedType,
            path: File.join(Kiba::Tms.datadir, "reports",
              "constituents_without_derived_type.csv"),
            desc: "Constituents without a derived type",
            tags: %i[con reports]
          }
        end

        Kiba::Tms.registry.namespace("dates_translated") do
          if Tms::DatesTranslated.used?
            Tms::DatesTranslated.lookup_sources
              .each_with_index do |src, idx|
              name = "source_orig_#{idx}"
              register name.to_sym, {
                path: src,
                supplied: true
              }
            end
            register :lookup, {
              creator: Kiba::Tms::Jobs::DatesTranslated::Lookup,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "dates_translated_lookup.csv"
              ),
              desc: "Compiles all lookup sources into single lookup file",
              tags: %i[dates],
              lookup_on: :orig
            }
          end
        end

        # "exhibitions" "exh_loan_xrefs" "exh_obj_loan_obj_xrefs"
        # "exh_obj_xrefs" "exh_venues_xrefs" "exh_ven_obj_xrefs"
        Kiba::Tms::RegistryData::Exhibitions.register

        # "loans" "loansin" "loan_obj_xrefs"
        Kiba::Tms::RegistryData::Loans.register

        Kiba::Tms.registry.namespace("loansout") do
          register :prep, {
            creator: Kiba::Tms::Jobs::Loansout::Prep,
            path: File.join(Kiba::Tms.datadir, "working", "loansout__prep.csv"),
            tags: %i[loans loansout]
          }
          register :dropped_names, {
            creator: Kiba::Tms::Jobs::Loansout::DroppedNames,
            path: File.join(Kiba::Tms.datadir, "postmigcleanup",
              "loansout_dropped_names.csv"),
            tags: %i[loans loansout postmigcleanup],
            desc: "Retains only rows having unmigrateable values in "\
              "borrowerscontactorg (name must be a person name) or "\
              "borrowerscontactdropped (field is single-valued). Also retains "\
              "borrowerpersonlocal values if there's a borrower org name, and "\
              "there is another name in borrowerscontact, so it cannot be put "\
              "there. These are retained as :borrowerdropped"
          }
          register :ingest, {
            creator: Kiba::Tms::Jobs::Loansout::Ingest,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "loansout.csv"),
            tags: %i[loans loansout ingest]
          }
          register :rel_obj, {
            creator: Kiba::Tms::Jobs::Loansout::RelObj,
            path: File.join(Kiba::Tms.datadir, "working",
              "loansout__rel_obj.csv"),
            tags: %i[loans loansout relations]
          }
        end

        # "locs" "locations"
        Kiba::Tms::RegistryData::Locations.register

        # Kiba::Tms.registry.namespace('locclean') do
        #   %i[local offsite organization].each do |loc_type|
        #     register loc_type, {
        #       path: File.join(
        #         Kiba::Tms.datadir,
        #         'working',
        #         "locations_#{loc_type}.csv"
        #       ),
        #       creator: {
        #         callee: Kiba::Tms::Jobs::LocsClean::Splitter,
        #         args: {type: loc_type}
        #       },
        #       tags: %i[locations],
        #       lookup_on: :location_name
        #     }
        #   end
        #   Kiba::Tms::Locations.authorities.each do |loc_type|
        #     register "#{loc_type}_hier".to_sym, {
        #       path: File.join(
        #         Kiba::Tms.datadir,
        #         'working',
        #         "locations_#{loc_type}_hier.csv"
        #       ),
        #       creator: {
        #         callee: Kiba::Tms::Jobs::LocsClean::HierarchyAdder,
        #         args: {type: loc_type}
        #       },
        #       tags: %i[locations],
        #     }
        #   end
        #   Kiba::Tms::Locations.authorities.each do |loc_type|
        #     register "#{loc_type}_cspace".to_sym, {
        #       path: File.join(
        #         Kiba::Tms.datadir,
        #         'working',
        #         "locations_#{loc_type}_cspace.csv"
        #       ),
        #       creator: {
        #         callee: Kiba::Tms::Jobs::LocsClean::Cspace,
        #         args: {type: loc_type}
        #       },
        #       tags: %i[locations cspace],
        #     }
        #   end
        #   Kiba::Tms::Locations.authorities.each do |loc_type|
        #     register "#{loc_type}_hier_cspace".to_sym, {
        #       path: File.join(
        #         Kiba::Tms.datadir,
        #         'cspace',
        #         "locations_#{loc_type}_hier.csv"
        #       ),
        #       creator: {
        #         callee: Kiba::Tms::Jobs::LocsClean::HierCspace,
        #         args: {type: loc_type}
        #       },
        #       tags: %i[locations cspace relations],
        #     }
        #   end
        #   register :unknown_types, {
        #     creator: Kiba::Tms::Jobs::LocsClean::UnknownTypes,
        #     path: File.join(
        #       Kiba::Tms.datadir,
        #       'reports',
        #       'locations_unknown_types.csv'
        #     ),
        #     desc: 'Cleaned locations with unrecognized authority type',
        #     tags: %i[locations reports todochk]
        #   }
        #   register :org_lookup, {
        #     creator: Kiba::Tms::Jobs::LocsClean::OrgLookup,
        #     path: File.join(
        #       Kiba::Tms.datadir,
        #       'working',
        #       'locations_org_lookup.csv'
        #     ),
        #     desc: 'Organization locations matched to existing organization '\
        #       'termdisplaynames',
        #     tags: %i[locations orgs]
        #   }
        #   register :new_orgs, {
        #     creator: Kiba::Tms::Jobs::LocsClean::NewOrgs,
        #     path: File.join(
        #       Kiba::Tms.datadir,
        #       'working',
        #       'locations_new_orgs.csv'
        #     ),
        #     desc: 'Organization locations that need to be added',
        #     tags: %i[locations orgs]
        #   }
        # end

        # Kiba::Tms.registry.namespace('locclean0') do
        #   register :prep, {
        #     creator: Kiba::Tms::Jobs::LocsClean0::Prep,
        #     path: File.join(
        #       Kiba::Tms.datadir,
        #       'working',
        #       'locations_cleaned_0.csv'
        #     ),
        #     desc: 'Initial cleaned location data with info-only fields removed',
        #     tags: %i[locations]
        #   }
        # end

        # "media" "media_files" "media_master" "media_xrefs"
        Kiba::Tms::RegistryData::Media.register

        # "name_compile"
        Kiba::Tms::RegistryData::NameCompile.register

        # "name_type_cleanup"
        Kiba::Tms::RegistryData::NameTypeCleanup.register

        # "names"
        Kiba::Tms::RegistryData::Names.register

        # "nhrs" "nonhierarchicalrelationships"
        Kiba::Tms::RegistryData::Nhrs.register

        # "accession_lot" "acq_num_acq" "acquisitions" "obj_accession"
        # "linked_lot_acq" "linked_set_acq" "lot_num_acq"
        # "one_to_one_acq" "registration_sets"
        Kiba::Tms::RegistryData::ObjAccession.register

        Kiba::Tms.registry.namespace("obj_components") do
          register :with_object_numbers, {
            desc: "Merges in the human-readable :objectnumber value for each "\
              'row; Flags "top objects", i.e. not separate components, i.e. '\
              ":objectnumber = :componentnumber; Adds :existingobject field, "\
              "which, if populated, means there is an object in Objects table "\
              'with the same ID as the component (this is expected for "top '\
              'objects" but not other rows.',
            creator: Kiba::Tms::Jobs::ObjComponents::WithObjectNumbers,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "obj_components_with_object_numbers.csv"
            ),
            tags: %i[obj_components reports cleanup],
            dest_special_opts: {
              initial_headers:
              %i[
                parentobjectnumber componentnumber is_top_object
                problemcomponent existingobject duplicate
                componentname parentname parenttitle
                physdesc parentdesc
                component_type objcompstatus active
                physdesc
              ]
            },
            lookup_on: :objectid
          }
          register :with_object_numbers_by_compid, {
            desc: "Same as :with_object_numbers, but lookup on :componentid",
            creator: Kiba::Tms::Jobs::ObjComponents::WithObjectNumbers,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "obj_components_with_object_numbers.csv"
            ),
            tags: %i[obj_components reports cleanup],
            dest_special_opts: {
              initial_headers:
              %i[
                parentobjectnumber componentnumber is_top_object
                problemcomponent existingobject duplicate
                componentname parentname parenttitle
                physdesc parentdesc
                component_type objcompstatus active
                physdesc
              ]
            },
            lookup_on: :componentid
          }
          register :actual_components, {
            creator: Kiba::Tms::Jobs::ObjComponents::ActualComponents,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_components_actual.csv"),
            tags: %i[obj_components],
            lookup_on: :componentid
          }
          register :problem_components, {
            creator: Kiba::Tms::Jobs::ObjComponents::ProblemComponents,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_components_problem.csv"),
            tags: %i[obj_components reports postmigcleanup],
            lookup_on: :componentid
          }
          register :problem_components_with_loc_merged, {
            creator:
            Kiba::Tms::Jobs::ObjComponents::ProblemComponentsWithLocMerged,
            path: File.join(Kiba::Tms.datadir, "postmigcleanup",
              "obj_components_problem.csv"),
            tags: %i[obj_components postmigcleanup]
          }
          register :problem_component_lmi, {
            creator: Kiba::Tms::Jobs::ObjComponents::ProblemComponentLmi,
            path: File.join(Kiba::Tms.datadir, "postmigcleanup",
              "obj_components_problem_lmi.csv"),
            tags: %i[obj_components reports postmigcleanup],
            dest_special_opts: {
              initial_headers: %i[parent_object objectnumber transdate
                location_purpose transport_status
                transport_type is_temp location]
            }
          }
          register :parent_objects, {
            creator: Kiba::Tms::Jobs::ObjComponents::ParentObjects,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_components_parent_objects.csv"),
            tags: %i[obj_components],
            lookup_on: :componentid
          }
          register :objects, {
            creator: Kiba::Tms::Jobs::ObjComponents::Objects,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_components_objects.csv"),
            tags: %i[obj_components objects],
            desc: "Converts rows from :actual_components to object records"
          }
          register :current_loc_lookup, {
            creator: Kiba::Tms::Jobs::ObjComponents::CurrentLocLookup,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_components_current_loc_lookup.csv"),
            tags: %i[obj_components obj_locations],
            desc: "Lookup via :fullfingerprint. Only field: :fullfingerprint. "\
              "Use to identify which clumped ObjLocations rows are for "\
              "current locations",
            lookup_on: :fullfingerprint
          }
          register :parent_title_mismatch, {
            creator: Kiba::Tms::Jobs::ObjComponents::ParentTitleMismatch,
            path: File.join(Kiba::Tms.datadir, "reports",
              "obj_components_parent_title_mismatch.csv"),
            tags: %i[obj_components reports postmigcleanup],
            desc: "Components that have a title, but where that title does "\
              "appear in the parent object's title or objectname fields"
          }
          register :parent_desc_mismatch, {
            creator: Kiba::Tms::Jobs::ObjComponents::ParentDescMismatch,
            path: File.join(Kiba::Tms.datadir, "reports",
              "obj_components_parent_desc_mismatch.csv"),
            tags: %i[obj_components reports postmigcleanup],
            desc: "Components that have a physdesc field value, and where "\
              "the parent object's record does not contain that description"
          }
        end

        Kiba::Tms.registry.namespace("obj_context") do
          register :dates, {
            creator: Kiba::Tms::Jobs::ObjContext::Dates,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_context_dates.csv"),
            tags: %i[obj_context dates objects],
            desc: "Only rows with values in fields categorized as date "\
              "fields, looked up by objectid",
            lookup_on: :objectid
          }
        end

        Kiba::Tms.registry.namespace("obj_dates") do
          # This job only runs if Tms.migration_status == :prelim
          register :inactive, {
            creator: Kiba::Tms::Jobs::ObjDates::Inactive,
            path: File.join(Kiba::Tms.datadir, "to_client",
              "obj_dates_inactive.csv"),
            tags: %i[obj_dates prelim reports],
            desc: "Supports decision of whether to include inactive rows in "\
              "the migration. Populates :check column on inactive rows where "\
              "Objects.dated does not equal ObjDates.datetext to focus review",
            dest_special_opts: {
              initial_headers: %i[objectnumber check active
                main_object_dated_value]
            }
          }
          register :uniq, {
            creator: Kiba::Tms::Jobs::ObjDates::Uniq,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_dates_uniq.csv"),
            tags: %i[obj_dates],
            desc: "Unique date values for Emendate processing"
          }
          register :merge_translated, {
            creator: Kiba::Tms::Jobs::ObjDates::MergeTranslated,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_dates_merge_translated.csv"),
            tags: %i[obj_dates],
            desc: "Merges in CollectionSpace structured date fields from "\
              "Emendate, and prepares for reshaping into potentially "\
              "multivalued rows for ingest",
            lookup_on: :objectid
          }
        end

        Kiba::Tms.registry.namespace("obj_deaccession") do
          register :shaped, {
            creator: Kiba::Tms::Jobs::ObjDeaccession::Shaped,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_deaccession_shaped.csv"),
            tags: %i[obj_deaccession],
            desc: "Renames fields and reshapes data into CS Object Exit",
            dest_special_opts: {
              initial_headers: %i[exitnumber disposalmethod]
            }
          }
          register :obj_rel, {
            creator: Kiba::Tms::Jobs::ObjDeaccession::ObjRel,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_deaccession_obj_rel.csv"),
            tags: %i[obj_deaccession objects nhr]
          }
          Tms::ObjDeaccession.valuation_source_fields.each do |src|
            register "valuation_#{src}".to_sym, {
              creator: {
                callee: Tms::Jobs::ObjDeaccession::ValuationCreator,
                args: {source: src}
              },
              path: File.join(
                Tms.datadir, "working", "vc_from_#{src}.csv"
              ),
              desc: "Valuation control procedures derived from "\
                "ObjDeaccession.#{src}",
              tags: %i[obj_deaccession valuation_control]
            }
          end
        end

        Kiba::Tms.registry.namespace("obj_geography") do
          register :mapping_review, {
            creator: Kiba::Tms::Jobs::ObjGeography::MappingReview,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_geography_mapping_review.csv"),
            tags: %i[obj_geography reports],
            desc: "Merges in object number, title, and description so these "\
              "can be reviewed to determine where to map each geocode type",
            dest_special_opts: {
              initial_headers: %i[objectnumber objecttitle objectdesc geocode
                orig_combined]
            },
            lookup_on: :orig_combined
          }
          register :for_authority, {
            creator: Kiba::Tms::Jobs::ObjGeography::ForAuthority,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_geography_for_authority.csv"),
            tags: %i[obj_geography],
            desc: "Removes rows with :geocode values that are not mapping to "\
              "CS place authority-controlled fields"
          }
          register :authority_merge, {
            creator: Kiba::Tms::Jobs::ObjGeography::AuthorityMerge,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_geography_authority_merge.csv"),
            tags: %i[obj_geography]
          }
        end

        Kiba::Tms.registry.namespace("obj_incoming") do
          register :for_initial_review, {
            creator: Kiba::Tms::Jobs::ObjIncoming::ForInitialReview,
            path: File.join(Kiba::Tms.datadir, "reports",
              "obj_incoming_initial_review.csv"),
            tags: %i[obj_incoming reports],
            desc: "Merges object number from object table into prepped obj_incoming table",
            dest_special_opts: {
              initial_headers: %i[objincomingid objectnumber]
            }
          }
        end

        # "obj_locations" "movement" "lmi"
        Kiba::Tms::RegistryData::ObjLocations.register

        Kiba::Tms.registry.namespace("obj_rights") do
          register :external_data_merged, {
            creator: Kiba::Tms::Jobs::ObjRights::ExternalDataMerged,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_rights_external_data_merged.csv"),
            tags: %i[obj_rights]
          }
          register :shape, {
            creator: Kiba::Tms::Jobs::ObjRights::Shape,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_rights_shape.csv"),
            tags: %i[obj_rights],
            lookup_on: :objectid
          }
        end

        Kiba::Tms.registry.namespace("obj_titles") do
          register :note_review, {
            creator: Kiba::Tms::Jobs::ObjTitles::NoteReview,
            path: File.join(Kiba::Tms.datadir, "reports",
              "obj_titles_note_review.csv"),
            desc: "Object title notes for client review/cleanup",
            tags: %i[obj_titles objects postmigcleanup]
          }
        end

        Kiba::Tms.registry.namespace("objecthierarchy") do
          register :from_obj_components, {
            creator: Kiba::Tms::Jobs::Objecthierarchy::FromObjComponents,
            path: File.join(Kiba::Tms.datadir, "working",
              "objecthierarchy_from_obj_components.csv"),
            tags: %i[objecthierarchy obj_components]
          }
        end

        Kiba::Tms.registry.namespace("objects") do
          register :external_data_merged, {
            creator: Kiba::Tms::Jobs::Objects::ExternalDataMerged,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "objects_external_data_merged.csv"
            ),
            tags: %i[objects],
            desc: "Merges in data from external tables (where objects table "\
              "does not contain external table id) such as AltNums and "\
              "ConRefs"
          }
          register :merged_data_prep, {
            creator: Kiba::Tms::Jobs::Objects::MergedDataPrep,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "objects_merged_data_prep.csv"
            ),
            tags: %i[objects],
            desc: "Applies cleaners and shapers to external data merged in, "\
              "which need to be made consistent with other fields for the "\
              "subsequent :objects__shape job"
          }
          register :shape, {
            creator: Kiba::Tms::Jobs::Objects::Shape,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "objects_shape.csv"
            ),
            tags: %i[objects]
          }
          register :authorities_merged, {
            creator: Kiba::Tms::Jobs::Objects::AuthoritiesMerged,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "objects_authorities_merged.csv"
            ),
            tags: %i[objects]
          }
          register :date_prep, {
            creator: Kiba::Tms::Jobs::Objects::DatePrep,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "objects_date_prep.csv"
            ),
            lookup_on: :objectid,
            tags: %i[objects dates],
            desc: "Handle initial processing and cleanup of date fields from "\
              "TMS Objects table. The affected date fields are removed from "\
              "the main objects processing by Objects::Prep"
          }
          register :dated_uniq, {
            creator: Kiba::Tms::Jobs::Objects::DatedUniq,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "objects_dated_uniq.csv"
            ),
            tags: %i[objects dates],
            desc: "Unique values of :dated field, for Emendate processing"
          }
          register :numbers_cleaned, {
            creator: Kiba::Tms::Jobs::Objects::NumbersCleaned,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "objects_numbers_cleaned.csv"
            ),
            lookup_on: :objectid,
            tags: %i[objects]
          }
          register :by_number, {
            creator: Kiba::Tms::Jobs::Objects::ByNumber,
            path: File.join(Kiba::Tms.datadir, "working",
              "objects_by_number.csv"),
            desc: "Original TMS Objects table rows, lookedup by :objectnumber",
            lookup_on: :objectnumber,
            tags: %i[objects]
          }
          register :number_lookup, {
            path: File.join(
              Kiba::Tms.datadir,
              "prepped",
              "object_number_lookup.csv"
            ),
            creator: Kiba::Tms::Jobs::Objects::NumberLookup,
            desc: "Just id and objectnumber, retrievable by id",
            lookup_on: :objectid,
            tags: %i[objects]
          }
          register :loan_in_creditlines, {
            creator: Kiba::Tms::Jobs::Objects::LoanInCreditlines,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "loan_in_creditlines.csv"
            ),
            tags: %i[objects loansin],
            desc: ":creditline values for objects linked to loansin",
            lookup_on: :objectid
          }
          register :classification_report, {
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "obj_title_name_class.csv"
            ),
            creator: Kiba::Tms::Jobs::Objects::ClassificationReport,
            desc: "Object number, title, objectname, and classification "\
              "values for client review/decision making",
            tags: %i[objects]
          }
        end

        Kiba::Tms.registry.namespace("orgs") do
          register :flagged, {
            creator: Kiba::Tms::Jobs::Orgs::Flagged,
            path: File.join(Kiba::Tms.datadir, "working",
              "orgs_flagged.csv"),
            tags: %i[orgs],
            desc: "Flags duplicates (on normalized final name value)."
          }
          # Ensures the final termdisplayname form is associated with each
          #   constituentid. Fields: constituentid, norm, name
          register :by_constituentid, {
            creator: Kiba::Tms::Jobs::Orgs::ByConstituentId,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "orgs_by_constituent_id.csv"
            ),
            desc: "Org authority values lookup by constituentid",
            lookup_on: :constituentid,
            tags: %i[orgs]
          }
          register :by_norm, {
            creator: Kiba::Tms::Jobs::Orgs::ByNorm,
            path: File.join(Kiba::Tms.datadir, "working", "orgs_by_norm.csv"),
            desc: "Org authority values (:name) lookup by normalized value",
            lookup_on: :norm,
            tags: %i[orgs]
          }
          register :by_norm_word, {
            creator: Kiba::Tms::Jobs::Orgs::ByNormWord,
            path: File.join(Kiba::Tms.datadir, "working",
              "orgs_by_norm_word.csv"),
            desc: "For scoring uncategorized terms for term categorization",
            lookup_on: :normword,
            tags: %i[orgs]
          }
          register :cspace, {
            creator: Kiba::Tms::Jobs::Orgs::Cspace,
            path: File.join(Kiba::Tms.datadir, "working",
              "orgs_for_cspace.csv"),
            tags: %i[orgs cspace],
            dest_special_opts: {initial_headers: %i[termdisplayname]}
          }
          register :for_ingest, {
            creator: Kiba::Tms::Jobs::Orgs::ForIngest,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "organizations.csv"),
            tags: %i[orgs ingest]
          }
          register :brief, {
            creator: Kiba::Tms::Jobs::Orgs::Brief,
            path: File.join(Kiba::Tms.datadir, "working", "orgs_brief.csv"),
            tags: %i[orgs cspace],
            desc: "Only termdisplayname values, for bootstrap ingests, and "\
              "looking up final controlled name values by normalized form",
            lookup_on: :norm
          }
        end

        Kiba::Tms.registry.namespace("group") do
          register :ingest, {
            creator: Kiba::Tms::Jobs::Group::Ingest,
            path: File.join(Kiba::Tms.datadir, "ingest", "group.csv"),
            tags: %i[packages group]
          }
          register :nhr_objects, {
            creator: Kiba::Tms::Jobs::Group::NhrObjects,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "nhr_group_object.csv"),
            tags: %i[packages group collectionobjects nhr]
          }
        end

        Kiba::Tms.registry.namespace("packages") do
          register :flag_omitting, {
            creator: Kiba::Tms::Jobs::Packages::FlagOmitting,
            path: File.join(Kiba::Tms.datadir, "working",
              "packages_flag_omitting.csv"),
            tags: %i[packages],
            desc: "Flags packages that are omitted from the migration with "\
              "no option for inclusion. Reason for omission is in :omit"
          }
          register :omitted, {
            creator: Kiba::Tms::Jobs::Packages::Omitted,
            path: File.join(Kiba::Tms.datadir, "working",
              "packages_omitted.csv"),
            tags: %i[packages],
            desc: "Omitted packages lookup. :omit and :packageid only",
            lookup_on: :packageid
          }
          register :flag_migrating, {
            creator: Kiba::Tms::Jobs::Packages::FlagMigrating,
            path: File.join(Kiba::Tms.datadir, "working",
              "packages_flag_migrating.csv"),
            tags: %i[packages],
            desc: "Flag omitted packages not migrating. Flags (in :migrating) "\
              "remaining packages that are to be migrated (y) and those that "\
              "need client decision (blank)"
          }
          register :client_decision_worksheet, {
            creator: Kiba::Tms::Jobs::Packages::ClientDecisionWorksheet,
            path: File.join(Kiba::Tms.datadir, "to_client",
              "packages_decision_worksheet.csv"),
            tags: %i[packages],
            desc: "Removes :packagetype, :tablename, :folderid, :folderdesc "\
              "fields from :packages__flag_migrating",
            dest_special_opts: {
              initial_headers: %i[
                migrating omit name notes owner
              ]
            }
          }
          register :migrating, {
            creator: Kiba::Tms::Jobs::Packages::Migrating,
            path: File.join(Kiba::Tms.datadir, "working",
              "packages_migrating.csv"),
            tags: %i[packages],
            desc: "Removes :omitting. If client decisions are done, merges "\
              "those in. If not, blank are dropped",
            lookup_on: :packageid
          }
          register :shaped, {
            creator: Kiba::Tms::Jobs::Packages::Shaped,
            path: File.join(Kiba::Tms.datadir, "working",
              "packages_shaped.csv"),
            tags: %i[packages],
            desc: "Prepares for CS, but retains additional fields needed "\
            "for linkage",
            lookup_on: :packageid
          }
          if Tms::Packages.selection_done
            Tms::Packages.provided_worksheet_jobs
              .each_with_index do |job, idx|
                jobname = job.to_s
                  .delete_prefix("packages__")
                  .to_sym
                register jobname, {
                  path: Tms::Packages.provided_worksheets[idx],
                  desc: "Package decision worksheet provided to client",
                  tags: %i[packages cleanup],
                  supplied: true
                }
              end
            register :previous_worksheet_compile, {
              creator:
              Kiba::Tms::Jobs::Packages::PreviousWorksheetCompile,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "packages_previous_worksheet_compile.csv"
              ),
              tags: %i[packages cleanup],
              desc: "Joins completed supplied worksheets and deduplicates on "\
                ":packageid",
              lookup_on: :packageid
            }
            Tms::Packages.returned_file_jobs
              .each_with_index do |job, idx|
                jobname = job.to_s
                  .delete_prefix("packages__")
                  .to_sym
                register jobname, {
                  path: Tms::Packages.returned_files[idx],
                  desc: "Completed package decision worksheet",
                  tags: %i[packages cleanup],
                  supplied: true
                }
              end
            register :returned_compile, {
              creator: Kiba::Tms::Jobs::Packages::ReturnedCompile,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "packages_returned_compile.csv"
              ),
              tags: %i[packages cleanup],
              desc: "Joins completed decision worksheets and deduplicates on "\
                ":packageid",
              lookup_on: :packageid
            }
          end
        end

        Kiba::Tms.registry.namespace("persons") do
          register :flagged, {
            creator: Kiba::Tms::Jobs::Persons::Flagged,
            path: File.join(Kiba::Tms.datadir, "working",
              "persons_flagged.csv"),
            tags: %i[persons],
            desc: "Flags duplicates (on normalized final name value)."
          }
          register :duplicates_not_migrated, {
            creator: Kiba::Tms::Jobs::Persons::DuplicatesNotMigrated,
            path: File.join(Kiba::Tms.datadir, "reports",
              "persons_duplicates_not_migrating.csv"),
            tags: %i[persons],
            dest_special_opts: {
              initial_headers: %i[
                drop_from_mig termdisplayname namemergenorm
              ]
            },
            desc: "Report of all duplicate persons. The :drop_from_mig "\
              "column indicates which one was kept (y) and which ones "\
              "were not migrated. Client may opt to disambiguate names "\
              "in TMS, fix inadvertently merged names in name type "\
              "cleanup worksheet, or use this report to do post-migration "\
              "cleanup.\n\nNote that if there were 2 constituents (ids "\
              '23 and 57) with name "John Doe", the migrated name "John '\
              'Doe" will be assigned to populate all references to ids '\
              "23 and 57 in migrated objects and other records. If "\
              "different constituent ids with the same name string have "\
              "been used in many records, disambiguating the names "\
              "post-migration may take a lot of work"
          }
          # Ensures the final termdisplayname form is associated with each
          #   constituentid. Fields: constituentid, norm, name
          register :by_constituentid, {
            creator: Kiba::Tms::Jobs::Persons::ByConstituentId,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "persons_by_constituent_id.csv"
            ),
            desc: "Person authority values lookup by constituentid",
            lookup_on: :constituentid,
            tags: %i[persons]
          }
          register :by_norm, {
            creator: Kiba::Tms::Jobs::Persons::ByNorm,
            path: File.join(Kiba::Tms.datadir, "working",
              "persons_by_norm.csv"),
            desc: "Person authority values (:name) lookup by normalized value",
            lookup_on: :norm,
            tags: %i[persons]
          }
          register :by_norm_word, {
            creator: Kiba::Tms::Jobs::Persons::ByNormWord,
            path: File.join(Kiba::Tms.datadir, "working",
              "persons_by_norm_word.csv"),
            desc: "For scoring uncategorized terms into term type",
            lookup_on: :normword,
            tags: %i[persons]
          }
          register :cspace, {
            creator: Kiba::Tms::Jobs::Persons::Cspace,
            path: File.join(Kiba::Tms.datadir, "working",
              "persons_for_cspace.csv"),
            tags: %i[persons cspace],
            dest_special_opts: {initial_headers: %i[termdisplayname]}
          }
          register :for_ingest, {
            creator: Kiba::Tms::Jobs::Persons::ForIngest,
            path: File.join(Kiba::Tms.datadir, "ingest",
              "persons.csv"),
            tags: %i[persons ingest]
          }
          register :brief, {
            creator: Kiba::Tms::Jobs::Persons::Brief,
            path: File.join(Kiba::Tms.datadir, "working", "persons_brief.csv"),
            tags: %i[persons cspace],
            desc: "Only termdisplayname values, for bootstrap ingests, and "\
              "looking up final controlled name values by normalized form",
            lookup_on: :norm
          }
        end

        Kiba::Tms.registry.namespace("places") do
          register :compile, {
            creator: Kiba::Tms::Jobs::Places::Compile,
            path: File.join(Kiba::Tms.datadir, "working",
              "places_compile.csv"),
            tags: %i[places],
            lookup_on: :orig_combined
          }
          register :unique, {
            creator: Kiba::Tms::Jobs::Places::Unique,
            path: File.join(Kiba::Tms.datadir, "working",
              "places_unique.csv"),
            tags: %i[places]
          }
          register :notes_extracted, {
            creator: Kiba::Tms::Jobs::Places::NotesExtracted,
            path: File.join(Kiba::Tms.datadir, "working",
              "places_notes_extracted.csv"),
            tags: %i[places],
            lookup_on: :orig_combined
          }
          register :orig_normalized, {
            creator: Kiba::Tms::Jobs::Places::OrigNormalized,
            path: File.join(Kiba::Tms.datadir, "working",
              "places_orig_normalized.csv"),
            tags: %i[places],
            lookup_on: :norm_combined
          }
          register :norm_unique, {
            creator: Kiba::Tms::Jobs::Places::NormUnique,
            path: File.join(Kiba::Tms.datadir, "working",
              "places_norm_unique.csv"),
            tags: %i[places]
          }
          register :cleaned_exploded, {
            creator: Kiba::Tms::Jobs::Places::CleanedExploded,
            path: File.join(Kiba::Tms.datadir, "working",
              "places_cleaned_exploded.csv"),
            tags: %i[places],
            dest_special_opts: {
              initial_headers: %i[value fieldname norm_combineds fieldkey]
            },
            lookup_on: :fieldkey
          }
          register :cleaned_exploded_report_prep, {
            creator: Kiba::Tms::Jobs::Places::CleanedExplodedReportPrep,
            path: File.join(Kiba::Tms.datadir, "working",
              "places_cleaned_exploded_report_prep.csv"),
            tags: %i[places]
          }
          register :cleaned_exploded_report, {
            creator: Kiba::Tms::Jobs::Places::CleanedExplodedReport,
            path: File.join(Kiba::Tms.datadir, "reports",
              "places_cleaned_exploded_report.csv"),
            tags: %i[places reports],
            dest_special_opts: {
              initial_headers: %i[key value fieldname field_cat left_cat
                left_combined clean_combined occs
                objectnumbers objecttitles objectdescriptions]
            }
          }
          register :norm_unique_cleaned, {
            creator: Kiba::Tms::Jobs::Places::NormUniqueCleaned,
            path: File.join(Kiba::Tms.datadir, "working",
              "places_norm_unique_cleaned.csv"),
            tags: %i[places],
            lookup_on: :clean_combined
          }
          register :cleaned_unique, {
            creator: Kiba::Tms::Jobs::Places::CleanedUnique,
            path: File.join(Kiba::Tms.datadir, "working",
              "places_cleaned_unique.csv"),
            tags: %i[places],
            lookup_on: :clean_combined
          }
          register :cleaned_notes, {
            creator: Kiba::Tms::Jobs::Places::CleanedNotes,
            path: File.join(Kiba::Tms.datadir, "working",
              "places_cleaned_notes.csv"),
            tags: %i[places],
            lookup_on: :norm_combined
          }
          register :worksheet, {
            creator: Kiba::Tms::Jobs::Places::Worksheet,
            path: File.join(Kiba::Tms.datadir, "to_client",
              "place_cleanup_worksheet.csv"),
            tags: %i[places cleanup],
            dest_special_opts: {
              initial_headers: proc { Tms::Places.worksheet_columns }
            }
          }
          register :build_hierarchical, {
            creator: Kiba::Tms::Jobs::Places::BuildHierarchical,
            path: File.join(Kiba::Tms.datadir, "working",
              "place_build_hierarchical.csv"),
            tags: %i[places],
            lookup_on: :norm
          }
          register :uniq_hierarchical, {
            creator: Kiba::Tms::Jobs::Places::UniqHierarchical,
            path: File.join(Kiba::Tms.datadir, "working",
              "place_uniq_hierarchical.csv"),
            tags: %i[places]
          }
          register :build_nonhier, {
            creator: Kiba::Tms::Jobs::Places::BuildNonhier,
            path: File.join(Kiba::Tms.datadir, "working",
              "place_build_nonhier.csv"),
            tags: %i[places],
            lookup_on: :norm
          }
          register :uniq_nonhier, {
            creator: Kiba::Tms::Jobs::Places::UniqNonhier,
            path: File.join(Kiba::Tms.datadir, "working",
              "place_uniq_nonhier.csv"),
            tags: %i[places]
          }
          register :init_cleaned_lookup, {
            creator: Kiba::Tms::Jobs::Places::InitCleanedLookup,
            path: File.join(Kiba::Tms.datadir, "working",
              "place_init_cleaned_lookup.csv"),
            tags: %i[places],
            lookup_on: :norm_combined
          }
          register :init_cleaned_terms, {
            creator: Kiba::Tms::Jobs::Places::InitCleanedTerms,
            path: File.join(Kiba::Tms.datadir, "working",
              "place_init_cleaned_terms.csv"),
            tags: %i[places reports],
            lookup_on: :norm
          }
          register :final_cleanup_worksheet, {
            creator: Kiba::Tms::Jobs::Places::FinalCleanupWorksheet,
            path: File.join(Kiba::Tms.datadir, "to_client",
              "place_final_cleanup_worksheet.csv"),
            tags: %i[places cleanup],
            dest_special_opts: {
              initial_headers: %i[place add_variant normalized_variants]
            }
          }
          if Tms::Places.cleanup_done
            Tms::Places.worksheet_jobs
              .each_with_index do |job, idx|
                jobname = job.to_s
                  .delete_prefix("places__")
                  .to_sym
                register jobname, {
                  path: Tms::Places.worksheets[idx],
                  desc: "Place cleanup worksheet provided to client",
                  tags: %i[places cleanup],
                  supplied: true
                }
              end
            Tms::Places.returned_jobs
              .each_with_index do |job, idx|
              jobname = job.to_s
                .delete_prefix("places__")
                .to_sym
              register jobname, {
                path: Tms::Places.returned[idx],
                desc: "Completed cleanup worksheet",
                tags: %i[places cleanup],
                supplied: true
              }
            end
            register :returned_compile, {
              creator:
              Kiba::Tms::Jobs::Places::ReturnedCompile,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "places_returned_compile.csv"
              ),
              tags: %i[places cleanup],
              lookup_on: :clean_combined
            }
            register :corrections, {
              creator: Kiba::Tms::Jobs::Places::Corrections,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "places_corrections.csv"
              ),
              tags: %i[places cleanup],
              lookup_on: :norm_fingerprint
            }
          end

          if Tms::Places.final_cleanup_done
            Tms::Places.final_returned_jobs
              .each_with_index do |job, idx|
                jobname = job.to_s
                  .delete_prefix("places__")
                  .to_sym
                register jobname, {
                  path: Tms::Places.final_returned[idx],
                  desc: "Completed final cleanup worksheet",
                  tags: %i[places cleanup],
                  supplied: true
                }
              end
            register :final_returned_compile, {
              creator:
              Kiba::Tms::Jobs::Places::FinalReturnedCompile,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "places_final_returned_compile.csv"
              ),
              tags: %i[places cleanup],
              lookup_on: :clean_combined
            }
            register :final_cleanup_corrections, {
              creator: Kiba::Tms::Jobs::Places::FinalCleanupCorrections,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "places_final_cleanup_corrections.csv"
              ),
              tags: %i[places cleanup],
              lookup_on: :fingerprint
            }
            register :final_cleanup_cleaned, {
              creator: Kiba::Tms::Jobs::Places::FinalCleanupCleaned,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "places_final_cleanup_cleaned.csv"
              ),
              tags: %i[places cleanup],
              lookup_on: :norm
            }
            register :final_cleaned_lookup, {
              creator: Kiba::Tms::Jobs::Places::FinalCleanedLookup,
              path: File.join(Kiba::Tms.datadir, "working",
                "place_final_cleaned_lookup.csv"),
              tags: %i[places],
              lookup_on: :orig_combined
            }
            register :orig_cleaned, {
              creator: Kiba::Tms::Jobs::Places::FinalCleanedLookup,
              path: File.join(Kiba::Tms.datadir, "working",
                "place_final_cleaned_lookup.csv"),
              tags: %i[places],
              lookup_on: :norm_combined
            }
            register :authority_lookup, {
              creator: Kiba::Tms::Jobs::Places::AuthorityLookup,
              path: File.join(Kiba::Tms.datadir, "working",
                "place_authority_lookup.csv"),
              tags: %i[places],
              lookup_on: :place
            }
            register :ingest, {
              creator: Kiba::Tms::Jobs::Places::Ingest,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "places.csv"),
              tags: %i[places ingest]
            }
            register :by_norm_segment, {
              creator: Kiba::Tms::Jobs::Places::ByNormSegment,
              path: File.join(Kiba::Tms.datadir, "working",
                "places_by_norm_segment.csv"),
              tags: %i[places],
              lookup_on: :normsegment,
              desc: "Used to match/score uncategorized terms against places"
            }
            register :by_norm_word, {
              creator: Kiba::Tms::Jobs::Places::ByNormWord,
              path: File.join(Kiba::Tms.datadir, "working",
                "places_by_norm_word.csv"),
              tags: %i[places],
              lookup_on: :normword,
              desc: "Used to match/score uncategorized terms against places"
            }
          end
        end

        # "reference_master"
        Kiba::Tms::RegistryData::ReferenceMaster.register

        Kiba::Tms.registry.namespace("terms") do
          register :used_in_xrefs, {
            creator: Kiba::Tms::Jobs::Terms::UsedInXrefs,
            path: File.join(Kiba::Tms.datadir, "reference",
              "terms_used_in_xrefs.csv"),
            desc: "Terms table rows for term IDs used in ThesXrefs",
            lookup_on: :termid,
            tags: %i[termdata terms reference]
          }
          register :used_row_data, {
            creator: Kiba::Tms::Jobs::Terms::UsedRowData,
            path: File.join(Kiba::Tms.datadir, "reference",
              "terms_used_row_data.csv"),
            desc: "All Terms rows having termmasterid that appears in Terms row used in ThesXrefs. (Allowing merging of alternate terms, etc.)",
            lookup_on: :termid,
            tags: %i[termdata terms reference]
          }
          register :preferred, {
            creator: Kiba::Tms::Jobs::Terms::Preferred,
            path: File.join(Kiba::Tms.datadir, "reference",
              "terms_preferred.csv"),
            lookup_on: :termid,
            tags: %i[termdata terms]
          }
        end

        Kiba::Tms.registry.namespace("term_master_geo") do
          register :used_in_xrefs, {
            creator: Kiba::Tms::Jobs::TermMasterGeo::UsedInXrefs,
            path: File.join(Kiba::Tms.datadir, "reference",
              "term_master_geo_used_in_xrefs.csv"),
            desc: "TermMasterGeo table rows referenced by Terms referenced "\
              "in ThesXrefs",
            lookup_on: :termmasterid,
            tags: %i[termdata terms reference]
          }
        end

        Kiba::Tms.registry.namespace("term_master_thes") do
          register :used_in_xrefs, {
            creator: Kiba::Tms::Jobs::TermMasterThes::UsedInXrefs,
            path: File.join(Kiba::Tms.datadir, "reference",
              "term_master_thes_used_in_xrefs.csv"),
            desc: "TermMasterThes table rows referenced by Terms referenced "\
              "in ThesXrefs",
            lookup_on: :termmasterid,
            tags: %i[termdata terms reference]
          }
        end

        Kiba::Tms.registry.namespace("thes_xrefs") do
          register :term_ids_used, {
            creator: Kiba::Tms::Jobs::ThesXrefs::TermIdsUsed,
            path: File.join(Kiba::Tms.datadir, "reference",
              "term_ids_used_in_thes_xrefs.csv"),
            desc: "List of term ids used in ThesXrefs.",
            tags: %i[termdata thes_xrefs terms reference],
            lookup_on: :termid
          }
        end

        # Since, by definition, UserFields will be custom to a given
        #   project, most handling of these fields (if there are any)
        #   will be in the client project. See az_ccp for examples
        Kiba::Tms.registry.namespace("user_fields") do
          register :used, {
            creator: Kiba::Tms::Jobs::UserFields::Used,
            path: File.join(Kiba::Tms.datadir, "reference",
              "user_fields_used.csv"),
            tags: %i[user_fields],
            lookup_on: :userfieldid,
            desc: "Unique :userfieldid values used in UserFieldXrefs"
          }
        end

        # "obj_insurance" "valuation_control"
        Kiba::Tms::RegistryData::Valuationcontrols.register

        Kiba::Tms.registry.namespace("works") do
          register :lookup, {
            creator: Kiba::Tms::Jobs::Works::Lookup,
            path: File.join(Kiba::Tms.datadir, "working", "works_lookup.csv"),
            tags: %i[works],
            lookup_on: :work
          }
          register :ingest, {
            creator: Kiba::Tms::Jobs::Works::Ingest,
            path: File.join(Kiba::Tms.datadir, "ingest", "works.csv"),
            tags: %i[works ingest]
          }
        end
      end
    end
  end
end
