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

        Kiba::Tms.registry.namespace("accession_lot") do
          register :valuation_prep, {
            creator: Kiba::Tms::Jobs::AccessionLot::ValuationPrep,
            path: File.join(Kiba::Tms.datadir, "working",
              "accession_lot_valuation_prep.csv"),
            desc: "Valuation Control procedures created from AccessionLot "\
              "data. Still with ID for creating relationships",
            tags: %i[valuation acquisitions],
            lookup_on: :acquisitionlotid
          }
        end

        Kiba::Tms.registry.namespace("acq_num_acq") do
          register :obj_rows, {
            creator: Kiba::Tms::Jobs::AcqNumAcq::ObjRows,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "acq_num_acq_obj_rows.csv"
            ),
            desc: "ObjAccession rows to be processed with :acqnumber approach",
            tags: %i[acquisitions]
          }
          register :combined, {
            creator: Kiba::Tms::Jobs::AcqNumAcq::Combined,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "acq_num_acq_combined.csv"
            ),
            desc: ":obj_rows, with :combined field added",
            tags: %i[acquisitions]
          }
          register :rows, {
            creator: Kiba::Tms::Jobs::AcqNumAcq::Rows,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "acq_num_acq_rows.csv"
            ),
            desc: "ObjAccession rows to be processed with :acqnumber approach "\
              "deduplicated on combined row values. Generated id merged in as "\
              ":acquisitionreferencenumber",
            tags: %i[acquisitions],
            lookup_on: :combined
          }
          register :prep, {
            creator: Kiba::Tms::Jobs::AcqNumAcq::Prep,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "acq_num_acq_prepped.csv"
            ),
            desc: "ObjAccession rows to be processed with :acqnumber "\
              "approach, prepped",
            tags: %i[acquisitions],
            lookup_on: :acquisitionreferencenumber
          }
          register :acq_obj_rel, {
            creator: Kiba::Tms::Jobs::AcqNumAcq::AcqObjRel,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "acq_num_acq_obj_rel.csv"
            ),
            tags: %i[acquisitions objects nhr]
          }
          register :acq_valuation_rel, {
            creator: Kiba::Tms::Jobs::AcqNumAcq::AcqValuationRel,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "acq_num_acq_valuation_rel.csv"
            ),
            tags: %i[acquisitions valuation nhr]
          }
        end

        Kiba::Tms.registry.namespace("acquisitions") do
          register :ids_final, {
            creator: Kiba::Tms::Jobs::Acquisitions::IdsFinal,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "acq_ids_final.csv"
            ),
            tags: %i[acquisitions],
            desc: "Compiles refnums and unique ids from all sources; "\
              "generates unique acquisitionreferencenumber values across "\
              "sources",
            lookup_on: :increment
          }
          register :all, {
            creator: Kiba::Tms::Jobs::Acquisitions::All,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "acq_all.csv"
            ),
            tags: %i[acquisitions],
            desc: "Compiles acquisitions from all treatments",
            dest_special_opts: {
              initial_headers: %i[
                acquisitionreferencenumber
                objaccessiontreatment acquisitionmethod creditline
              ]
            }
          }
          register :for_ingest, {
            creator: Kiba::Tms::Jobs::Acquisitions::ForIngest,
            path: File.join(
              Kiba::Tms.datadir,
              "ingest",
              "acquisitions.csv"
            ),
            tags: %i[acquisitions],
            desc: "Removes non-ingestable fields. If migration is in dev, "\
            "applies sample if sample has been selected"
          }
          register :from_acq_num, {
            creator: Kiba::Tms::Jobs::Acquisitions::FromAcqNum,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "acq_from_acq_num.csv"
            ),
            tags: %i[acquisitions]
          }
          register :from_linked_set, {
            creator: Kiba::Tms::Jobs::Acquisitions::FromLinkedSet,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "acq_from_linked_set.csv"
            ),
            tags: %i[acquisitions]
          }
          register :from_lot_num, {
            creator: Kiba::Tms::Jobs::Acquisitions::FromLotNum,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "acq_from_lot_num.csv"
            ),
            tags: %i[acquisitions]
          }
          register :from_one_to_one, {
            creator: Kiba::Tms::Jobs::Acquisitions::FromOneToOne,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "acq_from_one_to_one.csv"
            ),
            tags: %i[acquisitions]
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
            tags: %i[collectionobjects ingest]
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

        Kiba::Tms.registry.namespace("exhibitions") do
          register :shaped, {
            creator: Kiba::Tms::Jobs::Exhibitions::Shaped,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "exhibitions_shaped.csv"
            ),
            desc: "Reshape prepped exhibition data",
            tags: %i[exhibitions]
          }
          register :merge_exh_obj_info, {
            creator: Kiba::Tms::Jobs::Exhibitions::MergeExhObjInfo,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "exhibitions_obj_info_merged.csv"
            ),
            desc: "Adds Exhibited Object Information section data, if "\
              "migration is configured to do so, otherwise passes the table "\
              "through with no changes",
            tags: %i[exhibitions objects]
          }
          register :nhrs, {
            creator: Kiba::Tms::Jobs::Exhibitions::Nhrs,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhrs_exhibitions.csv"
            ),
            desc: "Compiles all nhrs between exhibitions and loans, objects",
            tags: %i[exhibitions nhr]
          }
          register :con_xref_review, {
            creator: Kiba::Tms::Jobs::Exhibitions::ConXrefReview,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "exhibitions_con_xref_review.csv"
            ),
            desc: "Prepares :con_refs_for__exhibitions rows having unmapped "\
              "role values for client review",
            tags: %i[exhibitions con reports],
            dest_special_opts: {
              initial_headers: %i[exhibitionnumber role person org]
            }
          }
        end

        Kiba::Tms.registry.namespace("exh_loan_xrefs") do
          register :nhr_exh_loan, {
            creator: Kiba::Tms::Jobs::ExhLoanXrefs::NhrExhLoan,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_exh_loan.csv"
            ),
            desc: "Creates NHRs between exhibitions and loans in",
            tags: %i[exhibitions loansin nhr]
          }
          register :nhr_exh_loanin, {
            creator: Kiba::Tms::Jobs::ExhLoanXrefs::NhrExhLoanin,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_exh_loanin.csv"
            ),
            desc: "Creates NHRs between exhibitions and loans in",
            tags: %i[exhibitions loansin nhr]
          }
          register :nhr_exh_loanout, {
            creator: Kiba::Tms::Jobs::ExhLoanXrefs::NhrExhLoanout,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_exh_loanout.csv"
            ),
            desc: "Creates NHRs between exhibitions and loans out",
            tags: %i[exhibitions loansout nhr]
          }
        end

        Kiba::Tms.registry.namespace("exh_obj_loan_obj_xrefs") do
          register :nhr_exh_loan, {
            creator: Kiba::Tms::Jobs::ExhObjLoanObjXrefs::NhrExhLoan,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_exh_loan_through_obj.csv"
            ),
            desc: "Creates NHRs between exhibitions and loans, through "\
              "objects",
            tags: %i[exhibitions loans nhr]
          }
        end

        Kiba::Tms.registry.namespace("exh_obj_xrefs") do
          register :nhr_obj_exh, {
            creator: Kiba::Tms::Jobs::ExhObjXrefs::NhrObjExh,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_obj_exh.csv"
            ),
            desc: "Creates NHRs between objects and exhibitions",
            tags: %i[exhibitions objects nhr]
          }
          register :text_entries_review, {
            creator: Kiba::Tms::Jobs::ExhObjXrefs::TextEntriesReview,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "exh_obj_xrefs_with_text_entries.csv"
            ),
            desc: "Relationships between Exhibitions and Objects that "\
              "have TextEntries merged in",
            tags: %i[exhibitions objects text_entries reports]
          }
        end

        Kiba::Tms.registry.namespace("linked_lot_acq") do
          register :obj_rows, {
            creator: Kiba::Tms::Jobs::LinkedLotAcq::ObjRows,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "linked_lot_acq__obj_rows.csv"
            ),
            desc: "All ObjAccession rows to be treated as :linkedlot",
            tags: %i[acquisitions]
          }
          register :rows, {
            creator: Kiba::Tms::Jobs::LinkedLotAcq::Rows,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "linked_lot_acq_rows.csv"
            ),
            desc: ":obj_rows, deduplicated on regsetid",
            tags: %i[acquisitions]
          }
          # register :prep, {
          #   creator: Kiba::Tms::Jobs::LinkedLotAcq::Prep,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'linked_lot_acq.csv'),
          #   tags: %i[acquisitions]
          # }
        end

        Kiba::Tms.registry.namespace("linked_set_acq") do
          register :obj_rows, {
            creator: Kiba::Tms::Jobs::LinkedSetAcq::ObjRows,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "linked_set_acq__obj_rows.csv"
            ),
            desc: "All ObjAccession rows to be treated as :linkedset",
            tags: %i[acquisitions]
          }
          register :rows, {
            creator: Kiba::Tms::Jobs::LinkedSetAcq::Rows,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "linked_set_acq_rows.csv"
            ),
            desc: ":obj_rows, deduplicated on regsetid",
            tags: %i[acquisitions]
          }
          register :prep, {
            creator: Kiba::Tms::Jobs::LinkedSetAcq::Prep,
            path: File.join(Kiba::Tms.datadir, "working", "linked_set_acq.csv"),
            tags: %i[acquisitions],
            lookup_on: :registrationsetid
          }
          register :acq_obj_rel, {
            creator: Kiba::Tms::Jobs::LinkedSetAcq::AcqObjRel,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "linked_set_acq_nhr.csv"
            ),
            tags: %i[acquisitions objects nhr]
          }
          register :acq_valuation_rel, {
            creator: Kiba::Tms::Jobs::LinkedSetAcq::AcqValuationRel,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "linked_set_valuation_nhr.csv"
            ),
            tags: %i[acquisitions valuation nhr]
          }
          register :object_statuses, {
            creator: Kiba::Tms::Jobs::LinkedSetAcq::ObjectStatuses,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "linked_set_acq_object_statuses.csv"
            ),
            tags: %i[acquisitions],
            lookup_on: :objectid
          }
        end

        Kiba::Tms.registry.namespace("loan_obj_xrefs") do
          register :by_obj, {
            creator: Kiba::Tms::Jobs::LoanObjXrefs::Prep,
            path: File.join(Kiba::Tms.datadir, "prepped", "loan_obj_xrefs.csv"),
            tags: %i[loans objects relations],
            lookup_on: :objectid
          }
          register :loanin_obj_lookup, {
            creator: Kiba::Tms::Jobs::LoanObjXrefs::LoaninObjLookup,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "loanin_obj_lookup.csv"
            ),
            tags: %i[loans objects],
            lookup_on: :objectid,
            desc: "Outputs single field: :objectid"
          }
          register :creditlines, {
            creator: Kiba::Tms::Jobs::LoanObjXrefs::Creditlines,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "loanin_obj_creditlines.csv"
            ),
            tags: %i[loans],
            lookup_on: :loanid
          }
          register :post_mig_cleanup, {
            creator: Kiba::Tms::Jobs::LoanObjXrefs::PostMigCleanup,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "loan_obj_relations_post_mig_cleanup.csv"
            ),
            tags: %i[loans objects postmigcleanup],
            desc: "Outputs data to be dealt with in post-migration cleanup"
          }
        end

        Kiba::Tms.registry.namespace("loans") do
          register :in, {
            creator: Kiba::Tms::Jobs::Loans::In,
            path: File.join(Kiba::Tms.datadir, "working", "loans_in.csv"),
            desc: "Loans with :loantype = `loan in`",
            tags: %i[loans loansin],
            lookup_on: :loanid
          }
          register :in_lookup, {
            creator: Kiba::Tms::Jobs::Loans::InLookup,
            path: File.join(Kiba::Tms.datadir, "working",
              "loans_in_lookup.csv"),
            desc: "Loans with :loantype = `loan in`; does NOT require running "\
              "prep__loans job as a dependency; outputs single field: "\
              ":loanid",
            tags: %i[loans loansin],
            lookup_on: :loanid
          }
          register :out, {
            creator: Kiba::Tms::Jobs::Loans::Out,
            path: File.join(Kiba::Tms.datadir, "working", "loans_out.csv"),
            desc: "Loans with :loantype = `loan out`",
            tags: %i[loans loansout],
            lookup_on: :loanid
          }
          register :nhrs, {
            creator: Kiba::Tms::Jobs::Loans::Nhrs,
            path: File.join(Kiba::Tms.datadir, "working", "loans_nhrs.csv"),
            desc: "Compiles loan/obj NHRs for loans in and out",
            tags: %i[loans loansout loansin objects nhr]
          }
          register :unexpected_type, {
            creator: Kiba::Tms::Jobs::Loans::UnexpectedType,
            path: File.join(Kiba::Tms.datadir, "reports",
              "loans_unexpected_type.csv"),
            desc: "Loans with :loantype not `loan in` or `loan out`. Non-zero means work to do!",
            tags: %i[loans todochk]
          }
        end

        Kiba::Tms.registry.namespace("loansin") do
          register :prep, {
            creator: Kiba::Tms::Jobs::Loansin::Prep,
            path: File.join(Kiba::Tms.datadir, "working", "loansin__prep.csv"),
            tags: %i[loans loansin],
            lookup_on: :loanid
          }
          register :cspace, {
            creator: Kiba::Tms::Jobs::Loansin::Cspace,
            path: File.join(Kiba::Tms.datadir, "working",
              "loansin__cspace.csv"),
            tags: %i[loans loansin]
          }
          register :lender_contact_structure_review, {
            creator: Kiba::Tms::Jobs::Loansin::LenderContactStructureReview,
            path: File.join(Kiba::Tms.datadir, "reports",
              "loansin_lender_contact_structure_review.csv"),
            tags: %i[loans loansin postmigcleanup],
            desc: "Contact names may be stored in the :contact field in TMS "\
              "and/or merged in from ConXrefs tables. Lender names are merged "\
              "in from ConXrefs tables. There is no explicit relationship "\
              "expressing which contact name goes with which lender name. "\
              "Further, even if there were, details of how this data must "\
              "be structured for ingest into CS (multiple possible lender "\
              "names from two different authorities, that need to be lined "\
              "up with contact names from one authority) make it vulnerable "\
              "to getting messed up if there is more than one name value for "\
              "lender and contact."
          }
          register :rel_obj, {
            creator: Kiba::Tms::Jobs::Loansin::RelObj,
            path: File.join(Kiba::Tms.datadir, "working",
              "loansin__rel_obj.csv"),
            tags: %i[loans loansin relations nhr]
          }
        end

        Kiba::Tms.registry.namespace("loansout") do
          register :prep, {
            creator: Kiba::Tms::Jobs::Loansout::Prep,
            path: File.join(Kiba::Tms.datadir, "working", "loansout__prep.csv"),
            tags: %i[loans loansout]
          }
          register :cspace, {
            creator: Kiba::Tms::Jobs::Loansout::Cspace,
            path: File.join(Kiba::Tms.datadir, "working",
              "loansout__cspace.csv"),
            tags: %i[loans loansout]
          }
          register :rel_obj, {
            creator: Kiba::Tms::Jobs::Loansout::RelObj,
            path: File.join(Kiba::Tms.datadir, "working",
              "loansout__rel_obj.csv"),
            tags: %i[loans loansout relations]
          }
        end

        Kiba::Tms.registry.namespace("locs") do
          Kiba::Tms::Locations.authorities.each do |type|
            register "#{type}_cspace".to_sym, {
              creator: {
                callee: Tms::Jobs::Locations::Cspace,
                args: {type: type}
              },
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "locs_cspace_#{type}.csv"
              ),
              desc: "Locations in #{type} vocabulary, prepped for ingest",
              tags: %i[locations]
            }
          end
          register :from_locations, {
            creator: Kiba::Tms::Jobs::Locations::FromLocations,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "locs_from_locations.csv"
            ),
            desc: "Locations extracted from TMS Locations",
            tags: %i[locations]
          }
          register :from_obj_locs, {
            creator: Kiba::Tms::Jobs::Locations::FromObjLocs,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "locs_from_obj_locs.csv"
            ),
            desc: "Locations created by appending :loclevel and/or :sublevel "\
              "to locationid location value",
            tags: %i[locations]
          }
          register :compiled_hier_0, {
            creator: Kiba::Tms::Jobs::Locations::CompiledHier0,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "locs_compiled_hier_0.csv"
            ),
            desc: "Locations from different sources, compiled, hierarchy "\
              "levels added, round 0",
            tags: %i[locations]
          }
          register :compiled_hierarchy, {
            creator: Kiba::Tms::Jobs::Locations::CompiledHierarchy,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "locs_compiled_hierarchy.csv"
            ),
            desc: "Locations from different sources, compiled, hierarchy "\
              "levels added",
            tags: %i[locations]
          }
          register :hierarchy, {
            creator: Kiba::Tms::Jobs::Locations::Hierarchy,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "locs_hierarchy.csv"
            ),
            desc: "Compiled hierarchy converted into term hierarchy for ingest",
            tags: %i[locations]
          }
          register :compiled, {
            creator: Kiba::Tms::Jobs::Locations::Compiled,
            path: File.join(Kiba::Tms.datadir, "working", "locs_compiled.csv"),
            desc: "Locations from different sources, compiled, final",
            tags: %i[locations],
            dest_special_opts: {
              initial_headers:
              %i[
                usage_ct location_name parent_location
                storage_location_authority address
                term_source fulllocid
              ]
            },
            lookup_on: :fulllocid
          }
          register :compiled_clean, {
            creator: Kiba::Tms::Jobs::Locations::CompiledClean,
            path: File.join(Kiba::Tms.datadir, "working",
              "locs_compiled_clean.csv"),
            desc: "Locations from different sources, compiled, with cleanup "\
              "applied",
            tags: %i[locations],
            dest_special_opts: {
              initial_headers:
              %i[
                usage_ct location_name
                storage_location_authority address
                term_source fulllocid
              ]
            },
            lookup_on: :fulllocid
          }
          register :worksheet, {
            creator: Kiba::Tms::Jobs::Locations::Worksheet,
            path: File.join(
              Kiba::Tms.datadir,
              "to_client",
              "location_review.csv"
            ),
            desc: "Locations for client review",
            tags: %i[locations],
            dest_special_opts: {
              initial_headers: proc { Tms::Locations.worksheet_columns }
            }
          }
          if Tms::Locations.cleanup_done
            Tms::Locations.provided_worksheet_jobs
              .each_with_index do |job, idx|
                jobname = job.to_s
                  .delete_prefix("locs__")
                  .to_sym
                register jobname, {
                  path: Tms::Locations.provided_worksheets[idx],
                  desc: "Locations cleanup/review worksheet provided to client",
                  tags: %i[locations cleanup],
                  supplied: true
                }
              end
            register :previous_worksheet_compile, {
              creator: Tms::Jobs::Locations::PreviousWorksheetCompile,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "locs_previous_worksheet_compile.csv"
              ),
              tags: %i[locations cleanup],
              desc: "Joins completed supplied worksheets and deduplicates on "\
                ":fulllocid",
              lookup_on: :fulllocid
            }
            Tms::Locations.returned_file_jobs
              .each_with_index do |job, idx|
                jobname = job.to_s
                  .delete_prefix("locs__")
                  .to_sym
                register jobname, {
                  path: Tms::Locations.returned_files[idx],
                  desc: "Completed locations review/cleanup worksheet",
                  tags: %i[locations cleanup],
                  supplied: true
                }
              end
            register :returned_compile, {
              creator: Tms::Jobs::Locations::ReturnedCompile,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "locs_returned_compile.csv"
              ),
              tags: %i[locations cleanup],
              desc: "Joins completed cleanup worksheets and deduplicates on "\
                ":fulllocid",
              lookup_on: :fulllocid
            }
            register :cleanup_changes, {
              creator: Tms::Jobs::Locations::CleanupChanges,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "locs_cleanup_changes.csv"
              ),
              tags: %i[locations cleanup],
              desc: "Rows with changes to merge into existing base location data",
              lookup_on: :fulllocid
            }
            register :cleanup_added_locs, {
              creator: Tms::Jobs::Locations::CleanupAddedLocs,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "locs_cleanup_added_locs.csv"
              ),
              tags: %i[locations cleanup],
              desc: "Rows where client added new locations in cleanup data"
            }
          end
        end

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

        Kiba::Tms.registry.namespace("lot_num_acq") do
          register :obj_rows, {
            creator: Kiba::Tms::Jobs::LotNumAcq::ObjRows,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "lot_num_acq_obj_rows.csv"
            ),
            desc: "ObjAccession rows to be processed with :lotnumber approach",
            tags: %i[acquisitions],
            lookup_on: :acquisitionlot
          }
          register :rows, {
            creator: Kiba::Tms::Jobs::LotNumAcq::Rows,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "lot_num_acq_rows.csv"
            ),
            desc: "ObjAccession rows to be processed with :lotnumber approach "\
              "deduplicated on :acquisitionlot value",
            tags: %i[acquisitions]
          }
          register :prep, {
            creator: Kiba::Tms::Jobs::LotNumAcq::Prep,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "lot_num_acq_prepped.csv"
            ),
            desc: "ObjAccession rows to be processed with :lotnumber "\
              "approach, prepped",
            tags: %i[acquisitions],
            lookup_on: :acquisitionreferencenumber
          }
          register :acq_obj_rel, {
            creator: Kiba::Tms::Jobs::LotNumAcq::AcqObjRel,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "lot_num_acq_obj_rel.csv"
            ),
            tags: %i[acquisitions objects nhr]
          }
          register :acq_valuation_rel, {
            creator: Kiba::Tms::Jobs::LotNumAcq::AcqValuationRel,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "lot_num_acq_valuation_rel.csv"
            ),
            tags: %i[acquisitions valuation nhr]
          }
        end

        Kiba::Tms.registry.namespace("media") do
          register :for_ingest, {
            creator: Kiba::Tms::Jobs::Media::ForIngest,
            path: File.join(
              Kiba::Tms.datadir,
              "ingest",
              "media.csv"
            ),
            desc: "Removes non-CS fields",
            tags: %i[media_files media ingest]
          }
        end

        Kiba::Tms.registry.namespace("media_files") do
          register :aws_ls, {
            supplied: true,
            path: File.join(
              Kiba::Tms.datadir, "supplied", "aws_ls.csv"
            )
          }
          register :file_path_lookup, {
            creator: Kiba::Tms::Jobs::MediaFiles::FilePathLookup,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "media_files_path_lookup.csv"
            ),
            desc: "Adds normalized form of file path for lookup of actual "\
              "media file paths in S3",
            tags: %i[media_files media],
            lookup_on: :norm
          }
          register :migratable, {
            creator: Kiba::Tms::Jobs::MediaFiles::Migratable,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "media_files_migratable.csv"
            ),
            desc: "Removes rows for media files included in "\
              ":media_files__unmigratable_report",
            tags: %i[media_files media]
          }
          register :migratable_files, {
            creator: Kiba::Tms::Jobs::MediaFiles::MigratableFiles,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "media_files_migratable.csv"
            ),
            desc: "List of unique media files (deduplicated on :fullpath "\
              "value), with :filesize, :memorysize. Give to client so they "\
              "can location and transfer media files to S3 for ingest.",
            tags: %i[media_files media reports],
            dest_special_opts: {
              initial_headers: %i[fullpath filename filesize memorysize]
            }
          }
          register :shaped, {
            creator: Kiba::Tms::Jobs::MediaFiles::Shaped,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "media_files_shaped.csv"
            ),
            desc: "Media files data reshaped for CS; Creates :mediafileuri",
            tags: %i[media_files media]
          }
          register :migrating, {
            creator: Kiba::Tms::Jobs::MediaFiles::Migrating,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "media_files_migrating.csv"
            ),
            desc: "Removes rows without files, if not migrating fileless "\
              "media; Adds :identificationnumber",
            tags: %i[media_files media],
            lookup_on: :mediafileuri
          }
          register :not_migrating, {
            creator: Kiba::Tms::Jobs::MediaFiles::NotMigrating,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "media_files_not_migrating.csv"
            ),
            desc: "Lists TMS media data rows that cannot be matched to a "\
              "media file in S3",
            tags: %i[media_files media reports]
          }
          register :duplicate_files, {
            creator: Kiba::Tms::Jobs::MediaFiles::DuplicateFiles,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "media_files_duplicate_files.csv"
            ),
            desc: "Records where the same filepath is used in more than one "\
              "MediaFiles record. Typically we create one Media Handling "\
              "procedure in CS from each MediaFiles record. We want to "\
              "only ingest each file once in CS, and there is no way to "\
              "have multiple Media Handling records describing the same file "\
              "in CS. Where there are multiple TMS records for the same file, "\
              "we can't know what descriptive data the client wants to retain "\
              "in the migration for that file. We provide this report for "\
              "initial decision-making on how to handle these.",
            tags: %i[media_files media reports],
            dest_special_opts: {
              initial_headers:
              %i[fullpath rend_renditionnumber file_entered_date filedate
                rend_renditiondate rend_mediatype rend_quality rend_remarks]
            }
          }
          register :id_lookup, {
            creator: Kiba::Tms::Jobs::MediaFiles::IdLookup,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "media_files_id_lookup.csv"
            ),
            desc: "Get :identificationnumber via :fileid",
            tags: %i[media_files],
            lookup_on: :mediamasterid
          }
          register :file_names, {
            creator: Kiba::Tms::Jobs::MediaFiles::FileNames,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "media_file_names.csv"
            ),
            desc: "List of media file names only",
            tags: %i[media_files reports]
          }
          register :no_filename, {
            creator: Kiba::Tms::Jobs::MediaFiles::NoFilename,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "media_files_no_filename.csv"
            ),
            desc: "MediaXrefs::TargetReport rows where :filename is not "\
              "populated. MediaXrefs::TargetReport is the source only so "\
              "output columns will match unmigratable and unreferenced",
            tags: %i[media_files]
          }
          register :target_report, {
            creator: Kiba::Tms::Jobs::MediaFiles::TargetReport,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "media_file_target_tables.csv"
            ),
            desc: "Merges MediaXrefs target tables into MediaFiles::Prep",
            tags: %i[media_files reports],
            dest_special_opts: {
              initial_headers: %i[targettable fullpath_duplicate
                filename_duplicate path filename]
            }
          }
          register :unmigratable_report, {
            creator: Kiba::Tms::Jobs::MediaFiles::UnmigratableReport,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "media_files_unmigratable.csv"
            ),
            desc: "MediaXrefs::TargetReport rows where :targettable is empty "\
              "or contains only tables that cannot be related to Media "\
              "Handling procedures",
            tags: %i[media_files reports],
            lookup_on: :fileid
          }
          register :unmigratable, {
            creator: Kiba::Tms::Jobs::MediaFiles::Unmigratable,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "media_files_unmigratable.csv"
            ),
            desc: "MediaXrefs::TargetReport rows where :targettable contains "\
              "only tables that cannot be related to Media Handling procedures",
            tags: %i[media_files]
          }
          register :unreferenced, {
            creator: Kiba::Tms::Jobs::MediaFiles::Unreferenced,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "media_files_unreferenced.csv"
            ),
            desc: "MediaXrefs::TargetReport rows where :targettable is empty",
            tags: %i[media_files]
          }
          register :nhr_report, {
            creator: Kiba::Tms::Jobs::MediaFiles::NhrReport,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "media_files_relationships.csv"
            ),
            desc: "Summary of nonhierarchical relationships between Media and "\
              "other record types",
            tags: %i[media_files]
          }
          register :not_matched_to_record, {
            creator: Kiba::Tms::Jobs::MediaFiles::NotMatchedToRecord,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "media_files_not_matched_to_record.csv"
            ),
            desc: "List of media files uploaded to S3 that cannot be matched "\
              "TMS data on normalized file path",
            tags: %i[media_files reports]
          }
        end

        Kiba::Tms.registry.namespace("media_xrefs") do
          register :nhrs, {
            creator: Kiba::Tms::Jobs::MediaXrefs::Nhrs,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_media.csv"
            ),
            desc: "All Media NHRs",
            tags: %i[media nhr],
            lookup_on: :item2_id
          }
          register :accession_lot, {
            creator: Kiba::Tms::Jobs::MediaXrefs::AccessionLot,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_media_accession_lot.csv"
            ),
            desc: "Media <-> Acquisition NHRs through AccessionLot",
            tags: %i[media acquisitions nhr]
          }
          register :cond_line_items, {
            creator: Kiba::Tms::Jobs::MediaXrefs::CondLineItems,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_media_cond_line_items.csv"
            ),
            desc: "Media <-> ConditionCheck NHRs through CondLineItems",
            tags: %i[media acquisitions nhr]
          }
          register :exhibitions, {
            creator: Kiba::Tms::Jobs::MediaXrefs::Exhibitions,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_media_exhibitions.csv"
            ),
            desc: "Media <-> Exhibition NHRs",
            tags: %i[media exhibitions nhr]
          }
          register :loansin, {
            creator: Kiba::Tms::Jobs::MediaXrefs::Loansin,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_media_loansin.csv"
            ),
            desc: "Media <-> Loans In NHRs",
            tags: %i[media loansin nhr]
          }
          register :loansout, {
            creator: Kiba::Tms::Jobs::MediaXrefs::Loansout,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_media_loansout.csv"
            ),
            desc: "Media <-> Loans Out NHRs",
            tags: %i[media loansout nhr]
          }
          register :objects, {
            creator: Kiba::Tms::Jobs::MediaXrefs::Objects,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_media_objects.csv"
            ),
            desc: "Media <-> Object NHRs",
            tags: %i[media objects nhr]
          }
          register :obj_insurance, {
            creator: Kiba::Tms::Jobs::MediaXrefs::ObjInsurance,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_media_obj_insurance.csv"
            ),
            desc: "Media <-> Valuation Control NHRs",
            tags: %i[media obj_insurance valuation_control nhr]
          }
          register :for_target_report, {
            creator: Kiba::Tms::Jobs::MediaXrefs::ForTargetReport,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "media_xrefs_for_target_report.csv"
            ),
            desc: "Lookup table used to merge target tables into media files "\
              "report",
            tags: %i[media_xrefs reports],
            lookup_on: :mediamasterid
          }
        end

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
                "- Deduplicate on :cleanupid"\
                "- Removes #{Tms::NameCompile.na_in_migration_value} values\n"\
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
                  "- Reverts any edited non-editable field to original value\n"\
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
                "and reverting non-editable values. :discarded_edit column is "\
                "present for reporting"
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
            desc: "Only typed (person/org) main terms from initial compiled terms flagged as duplicates",
            tags: %i[names],
            lookup_on: :fingerprint
          }
          register :untyped_main_duplicates, {
            creator: Kiba::Tms::Jobs::NameCompile::UntypedMainDuplicates,
            path: File.join(Kiba::Tms.datadir, "working",
              "names_compiled_untyped_main_duplicates.csv"),
            desc: "Only untyped main terms from initial compiled terms flagged as duplicates",
            tags: %i[names],
            lookup_on: :fingerprint
          }
          register :variant_duplicates, {
            creator: Kiba::Tms::Jobs::NameCompile::VariantDuplicates,
            path: File.join(Kiba::Tms.datadir, "working",
              "names_compiled_variant_duplicates.csv"),
            desc: "Only variant terms from initial compiled terms flagged as duplicates",
            tags: %i[names],
            lookup_on: :fingerprint
          }
          register :related_duplicates, {
            creator: Kiba::Tms::Jobs::NameCompile::RelatedDuplicates,
            path: File.join(Kiba::Tms.datadir, "working",
              "names_compiled_related_duplicates.csv"),
            desc: "Only related terms from initial compiled terms flagged as duplicates",
            tags: %i[names],
            lookup_on: :fingerprint
          }
          register :note_duplicates, {
            creator: Kiba::Tms::Jobs::NameCompile::NoteDuplicates,
            path: File.join(Kiba::Tms.datadir, "working",
              "names_compiled_note_duplicates.csv"),
            desc: "Only note terms from initial compiled terms flagged as duplicates",
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
            desc: "From Constituents orgs with multipe core name detail elements OR (a single core name detail element AND a position value)",
            tags: %i[names con]
          }
          register :from_con_org_with_single_name_part_no_position, {
            creator: Kiba::Tms::Jobs::NameCompile::FromConOrgWithSingleNamePartNoPosition,
            path: File.join(Kiba::Tms.datadir, "working",
              "names_compiled_from_con_org_with_single_name_part_no_position.csv"),
            desc: "From Constituents orgs with a single core name detail element, and no position value",
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

        Kiba::Tms.registry.namespace("name_type_cleanup") do
          register :from_base_data, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::FromBaseData,
            path: File.join(Kiba::Tms.datadir, "working",
              "name_type_cleanup_from_base_data.csv"),
            desc: "Data from main/base data source used to create Name Type review/cleanup worksheet",
            tags: %i[names cleanup]
          }
          register :worksheet, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::Worksheet,
            path: File.join(
              Kiba::Tms.datadir,
              "to_client",
              "name_type_cleanup_worksheet.csv"
            ),
            tags: %i[names cleanup],
            dest_special_opts: {
              initial_headers: Tms::NameTypeCleanup.initial_headers
            }
          }
          # For use with :convert_returned_to_uncontrolled. Manually tweak if
          #   needed
          # register :worksheet_returned, {
          #   path: File.join(
          #     Kiba::Tms.datadir,
          #     'supplied',
          #     'name_type_cleanup_20221212.csv'
          #   ),
          #   supplied: true
          # }
          # # Manually tweak this one if you need to use it.
          # register :convert_returned_to_uncontrolled, {
          #   creator: Kiba::Tms::Jobs::NameTypeCleanup::ConvertReturnedToUncontrolled,
          #   path: File.join(
          #     Kiba::Tms.datadir,
          #     'supplied',
          #     'name_type_cleanup_20221212_CONVERTED.csv'
          #   ),
          #   tags: %i[names cleanup]
          # }

          if Tms::NameTypeCleanup.done
            Tms::NameTypeCleanup.provided_worksheet_jobs
              .each_with_index do |job, idx|
                jobname = job.to_s
                  .delete_prefix("name_type_cleanup__")
                  .to_sym
                register jobname, {
                  path: Tms::NameTypeCleanup.provided_worksheets[idx],
                  desc: "NameType cleanup worksheet provided to client",
                  tags: %i[names cleanup],
                  supplied: true
                }
              end
            register :previous_worksheet_compile, {
              creator:
              Kiba::Tms::Jobs::NameTypeCleanup::PreviousWorksheetCompile,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "name_type_cleanup_previous_worksheet_compile.csv"
              ),
              tags: %i[names cleanup],
              desc: "Joins completed supplied worksheets and deduplicates on "\
                ":constituentid",
              lookup_on: :constituentid
            }
            Tms::NameTypeCleanup.returned_file_jobs
              .each_with_index do |job, idx|
                jobname = job.to_s
                  .delete_prefix("name_type_cleanup__")
                  .to_sym
                register jobname, {
                  path: Tms::NameTypeCleanup.returned_files[idx],
                  desc: "Completed nametype cleanup worksheet",
                  tags: %i[names cleanup],
                  supplied: true
                }
              end
            register :returned_compile, {
              creator: Kiba::Tms::Jobs::NameTypeCleanup::ReturnedCompile,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "name_type_cleanup_returned_compile.csv"
              ),
              tags: %i[names cleanup],
              desc: "Joins completed cleanup worksheets, adds :cleanupid if "\
                "it does not exist, and deduplicates on :cleanupid",
              lookup_on: :cleanupid
            }
            register :returned_prep, {
              creator: Kiba::Tms::Jobs::NameTypeCleanup::ReturnedPrep,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "name_type_cleanup_returned_prep.csv"
              ),
              tags: %i[names cleanup],
              desc: "Prepares supplied cleanup spreadsheet for use in "\
                "overlaying cleaned up data and generating phase 2 name "\
                "cleanup worksheet"
            }
            register :corrected_name_lookup, {
              creator: Kiba::Tms::Jobs::NameTypeCleanup::CorrectedNameLookup,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "name_type_cleanup_corrected_name_lookup.csv"
              ),
              tags: %i[names cleanup],
              desc: "Creates a table of known correct name/contype "\
                "combinations, in field :corrfingerprint. Used to avoid "\
                "marking already-corrected names `for review` in new "\
                "iterations of name type cleanup worksheet, because value is "\
                "now coming from a different constituentid",
              lookup_on: :corrfingerprint
            }
            register :corrected_value_lookup, {
              creator: Kiba::Tms::Jobs::NameTypeCleanup::CorrectedValueLookup,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "name_type_cleanup_corrected_value_lookup.csv"
              ),
              tags: %i[names cleanup],
              desc: "Creates a table of known corrected name/contype "\
                "combinations, in field :corrfingerprint. Used to avoid "\
                "marking already-corrected names `for review` in new "\
                "iterations of name type cleanup worksheet, because value is "\
                "now coming from a different place unaffected by an already-"\
                "made correction",
              lookup_on: :corrfingerprint
            }
          end
          register :for_con_alt_names, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::ForConAltNames,
            path: File.join(Kiba::Tms.datadir, "working",
              "name_type_cleanup_for_con_alt_names.csv"),
            tags: %i[names cleanup],
            lookup_on: :altnameid
          }
          register :for_constituents, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::ForConstituents,
            path: File.join(Kiba::Tms.datadir, "working",
              "name_type_cleanup_for_constituents.csv"),
            tags: %i[names cleanup],
            lookup_on: :constituentid
          }
          register :for_con_org_with_name_parts, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::ForConOrgWithNameParts,
            path: File.join(Kiba::Tms.datadir, "working",
              "name_type_cleanup_for_con_org_with_name_parts.csv"),
            tags: %i[names cleanup],
            lookup_on: :constituentid
          }
          register :for_con_person_with_inst, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::ForConPersonWithInst,
            path: File.join(Kiba::Tms.datadir, "working",
              "name_type_cleanup_for_con_person_with_inst.csv"),
            tags: %i[names cleanup],
            lookup_on: :constituentid
          }
          register :for_uncontrolled_name_tables, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::ForUncontrolledNameTables,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "name_type_cleanup_for_uncontrolled_tables.csv"
            ),
            tags: %i[names cleanup],
            lookup_on: :constituentid
          }
        end

        Kiba::Tms.registry.namespace("names") do
          register :by_altnameid, {
            desc: "For some bizarre reason, at least some TMS tables link to "\
              'to a name via :constituentid, but the ":constituentid" value '\
              "should actually be looked up as :altnameid and then mapped to "\
              "correct constituent name. This was discovered while mapping "\
              'valuation control information source names.\n\nThis table has '\
              "the same structure as :by_constituentid, but the lookup is on "\
              ":altnameid",
            creator: Kiba::Tms::Jobs::Names::ByAltnameid,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "names_by_altnameid.csv"
            ),
            tags: %i[names],
            lookup_on: :altnameid
          }
          register :by_constituentid, {
            creator: Kiba::Tms::Jobs::Names::ByConstituentid,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "names_by_constituentid.csv"
            ),
            desc: "With lookup on :constituentid, gives :person and :org "\
              "columns from which to merge authorized form of name. Also "\
              "gives :prefname and :nonprefname columns for use if type "\
              "of name does not matter. Only name values are retained in "\
              "this table, not name details.",
            tags: %i[names],
            lookup_on: :constituentid
          }
          register :by_norm, {
            creator: Kiba::Tms::Jobs::Names::ByNorm,
            path: File.join(Kiba::Tms.datadir, "working", "names_by_norm.csv"),
            desc: "With lookup on normalized version of original name value (i.e. "\
              "from any table, not controlled by constituentid), gives "\
              "`:person` and `:organization` column from which to merge "\
              "authorized form of name",
            tags: %i[names],
            lookup_on: :norm
          }
          register :by_norm_prep, {
            creator: Kiba::Tms::Jobs::Names::ByNormPrep,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "names_by_norm_prep.csv"
            ),
            desc: "Simplifies :name_compile__unique to only normalized "\
              ":contype, :name, and :norm values, where :norm is the "\
              "normalized ORIG value of the name",
            tags: %i[names],
            lookup_on: :norm
          }
          # register :compiled, {
          #   creator: Kiba::Tms::Jobs::Names::CompiledData,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled.csv'),
          #   desc: 'Compiled names',
          #   tags: %i[names],
          #   dest_special_opts: {
          #     initial_headers:
          #     %i[
          #        termsource normalized_form approx_normalized duplicate inconsistent_org_names missing_last_name
          #        migration_action constituenttype preferred_name_form variant_name_form alt_names
          #        institution contact_person contact_role
          #        salutation nametitle firstname middlename lastname suffix
          #        begindateiso enddateiso nationality culturegroup school
          #        biography remarks
          #        approved active isstaff is_private_collector code
          #       ] }
          # }
          # register :orgs, {
          #   creator: Kiba::Tms::Jobs::Names::Orgs,
          #   path: File.join(
          #     Kiba::Tms.datadir,
          #     'working',
          #     'names_orgs.csv'
          #   ),
          #   tags: %i[names],
          #   lookup_on: :constituentid
          # }
          # register :flagged_duplicates, {
          #   creator: Kiba::Tms::Jobs::Names::CompiledDataDuplicatesFlagged,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents_flagged_duplicates.csv'),
          #   desc: 'Names extracted from constituents table and flagged as duplicates',
          #   tags: %i[names con],
          #   lookup_on: :norm
          # }
          # register :initial_compile, {
          #   creator: Kiba::Tms::Jobs::Names::CompiledDataRaw,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents_initial_compile.csv'),
          #   desc: 'Names extracted from constituents table and other sources, with only subsequent duplicates flagged',
          #   tags: %i[names con]
          # }
          # register :from_constituents, {
          #   creator: Kiba::Tms::Jobs::Names::FromConstituents,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents.csv'),
          #   desc: 'Names extracted from constituents table',
          #   tags: %i[names con]
          # }
          # register :from_constituents_orgs_from_persons, {
          #   creator: Kiba::Tms::Jobs::Names::OrgsFromConstituentPersons,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents_orgs_from_persons.csv'),
          #   desc: 'Names extracted from institution field of Person constituents',
          #   tags: %i[names con]
          # }
          # register :from_constituents_persons_from_orgs, {
          #   creator: Kiba::Tms::Jobs::Names::PersonsFromConstituentOrgs,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents_persons_from_orgs.csv'),
          #   desc: 'Names extracted from Organization constituents when the name part values are populated',
          #   tags: %i[names con]
          # }
          # register :from_loans, {
          #   creator: Kiba::Tms::Jobs::Names::FromLoans,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_loans.csv'),
          #   desc: 'Names extracted from loans table',
          #   tags: %i[names loans]
          # }
          # register :from_loc_approvers, {
          #   creator: Kiba::Tms::Jobs::Names::FromLocApprovers,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_loc_approvers.csv'),
          #   desc: 'Names extracted from LocApprovers table',
          #   tags: %i[names loc_approvers]
          # }
          # register :from_loc_handlers, {
          #   creator: Kiba::Tms::Jobs::Names::FromLocHandlers,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_loc_handlers.csv'),
          #   desc: 'Names extracted from LocHandlers table',
          #   tags: %i[names loc_handlers]
          # }
          # register :from_obj_accession, {
          #   creator: Kiba::Tms::Jobs::Names::FromObjAccession,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_obj_accession.csv'),
          #   desc: 'Names extracted from obj_accession table',
          #   tags: %i[names obj_accession]
          # }
          # register :from_obj_incoming, {
          #   creator: Kiba::Tms::Jobs::Names::FromObjIncoming,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_obj_incoming.csv'),
          #   desc: 'Names extracted from obj_incoming table',
          #   tags: %i[names obj_incoming]
          # }
          # register :from_obj_locations, {
          #   creator: Kiba::Tms::Jobs::Names::FromObjLocations,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_obj_locations.csv'),
          #   desc: 'Names extracted from obj_locations table',
          #   tags: %i[names obj_locations]
          # }
          # register :from_reference_master, {
          #   creator: Kiba::Tms::Jobs::Names::FromReferenceMaster,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_reference_master.csv'),
          #   desc: 'Names extracted from reference_master table',
          #   tags: %i[names reference_master]
          # }
          # register :from_assoc_parents_for_con, {
          #   creator: Kiba::Tms::Jobs::Names::FromAssocParentsForCon,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'names_from_assoc_parents_for_con.csv'),
          #   desc: 'Names extracted from AssocParents (for constituents) table',
          #   tags: %i[names assoc_parents]
          # }
        end

        Kiba::Tms.registry.namespace("nhrs") do
          register :all, {
            creator: Kiba::Tms::Jobs::Nhrs::All,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "nhr_all.csv"
            ),
            tags: %i[nhr],
            desc: "Compiles NHRs of all types"
          }
        end

        Kiba::Tms.registry.namespace("obj_accession") do
          register :initial_prep, {
            creator: Kiba::Tms::Jobs::ObjAccession::InitialPrep,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "obj_accession_initial_prep.csv"
            ),
            tags: %i[obj_accessions setup],
            desc: "Prepares data enough for loans report to be meaningful: "\
              "merges in object numbers and accession methods. Flags objects "\
              "linked to loans in through the LoanObjXrefs table."
          }
          register :loans_in, {
            creator: Kiba::Tms::Jobs::ObjAccession::LoansIn,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "obj_accession_loans_in.csv"
            ),
            tags: %i[obj_accessions setup],
            desc: "Rows for objects linked to loansin via LoanObjXrefs table. "\
              "Merges in data fields from :loansin__prep for comparison",
            dest_special_opts: {
              initial_headers: %i[acquisitionlot acquisitionnumber objectnumber
                loanin_loaninnumber accessionmethod creditline]
            }
          }
          register :in_migration, {
            creator: Kiba::Tms::Jobs::ObjAccession::InMigration,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "obj_accession_in_migration.csv"
            ),
            tags: %i[obj_accessions setup],
            desc: "Removes rows for objects not linked to loansin, if "\
              "configured to do so. Otherwise passes through all rows."
          }
          register :linked_lot, {
            creator: Kiba::Tms::Jobs::ObjAccession::LinkedLot,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_accession_linked_lot.csv"),
            tags: %i[obj_accessions setup],
            desc: "Rows from which acquisitions will be created using LinkedLot approach"
          }
          register :linked_set, {
            creator: Kiba::Tms::Jobs::ObjAccession::LinkedSet,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_accession_linked_set.csv"),
            tags: %i[obj_accessions setup],
            desc: "Rows from which acquisitions will be created using LinkedSet approach"
          }
          register :lot_number, {
            creator: Kiba::Tms::Jobs::ObjAccession::LotNumber,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "obj_accession_lot_number.csv"
            ),
            tags: %i[obj_accessions setup],
            desc: "Rows from which acquisitions will be created using "\
              "LotNumber approach"
          }
          register :acq_number, {
            creator: Kiba::Tms::Jobs::ObjAccession::AcqNumber,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "obj_accession_acq_number.csv"
            ),
            tags: %i[obj_accessions setup],
            desc: "Rows from which acquisitions will be created using "\
              "AcqNumber approach"
          }
          register :one_to_one, {
            creator: Kiba::Tms::Jobs::ObjAccession::OneToOne,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_accession_one_to_one.csv"),
            tags: %i[obj_accessions setup],
            desc: "Rows from which acquisitions will be created using OneToOne approach"
          }
        end

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
            path: File.join(Kiba::Tms.datadir, "reports",
              "obj_components_problem_lmi.csv"),
            tags: %i[obj_components reports postmigcleanup]
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
          register :all_uniq, {
            creator: Kiba::Tms::Jobs::ObjDates::AllUniq,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_dates_all_uniq.csv"),
            tags: %i[obj_dates],
            desc: "Unique date values from ObjDates, Objects.dated, and "\
              "other sources as configured in ObjDates.all_sources, for "\
              "Emendate processing"
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

        Kiba::Tms.registry.namespace("obj_locations") do
          register :migrating, {
            creator: Kiba::Tms::Jobs::ObjLocations::Migrating,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_locations_migrating.csv"),
            tags: %i[obj_locations],
            desc: "- Removes rows where :objlocationid = -1\n"\
              "- Removes rows where :locationid = -1\n"\
              "- If migration is configured to drop inactive "\
              "rows, drops rows where :inactive = 1"\
              "- Adds fullfingerprint",
            dest_special_opts: {
              initial_headers:
              %i[objectnumber objlocationid is_temp transdate
                location_purpose transport_type transport_status
                location prevobjlocid nextobjlocid]
            },
            lookup_on: :objlocationid
          }
          register :migrating_custom, {
            creator: Kiba::Tms::Jobs::ObjLocations::MigratingCustom,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_locations_migrating_custom.csv"),
            tags: %i[obj_locations],
            desc: "- Removes project-specific omission rows",
            lookup_on: :objlocationid
          }
          register :unique, {
            creator: Kiba::Tms::Jobs::ObjLocations::Unique,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_locations_unique.csv"),
            tags: %i[obj_locations],
            desc: "- Deduplicates on :fullfingerprint\n"\
              "- Merge in related objectnumbers\n"\
              "- Merge in :homelocationname\n"\
              "- Add :year field (for use building movementrefnums)\n"\
              "- Merge names",
            dest_special_opts: {
              initial_headers:
              %i[objectnumber objlocationid is_temp transdate
                location_purpose transport_type transport_status
                location homelocationname prevobjlocid nextobjlocid]
            }
          }
          register :inventory, {
            creator: Kiba::Tms::Jobs::ObjLocations::Inventory,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_locations_inventory.csv"),
            tags: %i[obj_locations],
            desc: "Filter to only rows treated as Inventory LMI"
          }
          register :lmi, {
            creator: Kiba::Tms::Jobs::ObjLocations::Lmi,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_locations_lmi.csv"),
            tags: %i[obj_locations],
            desc: "Compile inventory, location, and movement LMIs"
          }
          register :nhr_lmi_obj, {
            creator: Kiba::Tms::Jobs::ObjLocations::NhrLmiObj,
            path: File.join(Kiba::Tms.datadir, "working",
              "nhr_lmi_obj.csv"),
            tags: %i[movement objects nhr]
          }
          register :location, {
            creator: Kiba::Tms::Jobs::ObjLocations::Location,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_locations_location.csv"),
            tags: %i[obj_locations],
            desc: "Filter to only rows treated as Location LMI"
          }
          register :movement, {
            creator: Kiba::Tms::Jobs::ObjLocations::Movement,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_locations_movement.csv"),
            tags: %i[obj_locations],
            desc: "Filter to only rows treated as Movement LMI"
          }
          register :inactive_review, {
            creator: Kiba::Tms::Jobs::ObjLocations::InactiveReview,
            path: File.join(Kiba::Tms.datadir, "reports",
              "obj_locations_inactive_review.csv"),
            tags: %i[obj_locations reports],
            dest_special_opts: {
              initial_headers:
              %i[objectnumber transdate location currentlocationnote is_temp
                inactive location_purpose transport_type transport_status
                objlocationid prevobjlocid nextobjlocid
                prev_location next_location]
            }
          }
          register :dropping, {
            creator: Kiba::Tms::Jobs::ObjLocations::Dropping,
            path: File.join(Kiba::Tms.datadir, "reports",
              "obj_locations_dropping_from_migration.csv"),
            tags: %i[obj_locations reports],
            desc: "ObjLocation rows that will be omitted from the migration. "\
              "The reason for omission is stated in the :dropreason column. "\
              "LMIs in CS that are not attached to any Object record(s) do "\
              "not serve any purpose. LMIs in CS require a location value, "\
              "so if there is not an associated location, we cannot create "\
              "and LMI in the migration",
            dest_special_opts: {
              initial_headers:
              %i[objlocationid dropreason objectnumber transdate location]
            }

          }
          register :dropping_no_location, {
            creator: Kiba::Tms::Jobs::ObjLocations::DroppingNoLocation,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_locations_dropping_no_location.csv"),
            tags: %i[obj_locations],
            desc: "ObjLocation rows having no linked Storage Location value. "\
              "Adds :dropreason column"
          }
          register :dropping_no_object, {
            creator: Kiba::Tms::Jobs::ObjLocations::DroppingNoObject,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_locations_dropping_no_object.csv"),
            tags: %i[obj_locations],
            desc: "ObjLocation rows having no linked Object value. "\
              "Adds :dropreason column"
          }
          register :location_names_merged, {
            creator: Kiba::Tms::Jobs::ObjLocations::LocationNamesMerged,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_locations_location_names_merged.csv"),
            tags: %i[obj_locations],
            desc: "Merges location names (using fulllocid) into location, "\
              "prevloc, nextloc, and scheduled loc fields",
            lookup_on: :objectnumber
          }
          register :mappable_temptext, {
            creator: Kiba::Tms::Jobs::ObjLocations::MappableTemptext,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "location_temptext_for_mapping.csv"
            ),
            tags: %i[obj_locations locs cleanup],
            desc: "Unique tmslocationstring + temptext values for client to "\
              "categorize/map into sublocations or notes",
            dest_special_opts: {
              initial_headers: %i[temptext mapping corrected_value
                loc1 loc3 loc5
                objectnumber transdate dateout]
            }
          }
          register :mappable_temptext_support, {
            creator: Kiba::Tms::Jobs::ObjLocations::MappableTemptextSupport,
            path: File.join(
              Kiba::Tms.datadir,
              "reports",
              "objlocations_reference_for_temptext_mapping.csv"
            ),
            tags: %i[obj_locations locs],
            desc: "ObjLocations rows with temptext values, with "\
              "tmslocationstring values merged in. Provided to client to "\
              "support completing mappable_temptext worksheet",
            dest_special_opts: {
              initial_headers: %i[temptext loc1 loc3 loc5
                objectnumber transdate dateout]
            }
          }
          if Tms::ObjLocations.temptext_mapping_done
            register :temptext_mapped, {
              path: File.join(
                Kiba::Tms.datadir,
                "supplied",
                "location_temptext_for_mapping.csv"
              ),
              tags: %i[obj_locations locs],
              supplied: true
            }
            register :temptext_mapped_for_merge, {
              creator: Tms::Jobs::ObjLocations::TemptextMappedForMerge,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "temptext_mapped_for_merge.csv"
              ),
              tags: %i[obj_locations locs],
              desc: "Removes unneeded fields; adds :lookup column",
              lookup_on: :lookup
            }
          end
          register :fulllocid_lookup, {
            creator: Kiba::Tms::Jobs::ObjLocations::FulllocidLookup,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_locations_by_fulllocid.csv"),
            tags: %i[obj_locations],
            desc: "Deletes everything else. Used to get counts of location usages",
            lookup_on: :fulllocid
          }
          register :prev_next_sched_loc_merge, {
            creator: Kiba::Tms::Jobs::ObjLocations::PrevNextSchedLocMerge,
            path: File.join(Kiba::Tms.datadir, "working",
              "obj_locations_prev_next_sched_merged.csv"),
            tags: %i[obj_locations obj_components reports]
          }
        end

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
            tags: %i[objects],
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
            tags: %i[objects],
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

        Kiba::Tms.registry.namespace("one_to_one_acq") do
          register :obj_rows, {
            creator: Kiba::Tms::Jobs::OneToOneAcq::ObjRows,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "one_to_one_acq_obj_rows.csv"
            ),
            desc: "ObjAccession rows to be processed with :onetoone approach",
            tags: %i[acquisitions]
          }
          register :combined, {
            creator: Kiba::Tms::Jobs::OneToOneAcq::Combined,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "one_to_one_acq_combined.csv"
            ),
            desc: ":combined values added as per configured treatment",
            tags: %i[acquisitions]
          }
          register :acq_num_lookup, {
            creator: Kiba::Tms::Jobs::OneToOneAcq::AcqNumLookup,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "one_to_one_acq_acq_num_lookup.csv"
            ),
            desc: "Returns unique :acqrefnum by :combined value.",
            tags: %i[acquisitions],
            lookup_on: :combined
          }
          register :prep, {
            creator: Kiba::Tms::Jobs::OneToOneAcq::Prep,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "one_to_one_acq_prepped.csv"
            ),
            desc: "ObjAccession rows to be processed with :onetoone "\
              "approach, prepped",
            tags: %i[acquisitions],
            lookup_on: :acquisitionreferencenumber
          }
          register :acq_obj_rel, {
            creator: Kiba::Tms::Jobs::OneToOneAcq::AcqObjRel,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "one_to_one_acq_nhr.csv"
            ),
            tags: %i[acquisitions objects nhr]
          }
          register :acq_valuation_rel, {
            creator: Kiba::Tms::Jobs::OneToOneAcq::AcqValuationRel,
            path: File.join(
              Kiba::Tms.datadir,
              "working",
              "one_to_one_valuation_nhr.csv"
            ),
            tags: %i[acquisitions valuation nhr]
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
            "for linkage"
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

        Kiba::Tms.registry.namespace("reference_master") do
          register :prep_clean, {
            creator: Kiba::Tms::Jobs::ReferenceMaster::PrepClean,
            path: File.join(Kiba::Tms.datadir, "working",
              "reference_master_prep_clean.csv"),
            desc: "Merges in corrections from placepublished cleanup "\
              "worksheet, if completed.",
            tags: %i[reference_master],
            lookup_on: :referenceid
          }
          register :places, {
            creator: Kiba::Tms::Jobs::ReferenceMaster::Places,
            path: File.join(Kiba::Tms.datadir, "working",
              "reference_master_places.csv"),
            desc: "Extracts unique place values from placepublished, in "\
              "format for combination with other places for cleanup and "\
              "translation to authority terms",
            tags: %i[reference_master places]
          }
          register :place_authority_merge, {
            creator: Kiba::Tms::Jobs::ReferenceMaster::PlaceAuthorityMerge,
            path: File.join(Kiba::Tms.datadir, "working",
              "reference_master_place_authority_merge.csv"),
            desc: "Merges in cleaned-up authority terms.",
            tags: %i[reference_master places],
            lookup_on: :placepublished
          }
          refmaster_ppworksheet_hdrs = %i[placepublished publisher
            merge_fingerprint]
          if Tms::ReferenceMaster.placepublished_done
            refmaster_ppworksheet_hdrs.unshift(:to_review)
          end
          register :placepublished_worksheet, {
            creator: Kiba::Tms::Jobs::ReferenceMaster::PlacepublishedWorksheet,
            path: File.join(Kiba::Tms.datadir, "to_client",
              "reference_master_placepublished_cleanup.csv"),
            desc: "Supports splitting of multiple place names by adding a "\
              "delimiter, and separating publisher name from place value",
            tags: %i[reference_master places],
            dest_special_opts: {
              initial_headers: refmaster_ppworksheet_hdrs
            }
          }

          if Tms::ReferenceMaster.placepublished_done
            Tms::ReferenceMaster.placepublished_worksheet_jobs
              .each_with_index do |job, idx|
                jobname = job.to_s
                  .delete_prefix("reference_master__")
                  .to_sym
                register jobname, {
                  path: Tms::ReferenceMaster.placepublished_worksheets[idx],
                  desc: "Placepublished cleanup worksheet provided to client",
                  tags: %i[reference_master cleanup],
                  supplied: true
                }
              end
            register :placepublished_worksheet_compile, {
              creator:
              Kiba::Tms::Jobs::ReferenceMaster::PlacepublishedWorksheetCompile,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "reference_master_placepublished_worksheet_compile.csv"
              ),
              tags: %i[reference_master cleanup],
              desc: "Joins completed supplied worksheets and deduplicates on "\
                ":merge_fingerprint",
              lookup_on: :merge_fingerprint
            }
            Tms::ReferenceMaster.placepublished_returned_jobs
              .each_with_index do |job, idx|
                jobname = job.to_s
                  .delete_prefix("reference_master__")
                  .to_sym
                register jobname, {
                  path: Tms::ReferenceMaster.placepublished_returned[idx],
                  desc: "Completed placepublished cleanup worksheet",
                  tags: %i[reference_master cleanup],
                  supplied: true
                }
              end
            register :placepublished_returned_compile, {
              creator:
              Kiba::Tms::Jobs::ReferenceMaster::PlacepublishedReturnedCompile,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "reference_master_placepublished_returned_compile.csv"
              ),
              tags: %i[reference_master cleanup],
              desc: "Joins completed worksheets and deduplicates on "\
                ":merge_fingerprint. Flags corrected fields (based on decoded "\
                "fingerprint) and deletes the decoded original fields",
              lookup_on: :merge_fingerprint
            }
            register :placepublished_corrections, {
              creator:
              Kiba::Tms::Jobs::ReferenceMaster::PlacepublishedCorrections,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "reference_master_placepublished_corrections.csv"
              ),
              tags: %i[reference_master cleanup],
              desc: "Only rows from :placepublished_returned_compile that "\
                "have changes, for merge into :placepublishedcleaned.",
              lookup_on: :merge_fingerprint
            }
          end
        end

        Kiba::Tms.registry.namespace("registration_sets") do
          register :for_ingest, {
            creator: Kiba::Tms::Jobs::RegistrationSets::ForIngest,
            path: File.join(Kiba::Tms.datadir, "working",
              "reg_set_for_ingest.csv"),
            desc: "Acquisitions for ingest, derived from RegSets. RegSet id removed.",
            tags: %i[acquisitions]
          }
          register :not_linked, {
            creator: Kiba::Tms::Jobs::RegistrationSets::NotLinked,
            path: File.join(Kiba::Tms.datadir, "reports",
              "reg_sets_not_linked.csv"),
            desc: "RegistrationSet rows not linked to objects in ObjAccession",
            tags: %i[acquisitions]
          }
          register :obj_rels, {
            creator: Kiba::Tms::Jobs::RegistrationSets::ObjRels,
            path: File.join(Kiba::Tms.datadir, "working",
              "reg_set_acq_obj_rels.csv"),
            tags: %i[nhr acquisitions objects]
          }
        end

        Kiba::Tms.registry.namespace("rels_acq_obj") do
          register :for_ingest, {
            creator: Kiba::Tms::Jobs::RelsAcqObj::ForIngest,
            path: File.join(
              Kiba::Tms.datadir,
              "ingest",
              "rels_acq_obj.csv"
            ),
            tags: %i[acquisitions objects nhr],
            desc: "Compiles acquisition-object nhrs from all treatments and "\
              "prepares for ingest"
          }
        end

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

        Kiba::Tms.registry.namespace("valuation_control") do
          register :all, {
            creator: Kiba::Tms::Jobs::ValuationControl::All,
            path: File.join(Kiba::Tms.datadir, "working", "vc_all.csv"),
            tags: %i[valuation],
            lookup_on: :objinsuranceid
          }
          register :all_clean, {
            creator: Kiba::Tms::Jobs::ValuationControl::AllClean,
            path: File.join(Kiba::Tms.datadir, "working", "vc_all_clean.csv"),
            tags: %i[valuation]
          }
          register :from_accession_lot, {
            creator: Kiba::Tms::Jobs::ValuationControl::FromAccessionLot,
            path: File.join(Kiba::Tms.datadir, "working",
              "vc_from_accessionlot.csv"),
            tags: %i[valuation acquisitions]
          }
          register :from_obj_insurance, {
            creator: Kiba::Tms::Jobs::ValuationControl::FromObjInsurance,
            path: File.join(Kiba::Tms.datadir, "working",
              "vc_from_obj_insurance.csv"),
            tags: %i[valuation obj_insurance]
          }
          register :nhrs, {
            creator: Kiba::Tms::Jobs::ValuationControl::Nhrs,
            path: File.join(Kiba::Tms.datadir, "working", "nhr_vc.csv"),
            tags: %i[valuation nhr]
          }
          register :nhr_acq_accession_lot, {
            creator: Kiba::Tms::Jobs::ValuationControl::NhrAcqAccessionLot,
            path: File.join(Kiba::Tms.datadir, "working",
              "nhr_acq_vc_from_accessionlot.csv"),
            tags: %i[valuation acquisitions nhr]
          }
          register :nhr_obj_accession_lot, {
            creator: Kiba::Tms::Jobs::ValuationControl::NhrObjAccessionLot,
            path: File.join(Kiba::Tms.datadir, "working",
              "nhr_obj_vc_from_accessionlot.csv"),
            tags: %i[valuation objects nhr]
          }
          register :nhr_obj, {
            creator: Kiba::Tms::Jobs::ValuationControl::NhrObj,
            path: File.join(Kiba::Tms.datadir, "working",
              "nhr_obj_vc.csv"),
            tags: %i[valuation objects nhr]
          }
        end

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
