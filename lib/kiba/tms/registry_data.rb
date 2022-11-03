# frozen_string_literal: true

module Kiba
  module Tms
    # Central place to register the expected jobs/files used and produced by your project
    #
    # Populates file registry provided by Kiba::Extend
    module RegistryData
      module_function

      def register
        register_supplied_files
        register_prep_files
        Tms::Utils::PerTableJobRegistrar.call
        register_files
      end

      def register_prep_files
        tables = Kiba::Tms::Table::List.call.map{ |table| Kiba::Tms::Table::Obj.new(table) }
          .select(&:included)

        Kiba::Tms.registry.namespace('prep') do
          tables.each do |table|
            reghash = Tms::Table::Prep::RegistryHashCreator.call(table)
            next unless reghash

            register table.filekey, reghash
          end
        end
      end
      private_class_method :register_prep_files

      def register_supplied_files
        tables = Kiba::Tms::Table::List.call.map{ |table| Kiba::Tms::Table::Obj.new(table) }
          .select(&:included)

        Kiba::Tms.registry.namespace('tms') do
          tables.each do |table|
            register table.filekey, Tms::Table::Supplied::RegistryHashCreator.call(table)
          end
        end
      end
      private_class_method :register_supplied_files

      def register_files

        # register :object_numbers, {
        #   path: File.join(Kiba::Tms.datadir, 'prepped', 'object_numbers.csv'),
        #   creator: Kiba::Tms::Jobs::Objects.method(:object_numbers),
        #   lookup_on: :objectnumber,
        #   tags: %i[objects lookup prep]
        # }

        Kiba::Tms.registry.namespace('report') do
          register :terms_in_mig, {
            creator: Kiba::Tms::Jobs::Terms::Reports.method(:in_mig),
            path: File.join(Kiba::Tms.datadir, 'reports', 'terms_in_migration.csv'),
            desc: 'Unique terms in migration',
            tags: %i[termdata reports]
          }
        end

        Kiba::Tms.registry.namespace('accession_lot') do
          register :valuation_prep, {
            creator: Kiba::Tms::Jobs::AccessionLot::ValuationPrep,
            path: File.join(Kiba::Tms.datadir, 'working', 'accession_lot_valuation_prep.csv'),
            desc: 'Valuation Control procedures created from AccessionLot data. Still with ID for creating relationships',
            tags: %i[valuation acquisitions],
            lookup_on: :acquisitionlotid
          }
        end

        Kiba::Tms.registry.namespace('acq_num_acq') do
          register :obj_rows, {
            creator: Kiba::Tms::Jobs::AcqNumAcq::ObjRows,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'acq_num_acq_obj_rows.csv'
            ),
            desc: 'ObjAccession rows to be processed with :acqnumber approach',
            tags: %i[acquisitions]
          }
          register :rows, {
            creator: Kiba::Tms::Jobs::AcqNumAcq::Rows,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'acq_num_acq_rows.csv'
            ),
            desc: 'ObjAccession rows to be processed with :acqnumber approach '\
              'deduplicated on combined row values. Generated id merged in as '\
              ':acquisitionreferencenumber',
            tags: %i[acquisitions],
            lookup_on: :combined
          }
          register :prep, {
            creator: Kiba::Tms::Jobs::AcqNumAcq::Prep,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'acq_num_acq_prepped.csv'
            ),
            desc: 'ObjAccession rows to be processed with :acqnumber '\
              'approach, prepped',
            tags: %i[acquisitions]
          }
          register :acq_obj_rel, {
            creator: Kiba::Tms::Jobs::AcqNumAcq::AcqObjRel,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'acq_num_acq_obj_rel.csv'
            ),
            tags: %i[acquisitions objects nhr]
          }
        end

        Kiba::Tms.registry.namespace('acquisitions') do
          register :all, {
            creator: Kiba::Tms::Jobs::Acquisitions::All,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'acq_all.csv'
            ),
            tags: %i[acquisitions],
            desc: 'Compiles acquisitions from all treatments'
          }
          register :obj_rels, {
            creator: Kiba::Tms::Jobs::Acquisitions::ObjRels,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'acq_obj_rels.csv'
            ),
            tags: %i[acquisitions objects nhr],
            desc: 'Compiles acquisition-object nhrs from all treatments'
          }
          register :from_acq_num, {
            creator: Kiba::Tms::Jobs::Acquisitions::FromAcqNum,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'acq_from_acq_num.csv'
            ),
            tags: %i[acquisitions]
          }
          register :from_linked_set, {
            creator: Kiba::Tms::Jobs::Acquisitions::FromLinkedSet,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'acq_from_linked_set.csv'
            ),
            tags: %i[acquisitions]
          }
          register :from_lot_num, {
            creator: Kiba::Tms::Jobs::Acquisitions::FromLotNum,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'acq_from_lot_num.csv'
            ),
            tags: %i[acquisitions]
          }
          register :from_one_to_one, {
            creator: Kiba::Tms::Jobs::Acquisitions::FromOneToOne,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'acq_from_one_to_one.csv'
            ),
            tags: %i[acquisitions]
          }
        end

        Kiba::Tms.registry.namespace('alt_nums') do
          register :new_tables, {
            creator: Kiba::Tms::Jobs::AltNums::NewTables,
            path: File.join(Kiba::Tms.datadir, 'reports', 'alt_nums_new_tables.csv'),
            desc: 'Tables with alt nums where table handling is not yet set up. Non-zero means work to do!',
            tags: %i[altnums todochk reports]
          }
          register :for_constituents, {
            creator: Kiba::Tms::Jobs::AltNums::ForConstituents,
            path: File.join(Kiba::Tms.datadir, 'working', 'alt_nums_for_constituents.csv'),
            desc: 'AltNums to be merged into Constituents',
            tags: %i[altnums constituents],
            lookup_on: :recordid
          }
          register :for_objects, {
            creator: Kiba::Tms::Jobs::AltNums::ForObjects,
            path: File.join(Kiba::Tms.datadir, 'working', 'alt_nums_for_objects.csv'),
            tags: %i[altnums objects],
            lookup_on: :recordid
          }
          register :for_reference_master, {
            creator: Kiba::Tms::Jobs::AltNums::ForReferenceMaster,
            path: File.join(Kiba::Tms.datadir, 'working', 'alt_nums_for_refs.csv'),
            desc: 'AltNums to be merged into ReferenceMaster',
            tags: %i[altnums reference_master],
            lookup_on: :recordid
          }
          register :for_objects_todo, {
            creator: Kiba::Tms::Jobs::AltNums::ForObjectsTodo,
            path: File.join(Kiba::Tms.datadir, 'reports', 'alt_nums_for_objects_todo.csv'),
            desc: 'Reference AltNums with date values - need to map. Non-zero means work to do!',
            tags: %i[altnums todochk]
          }
          register :for_reference_master_todo, {
            creator: Kiba::Tms::Jobs::AltNums::ForReferenceMasterTodo,
            path: File.join(Kiba::Tms.datadir, 'reports', 'alt_nums_for_refs_todo.csv'),
            desc: 'Reference AltNums with date values - need to map. Non-zero means work to do!',
            tags: %i[altnums todochk]
          }
          register :description_single_occs, {
            creator: Kiba::Tms::Jobs::AltNums::DescriptionSingleOccs,
            path: File.join(Kiba::Tms.datadir, 'reports', 'alt_nums_description_single_occ.csv'),
            desc: 'AltNums with a description only used once',
            tags: %i[altnums reports]
          }
          register :description_occs, {
            creator: Kiba::Tms::Jobs::AltNums::DescriptionOccs,
            path: File.join(Kiba::Tms.datadir, 'reports', 'alt_nums_description_occs.csv'),
            desc: 'AltNums with count of description occurrences - source data for other reports',
            tags: %i[altnums]
          }
          register :no_description, {
            creator: Kiba::Tms::Jobs::AltNums::NoDescription,
            path: File.join(Kiba::Tms.datadir, 'reports', 'alt_nums_no_description.csv'),
            desc: 'AltNums without a description value',
            tags: %i[altnums reports]
          }
          register :types, {
            creator: Kiba::Tms::Jobs::AltNums::Types,
            path: File.join(Kiba::Tms.datadir, 'reports', 'alt_num_types.csv'),
            desc: 'AltNumber types',
            tags: %i[altnums reports]
          }
        end

        Kiba::Tms.registry.namespace('assoc_parents') do
          register :for_constituents, {
            creator: Kiba::Tms::Jobs::AssocParents::ForConstituents,
            path: File.join(Kiba::Tms.datadir, 'working', 'assoc_parents_for_con.csv'),
            lookup_on: :recordid,
            tags: %i[assoc_parents con]
          }
        end

        Kiba::Tms.registry.namespace('associations') do
          register :missing_values, {
            creator: Kiba::Tms::Jobs::Associations::MissingValues,
            path: File.join(Kiba::Tms.datadir, 'reports', 'associations_missing_values.csv'),
            desc: 'One of the involved ids could not be mapped to a value, human-readable relationship cannot be created.',
            tags: %i[associations reports]
          }
        end

        Kiba::Tms.registry.namespace('classification_notations') do
          register :ids_used, {
            creator: Kiba::Tms::Jobs::ClassificationNotations::IdsUsed,
            path: File.join(Kiba::Tms.datadir, 'reference', 'classification_notation_ids_used.csv'),
            desc: 'Extracts list of unique classification notation ids in used TermMasterThes rows',
            lookup_on: :primarycnid,
            tags: %i[termdata terms reference]
          }
          register :used, {
            creator: Kiba::Tms::Jobs::ClassificationNotations::Used,
            path: File.join(Kiba::Tms.datadir, 'reference', 'classification_notation_ids_used.csv'),
            desc: 'ClassificationNotation rows in used TermMasterThes rows',
            lookup_on: :classificationnotationid,
            tags: %i[termdata terms reference]
          }
        end

        Kiba::Tms.registry.namespace('con_address') do
          register :to_merge, {
            creator: Kiba::Tms::Jobs::ConAddress::ToMerge,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_address_to_merge.csv'),
            desc: 'Removes rows with no address data, merges in coded values, shapes for CS',
            tags: %i[con con_address],
            lookup_on: :constituentid
          }
          register :for_persons, {
            creator: Kiba::Tms::Jobs::ConAddress::ForPersons,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_address_for_persons.csv'),
            tags: %i[con con_address],
            lookup_on: :person
          }
          register :for_orgs, {
            creator: Kiba::Tms::Jobs::ConAddress::ForOrgs,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_address_for_orgs.csv'),
            tags: %i[con con_address],
            lookup_on: :org
          }
          register :dropping, {
            creator: Kiba::Tms::Jobs::ConAddress::Dropping,
            path: File.join(Kiba::Tms.datadir, 'reports', 'con_address_dropping.csv'),
            tags: %i[con con_address not_migrating reports]
          }
          register :add_counts, {
            creator: Kiba::Tms::Jobs::ConAddress::AddCounts,
            path: File.join(Kiba::Tms.datadir, 'working', 'constituents_with_address_counts.csv'),
            desc: 'Merge in count of how many addresses for each constituent',
            tags: %i[con con_address],
            lookup_on: :constituentid
          }
          register :multi, {
            creator: Kiba::Tms::Jobs::ConAddress::Multi,
            path: File.join(Kiba::Tms.datadir, 'reports', 'constituents_with_multiple_address.csv'),
            tags: %i[con con_address reports],
            dest_special_opts: {
              initial_headers:
              %i[
                 addresscount type termdisplayname rank address_notes
                 addressplace1 addressplace2 city state zipcode addresscountry
                ] }
          }
        end

        Kiba::Tms.registry.namespace('con_alt_names') do
          register :by_constituent, {
            creator: Kiba::Tms::Jobs::ConAltNames::Prep,
            path: File.join(Kiba::Tms.datadir, 'prepped', 'con_alt_names.csv'),
            tags: %i[con prep],
            lookup_on: :constituentid,
            desc: 'Removes rows where altname is the same as linked name in constituents table. If preferred name field = alphasort, move org names from displayname to alphasort.'
          }
          register :categorized_post_cleanup, {
            creator: Kiba::Tms::Jobs::ConAltNames::CategorizedPostCleanup,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_alt_names_categorized_post_cleanup.csv'),
            desc: 'Categorizes prepped data into handling categories using cleanup data',
            tags: %i[con con_alt_names],
            lookup_on: :constituentid
          }
          register :to_merge_org, {
            creator: Kiba::Tms::Jobs::ConAltNames::ToMergeIntoOrg,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_alt_names_to_merge_into_org.csv'),
            desc: 'ConAltNames data to merge into Org Constituents',
            tags: %i[con con_alt_names],
            lookup_on: :org
          }
          register :to_merge_person, {
            creator: Kiba::Tms::Jobs::ConAltNames::ToMergeIntoPerson,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_alt_names_to_merge_into_person.csv'),
            desc: 'ConAltNames data to merge into Person Constituents',
            tags: %i[con con_alt_names],
            lookup_on: :person
          }
          register :dropping, {
            creator: Kiba::Tms::Jobs::ConAltNames::Dropping,
            path: File.join(Kiba::Tms.datadir, 'reports', 'con_alt_names_dropping.csv'),
            desc: 'ConAltNames data being removed from migration',
            tags: %i[con con_alt_names reports not_migrating]
          }
        end

        Kiba::Tms.registry.namespace('con_dates') do
          register :compiled, {
            creator: Kiba::Tms::Jobs::ConDates::Compiled,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_dates_compiled.csv'),
            tags: %i[con condates],
            desc: 'Combines data from constituents__clean_dates and, if used, prep__con_dates; Reduces to unique value per date type, as much as possible',
            dest_special_opts: {
              initial_headers:
              %i[constituentid datasource datedescription date remarks]
            }

          }
          register :prep_compiled, {
            creator: Kiba::Tms::Jobs::ConDates::PrepCompiled,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_dates_compiled_prep.csv'),
            tags: %i[con condates],
            desc: 'Adds warnings to be pulled into review; creates :datenotes; adds CS mappable fields',
            dest_special_opts: {
              initial_headers:
              %i[constituentid datasource warn datedescription date remarks
                 birth_foundation_date death_dissolution_date datenote	]
            }
          }
          register :to_merge, {
            creator: Kiba::Tms::Jobs::ConDates::ToMerge,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_dates_to_merge.csv'),
            tags: %i[con condates],
            desc: 'Keeps only fields from :prep_compiled to be merged back into Constituents.',
            lookup_on: :constituentid
          }
          register :for_review, {
            creator: Kiba::Tms::Jobs::ConDates::ForReview,
            path: File.join(Kiba::Tms.datadir, 'reports', 'con_dates_for_review.csv'),
            tags: %i[con condates reports cleanup],
            dest_special_opts: {
              initial_headers:
              %i[constituentname constituentid datasource warn datedescription date remarks
                 birth_foundation_date death_dissolution_date datenote	]
            }
          }
        end

        Kiba::Tms.registry.namespace('con_email') do
          register :dropping, {
            creator: Kiba::Tms::Jobs::ConEMail::Dropping,
            path: File.join(Kiba::Tms.datadir, 'reports', 'con_email_dropping.csv'),
            tags: %i[con conemail prep not_migrating reports]
          }
          register :for_persons, {
            creator: Kiba::Tms::Jobs::ConEMail::ForPersons,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_email_for_persons.csv'),
            tags: %i[con conemail],
            lookup_on: :person
          }
          register :for_orgs, {
            creator: Kiba::Tms::Jobs::ConEMail::ForOrgs,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_email_for_orgs.csv'),
            tags: %i[con conemail],
            lookup_on: :org
          }
        end

        Kiba::Tms.registry.namespace('con_phones') do
          register :dropping, {
            creator: Kiba::Tms::Jobs::ConPhones::Dropping,
            path: File.join(Kiba::Tms.datadir, 'reports', 'con_phones_dropping.csv'),
            tags: %i[con conphones prep not_migrating reports]
          }
          register :for_persons, {
            creator: Kiba::Tms::Jobs::ConPhones::ForPersons,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'con_phones_for_persons.csv'
            ),
            tags: %i[con conphones],
            lookup_on: :constituentid
          }
          register :for_orgs, {
            creator: Kiba::Tms::Jobs::ConPhones::ForOrgs,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'con_phones_for_orgs.csv'
            ),
            tags: %i[con conphones],
            lookup_on: :constituentid
          }
        end

        Kiba::Tms.registry.namespace('con_xref_details') do
          register :for_accession_lot, {
            creator: Kiba::Tms::Jobs::ConXrefDetails::ForAccessionLot,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_xref_details_for_accession_lot.csv'),
            tags: %i[con_xref_details accession_lot],
            lookup_on: :recordid
          }
          register :for_loans, {
            creator: Kiba::Tms::Jobs::ConXrefDetails::ForLoans,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_xref_details_for_loans.csv'),
            tags: %i[con_xref_details loans],
            lookup_on: :recordid
          }
          register :for_objects, {
            creator: Kiba::Tms::Jobs::ConXrefDetails::ForObjects,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_xref_details_for_objects.csv'),
            tags: %i[con_xref_details objects],
            lookup_on: :recordid
          }
          register :for_registration_sets, {
            creator: Kiba::Tms::Jobs::ConXrefDetails::ForRegistrationSets,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_xref_details_for_registration_sets.csv'),
            tags: %i[con_xref_details registration_sets],
            lookup_on: :recordid
          }
        end

        Kiba::Tms.registry.namespace('con_refs') do
          register :create, {
            creator: Kiba::Tms::Jobs::ConRefs::Create,
            path: File.join(Kiba::Tms.datadir, 'tms', 'ConRefs.csv'),
            tags: %i[con_xrefs]
          }
          register :prep, {
            creator: Kiba::Tms::Jobs::ConRefs::Prep,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_refs_prepped.csv'),
            tags: %i[con_xrefs]
          }
          register :type_mismatch, {
            creator: Kiba::Tms::Jobs::ConRefs::TypeMismatch,
            path: File.join(Kiba::Tms.datadir, 'reports', 'con_refs_type_mismatch.csv'),
            desc: 'Role type values from role, con_xrefs, and con_xref_details do not match',
            tags: %i[con_xrefs]
          }
          register :type_match, {
            creator: Kiba::Tms::Jobs::ConRefs::TypeMatch,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_refs_type_match.csv'),
            desc: 'Role type values from role, con_xrefs, and con_xref_details do match; redundant fields removed',
            tags: %i[con_xrefs]
          }
        end

        Kiba::Tms.registry.namespace('constituents') do
          register :text_entries_merged, {
            creator: Kiba::Tms::Jobs::Constituents::TextEntriesMerged,
            path: File.join(
              Kiba::Tms.datadir,
              'working', 'constituents_text_entries_merged.csv'
            ),
            desc: 'Prepped constituents with text entries merged in. This '\
              'cannot be handled in prep because prep of the TextEntries '\
              'table requires looking up names in prep__constituents',
            tags: %i[con textentries]
          }
          register :prep_clean, {
            creator: Kiba::Tms::Jobs::Constituents::PrepClean,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'constituents_prepped_clean.csv'
            ),
            desc: 'Prepped constituents with name type cleanup merged in',
            tags: %i[con]
          }
          register :by_norm_orig, {
            creator: Kiba::Tms::Jobs::Constituents::Prep,
            path: File.join(Kiba::Tms.datadir, 'prepped', 'constituents.csv'),
            desc: 'Uncleaned con data lookup by norm prefname',
            tags: %i[con],
            lookup_on: :norm
          }
          register :by_norm, {
            creator: Kiba::Tms::Jobs::Constituents::PrepClean,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'constituents_prepped_clean.csv'
            ),
            desc: 'Cleaned con data lookup by norm prefname',
            tags: %i[con],
            lookup_on: :norm
          }
          register :clean_by_norm_orig, {
            creator: Kiba::Tms::Jobs::Constituents::PrepClean,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'constituents_prepped_clean.csv'
            ),
            desc: 'Cleaned con data lookup by origninal/uncleaned norm prefname',
            tags: %i[con],
            lookup_on: :norm
          }
          register :by_nonpref_norm, {
            creator: Kiba::Tms::Jobs::Constituents::ByNonprefNorm,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'constituents_by_nonpref_norm.csv'
            ),
            desc: 'Prepped constituent table lookup by norm form of '\
              'nonpreferred name field',
            tags: %i[con],
            lookup_on: :norm
          }
          register :clean_dates, {
            creator: Kiba::Tms::Jobs::Constituents::CleanDates,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'constituents_clean_dates.csv'
            ),
            desc: 'Just begin/end dates extracted from displaydate, and '\
              'resulting :datenote values, for reconciliation with ConDates, '\
              'if using, or otherwise merging back into Constituents',
            tags: %i[con],
            lookup_on: :constituentid
          }
          register :for_compile, {
            creator: Kiba::Tms::Jobs::Constituents::ForCompile,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'constituents_for_compile.csv'
            ),
            desc: 'Removes fields not needed for NameCompile; removes fields '\
              'with no name data',
            tags: %i[con],
            lookup_on: :combined
          }
          register :duplicates, {
            creator: Kiba::Tms::Jobs::Constituents::Duplicates,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'constituents_duplicates.csv'
            ),
            desc: 'Duplicate constituent data for creating variant name entries',
            tags: %i[con],
            lookup_on: :combined
          }
          register :persons, {
            creator: Kiba::Tms::Jobs::Constituents::Persons,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'constituents_persons.csv'
            ),
            desc: 'Orig (not cleaned up) constituent values mapped to '\
              ':constituenttype or :derivedcontype = Person',
            tags: %i[con],
            lookup_on: :constituentid
          }
          register :orgs, {
            creator: Kiba::Tms::Jobs::Constituents::Orgs,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'constituents_orgs.csv'
            ),
            desc: 'Orig (not cleaned up) constituent values mapped to '\
              ':constituenttype or :derivedcontype = Organization',
            tags: %i[con],
            lookup_on: :constituentid
          }
          register :alt_name_mismatch, {
            creator: Kiba::Tms::Jobs::Constituents::AltNameMismatch,
            path: File.join(
              Kiba::Tms.datadir,
              'reports',
              'constituents_alt_name_mismatch.csv'
            ),
            desc: 'Constituents where value looked up on defaultnameid (in '\
              'con_alt_names table) does not match value of preferred name '\
              'field in constituents table',
            tags: %i[con reports]
          }
          register :alt_names_merged, {
            creator: Kiba::Tms::Jobs::Constituents::AltNamesMerged,
            path: File.join(Kiba::Tms.datadir, 'working', 'constituents_alt_names_merged.csv'),
            desc: 'Constituents with non-default form of name merged in',
            tags: %i[con]
          }
          register :with_type, {
            creator: Kiba::Tms::Jobs::Constituents::WithType,
            path: File.join(Kiba::Tms.datadir, 'reports', 'constituents_with_type.csv'),
            desc: 'Constituents with a constituent type entered',
            tags: %i[con reports]
          }
          register :without_type, {
            creator: Kiba::Tms::Jobs::Constituents::WithoutType,
            path: File.join(Kiba::Tms.datadir, 'working', 'constituents_without_type.csv'),
            desc: 'Constituents without a constituent type entered',
            tags: %i[con]
          }
          register :with_name_data, {
            creator: Kiba::Tms::Jobs::Constituents::WithNameData,
            path: File.join(Kiba::Tms.datadir, 'working', 'constituents_with_name_data.csv'),
            desc: 'Constituents with displayname or alphasort name',
            tags: %i[con]
          }
          register :without_name_data, {
            creator: Kiba::Tms::Jobs::Constituents::WithoutNameData,
            path: File.join(Kiba::Tms.datadir, 'reports', 'constituents_without_name_data.csv'),
            desc: 'Constituents without displayname or alphasort name',
            tags: %i[con reports]
          }
          register :derived_type, {
            creator: Kiba::Tms::Jobs::Constituents::DerivedType,
            path: File.join(Kiba::Tms.datadir, 'reports', 'constituents_with_derived_type.csv'),
            desc: 'Constituents with a derived type',
            tags: %i[con reports]
          }
          register :no_derived_type, {
            creator: Kiba::Tms::Jobs::Constituents::NoDerivedType,
            path: File.join(Kiba::Tms.datadir, 'reports', 'constituents_without_derived_type.csv'),
            desc: 'Constituents without a derived type',
            tags: %i[con reports]
          }
        end

        Kiba::Tms.registry.namespace('linked_lot_acq') do
          register :obj_rows, {
            creator: Kiba::Tms::Jobs::LinkedLotAcq::ObjRows,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'linked_lot_acq__obj_rows.csv'
            ),
            desc: 'All ObjAccession rows to be treated as :linkedlot',
            tags: %i[acquisitions]
          }
          register :rows, {
            creator: Kiba::Tms::Jobs::LinkedLotAcq::Rows,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'linked_lot_acq_rows.csv'
            ),
            desc: ':obj_rows, deduplicated on regsetid',
            tags: %i[acquisitions]
          }
          # register :prep, {
          #   creator: Kiba::Tms::Jobs::LinkedLotAcq::Prep,
          #   path: File.join(Kiba::Tms.datadir, 'working', 'linked_lot_acq.csv'),
          #   tags: %i[acquisitions]
          # }
        end

        Kiba::Tms.registry.namespace('linked_set_acq') do
          register :obj_rows, {
            creator: Kiba::Tms::Jobs::LinkedSetAcq::ObjRows,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'linked_set_acq__obj_rows.csv'
            ),
            desc: 'All ObjAccession rows to be treated as :linkedset',
            tags: %i[acquisitions]
          }
          register :rows, {
            creator: Kiba::Tms::Jobs::LinkedSetAcq::Rows,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'linked_set_acq_rows.csv'
            ),
            desc: ':obj_rows, deduplicated on regsetid',
            tags: %i[acquisitions]
          }
          register :prep, {
            creator: Kiba::Tms::Jobs::LinkedSetAcq::Prep,
            path: File.join(Kiba::Tms.datadir, 'working', 'linked_set_acq.csv'),
            tags: %i[acquisitions],
            lookup_on: :registrationsetid
          }
          register :acq_obj_rel, {
            creator: Kiba::Tms::Jobs::LinkedSetAcq::AcqObjRel,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'linked_set_acq_nhr.csv'
            ),
            tags: %i[acquisitions objects nhr]
          }
          register :object_statuses, {
            creator: Kiba::Tms::Jobs::LinkedSetAcq::ObjectStatuses,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'linked_set_acq_object_statuses.csv'
            ),
            tags: %i[acquisitions],
            lookup_on: :objectid
          }
        end

        Kiba::Tms.registry.namespace('loan_obj_xrefs') do
          register :by_obj, {
            creator: Kiba::Tms::Jobs::LoanObjXrefs::Prep,
            path: File.join(Kiba::Tms.datadir, 'prepped', 'loan_obj_xrefs.csv'),
            tags: %i[loans objects relations],
            lookup_on: :objectid
          }
          register :loanin_obj_lookup, {
            creator: Kiba::Tms::Jobs::LoanObjXrefs::LoaninObjLookup,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'loanin_obj_lookup.csv'
            ),
            tags: %i[loans objects],
            lookup_on: :objectid,
            desc: 'Outputs single field: :objectid'
          }
        end

        Kiba::Tms.registry.namespace('loans') do
          register :in, {
            creator: Kiba::Tms::Jobs::Loans::In,
            path: File.join(Kiba::Tms.datadir, 'working', 'loans_in.csv'),
            desc: 'Loans with :loantype = `loan in`',
            tags: %i[loans loansin],
            lookup_on: :loanid
          }
          register :in_lookup, {
            creator: Kiba::Tms::Jobs::Loans::InLookup,
            path: File.join(Kiba::Tms.datadir, 'working', 'loans_in_lookup.csv'),
            desc: 'Loans with :loantype = `loan in`; does NOT require running '\
              'prep__loans job as a dependency; outputs single field: '\
              ':loanid',
            tags: %i[loans loansin],
            lookup_on: :loanid
          }
          register :out, {
            creator: Kiba::Tms::Jobs::Loans::Out,
            path: File.join(Kiba::Tms.datadir, 'working', 'loans_out.csv'),
            desc: 'Loans with :loantype = `loan out`',
            tags: %i[loans loansout],
            lookup_on: :loanid
          }
          register :unexpected_type, {
            creator: Kiba::Tms::Jobs::Loans::UnexpectedType,
            path: File.join(Kiba::Tms.datadir, 'reports', 'loans_unexpected_type.csv'),
            desc: 'Loans with :loantype not `loan in` or `loan out`. Non-zero means work to do!',
            tags: %i[loans todochk]
          }
        end

        Kiba::Tms.registry.namespace('loansin') do
          register :prep, {
            creator: Kiba::Tms::Jobs::Loansin::Prep,
            path: File.join(Kiba::Tms.datadir, 'working', 'loansin__prep.csv'),
            tags: %i[loans loansin]
          }
          register :cspace, {
            creator: Kiba::Tms::Jobs::Loansin::Cspace,
            path: File.join(Kiba::Tms.datadir, 'working', 'loansin__cspace.csv'),
            tags: %i[loans loansin]
          }
          register :rel_obj, {
            creator: Kiba::Tms::Jobs::Loansin::RelObj,
            path: File.join(Kiba::Tms.datadir, 'working', 'loansin__rel_obj.csv'),
            tags: %i[loans loansin relations]
          }
        end

        Kiba::Tms.registry.namespace('loansout') do
          register :prep, {
            creator: Kiba::Tms::Jobs::Loansout::Prep,
            path: File.join(Kiba::Tms.datadir, 'working', 'loansout__prep.csv'),
            tags: %i[loans loansout]
          }
          register :cspace, {
            creator: Kiba::Tms::Jobs::Loansout::Cspace,
            path: File.join(Kiba::Tms.datadir, 'working', 'loansout__cspace.csv'),
            tags: %i[loans loansout]
          }
          register :rel_obj, {
            creator: Kiba::Tms::Jobs::Loansout::RelObj,
            path: File.join(Kiba::Tms.datadir, 'working', 'loansout__rel_obj.csv'),
            tags: %i[loans loansout relations]
          }
        end

        Kiba::Tms.registry.namespace('locs') do
          register :from_locations, {
            creator: Kiba::Tms::Jobs::Locations::FromLocations,
            path: File.join(Kiba::Tms.datadir, 'working', 'locs_from_locations.csv'),
            desc: 'Locations extracted from TMS Locations',
            tags: %i[locations]
          }
          register :from_obj_locs_temptext, {
            creator: Kiba::Tms::Jobs::Locations::FromObjLocsTemptext,
            path: File.join(Kiba::Tms.datadir, 'working', 'locs_from_obj_locs_temptext.csv'),
            desc: 'Locations created by appending temp text to location id location',
            tags: %i[locations]
          }
          register :compiled_0, {
            creator: Kiba::Tms::Jobs::Locations::Compiled0,
            path: File.join(Kiba::Tms.datadir, 'working', 'locs_compiled_0.csv'),
            desc: 'Locations from different sources, compiled, round 0',
            tags: %i[locations],
          }
          register :compiled_hier_0, {
            creator: Kiba::Tms::Jobs::Locations::CompiledHier0,
            path: File.join(Kiba::Tms.datadir, 'working', 'locs_compiled_hier_0.csv'),
            desc: 'Locations from different sources, compiled, hierarchy levels added, round 0',
            tags: %i[locations]
          }
          register :compiled, {
            creator: Kiba::Tms::Jobs::Locations::Compiled,
            path: File.join(Kiba::Tms.datadir, 'working', 'locs_compiled.csv'),
            desc: 'Locations from different sources, compiled, final',
            tags: %i[locations],
            dest_special_opts: {
              initial_headers:
              %i[
                 usage_ct location_name parent_location storage_location_authority current_location_note address term_source fulllocid
                ] },
            lookup_on: :fulllocid
          }
          register :to_client_0, {
            creator: Kiba::Tms::Jobs::Locations::ToClient0,
            path: File.join(Kiba::Tms.datadir, 'reports', 'location_review_0.csv'),
            desc: 'Locations for client review',
            tags: %i[locations]
          }
        end

        Kiba::Tms.registry.namespace('locclean') do
          %i[local offsite organization].each do |loc_type|
            register loc_type, {
              path: File.join(Kiba::Tms.datadir, 'working', "locations_#{loc_type}.csv"),
              creator: {callee: Kiba::Tms::Jobs::LocsClean::Splitter, args: {type: loc_type}},
              tags: %i[locations],
              lookup_on: :location_name
            }
          end

          Kiba::Tms::Locations.authorities.each do |loc_type|
            register "#{loc_type}_hier".to_sym, {
              path: File.join(Kiba::Tms.datadir, 'working', "locations_#{loc_type}_hier.csv"),
              creator: {callee: Kiba::Tms::Jobs::LocsClean::HierarchyAdder, args: {type: loc_type}},
              tags: %i[locations],
            }
          end

          Kiba::Tms::Locations.authorities.each do |loc_type|
            register "#{loc_type}_cspace".to_sym, {
              path: File.join(Kiba::Tms.datadir, 'working', "locations_#{loc_type}_cspace.csv"),
              creator: {callee: Kiba::Tms::Jobs::LocsClean::Cspace, args: {type: loc_type}},
              tags: %i[locations cspace],
            }
          end

          Kiba::Tms::Locations.authorities.each do |loc_type|
            register "#{loc_type}_hier_cspace".to_sym, {
              path: File.join(Kiba::Tms.datadir, 'cspace', "locations_#{loc_type}_hier.csv"),
              creator: {callee: Kiba::Tms::Jobs::LocsClean::HierCspace, args: {type: loc_type}},
              tags: %i[locations cspace relations],
            }
          end

          register :unknown_types, {
            creator: Kiba::Tms::Jobs::LocsClean::UnknownTypes,
            path: File.join(Kiba::Tms.datadir, 'reports', 'locations_unknown_types.csv'),
            desc: 'Cleaned locations with unrecognized authority type',
            tags: %i[locations reports todochk]
          }
          register :org_lookup, {
            creator: Kiba::Tms::Jobs::LocsClean::OrgLookup,
            path: File.join(Kiba::Tms.datadir, 'working', 'locations_org_lookup.csv'),
            desc: 'Organization locations matched to existing organization termdisplaynames',
            tags: %i[locations orgs]
          }
          register :new_orgs, {
            creator: Kiba::Tms::Jobs::LocsClean::NewOrgs,
            path: File.join(Kiba::Tms.datadir, 'working', 'locations_new_orgs.csv'),
            desc: 'Organization locations that need to be added',
            tags: %i[locations orgs]
          }
        end

        Kiba::Tms.registry.namespace('locclean0') do
          register :prep, {
            creator: Kiba::Tms::Jobs::LocsClean0::Prep,
            path: File.join(Kiba::Tms.datadir, 'working', 'locations_cleaned_0.csv'),
            desc: 'Initial cleaned location data with info-only fields removed',
            tags: %i[locations]
          }
        end

        Kiba::Tms.registry.namespace('lot_num_acq') do
          register :obj_rows, {
            creator: Kiba::Tms::Jobs::LotNumAcq::ObjRows,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'lot_num_acq_obj_rows.csv'
            ),
            desc: 'ObjAccession rows to be processed with :lotnumber approach',
            tags: %i[acquisitions],
            lookup_on: :acquisitionlot
          }
          register :rows, {
            creator: Kiba::Tms::Jobs::LotNumAcq::Rows,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'lot_num_acq_rows.csv'
            ),
            desc: 'ObjAccession rows to be processed with :lotnumber approach '\
              'deduplicated on :acquisitionlot value',
            tags: %i[acquisitions]
          }
          register :prep, {
            creator: Kiba::Tms::Jobs::LotNumAcq::Prep,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'lot_num_acq_prepped.csv'
            ),
            desc: 'ObjAccession rows to be processed with :lotnumber '\
              'approach, prepped',
            tags: %i[acquisitions]
          }
          register :acq_obj_rel, {
            creator: Kiba::Tms::Jobs::LotNumAcq::AcqObjRel,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'lot_num_acq_obj_rel.csv'
            ),
            tags: %i[acquisitions objects nhr]
          }
        end

        Kiba::Tms.registry.namespace('media_files') do
          register :file_names, {
            creator: Kiba::Tms::Jobs::MediaFiles::FileNames,
            path: File.join(Kiba::Tms.datadir, 'reports', 'media_file_names.csv'),
            desc: 'Media file names',
            tags: %i[mediafiles reports]
          }
        end

        Kiba::Tms.registry.namespace('nameclean') do
          register :by_constituentid, {
            creator: Kiba::Tms::Jobs::Names::Cleanup::ByConstituentId,
            path: File.join(Kiba::Tms.datadir, 'working', 'by_constituent_id.csv'),
            desc: 'Lookup authorized form by constituent id. Additional fields: person, org, alphasort, displayname. Person and Org columns contain the normalized form of the constituent name',
            tags: %i[names],
            lookup_on: :constituentid
          }
        end

        Kiba::Tms.registry.namespace('nameclean0') do
          register :prep, {
            creator: Kiba::Tms::Jobs::Names::Cleanup0::Prep,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_cleaned_up.csv'),
            desc: 'First round of client name cleanup merged in; expands fingerprinted fields, removes rows marked skip, normalizes cleaned up forms',
            tags: %i[names],
            lookup_on: :norm
          }
          register :kept, {
            creator: Kiba::Tms::Jobs::Names::Cleanup0::Kept,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_kept.csv'),
            desc: 'Names which are marked to be used as authority terms',
            tags: %i[names],
            lookup_on: :norm
          }
          register :constituents_kept, {
            creator: Kiba::Tms::Jobs::Names::Cleanup0::ConstituentsKept,
            path: File.join(Kiba::Tms.datadir, 'working', 'constituent_names_kept.csv'),
            desc: 'Names with constituent IDs which are marked to be used as authority terms',
            tags: %i[names],
            lookup_on: :norm
          }
          register :orgs_kept, {
            creator: Kiba::Tms::Jobs::Names::Cleanup0::OrgsKept,
            path: File.join(Kiba::Tms.datadir, 'working', 'org_names_kept.csv'),
            desc: 'Organization names which are marked to be used as authority terms',
            tags: %i[names],
            lookup_on: :norm
          }
          register :persons_kept, {
            creator: Kiba::Tms::Jobs::Names::Cleanup0::PersonsKept,
            path: File.join(Kiba::Tms.datadir, 'working', 'person_names_kept.csv'),
            desc: 'Person names which are marked to be used as authority terms',
            tags: %i[names],
            lookup_on: :norm
          }
          register :orgs_not_kept, {
            creator: Kiba::Tms::Jobs::Names::Cleanup0::OrgsNotKept,
            path: File.join(Kiba::Tms.datadir, 'working', 'org_names_not_kept.csv'),
            desc: 'Organization names which are NOT marked to be used as authority terms',
            tags: %i[names],
            lookup_on: :norm
          }
          register :persons_not_kept, {
            creator: Kiba::Tms::Jobs::Names::Cleanup0::PersonsNotKept,
            path: File.join(Kiba::Tms.datadir, 'working', 'person_names_not_kept.csv'),
            desc: 'Person names which are NOT marked to be used as authority terms',
            tags: %i[names],
            lookup_on: :norm
          }
          register :orgs_not_kept_missing_target, {
            creator: Kiba::Tms::Jobs::Names::Cleanup0::OrgsNotKeptMissingTarget,
            path: File.join(Kiba::Tms.datadir, 'reports', 'org_names_not_kept_missing_target.csv'),
            desc: 'Organization names which are NOT marked to be used as authority terms, but have no term to be merged into',
            tags: %i[names]
          }
          register :persons_not_kept_missing_target, {
            creator: Kiba::Tms::Jobs::Names::Cleanup0::PersonsNotKeptMissingTarget,
            path: File.join(Kiba::Tms.datadir, 'reports', 'person_names_not_kept_missing_target.csv'),
            desc: 'Person names which are NOT marked to be used as authority terms, but have no term to be merged into',
            tags: %i[names]
          }
          register :org_duplicates, {
            creator: Kiba::Tms::Jobs::Names::Cleanup0::OrgDuplicates,
            path: File.join(Kiba::Tms.datadir, 'reports', 'org_names_duplicates.csv'),
            desc: 'Organization names which, once normalized, are duplicates',
            tags: %i[names]
          }
          register :persons_duplicates, {
            creator: Kiba::Tms::Jobs::Names::Cleanup0::PersonsDuplicates,
            path: File.join(Kiba::Tms.datadir, 'reports', 'person_names_duplicates.csv'),
            desc: 'Person names which, once normalized, are duplicates',
            tags: %i[names]
          }
        end

        Kiba::Tms.registry.namespace('name_compile') do
          register :raw, {
            creator: Kiba::Tms::Jobs::NameCompile::Raw,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_raw.csv'),
            desc: 'Initial compiled terms - adds fingerprint field for main name deduplication merge',
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
                ] },
            lookup_on: :norm
          }
          register :worksheet, {
            creator: Kiba::Tms::Jobs::NameCompile::Worksheet,
            path: File.join(Kiba::Tms.datadir, 'reports', 'names_worksheet.csv'),
            desc: Proc.new{ Kiba::Tms::Jobs::NameCompile::Worksheet.desc },
            tags: %i[names],
            dest_special_opts: {
              initial_headers:
              %i[
                 authority name relation_type variant_term variant_qualifier related_term related_role
                 note_text birth_foundation_date death_dissolution_date datenote
                 salutation nametitle firstname middlename lastname suffix
                 biography code nationality school remarks culturegroup
                 constituentid termsource fp sort
                ] }
          }
          register :main_duplicates, {
            creator: Kiba::Tms::Jobs::NameCompile::MainDuplicates,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_main_duplicates.csv'),
            desc: 'Only main terms from initial compiled terms flagged as duplicates',
            tags: %i[names],
            lookup_on: :fingerprint
          }
          register :typed_main_duplicates, {
            creator: Kiba::Tms::Jobs::NameCompile::TypedMainDuplicates,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_typed_main_duplicates.csv'),
            desc: 'Only typed (person/org) main terms from initial compiled terms flagged as duplicates',
            tags: %i[names],
            lookup_on: :fingerprint
          }
          register :untyped_main_duplicates, {
            creator: Kiba::Tms::Jobs::NameCompile::UntypedMainDuplicates,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_untyped_main_duplicates.csv'),
            desc: 'Only untyped main terms from initial compiled terms flagged as duplicates',
            tags: %i[names],
            lookup_on: :fingerprint
          }
          register :variant_duplicates, {
            creator: Kiba::Tms::Jobs::NameCompile::VariantDuplicates,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_variant_duplicates.csv'),
            desc: 'Only variant terms from initial compiled terms flagged as duplicates',
            tags: %i[names],
            lookup_on: :fingerprint
          }
          register :related_duplicates, {
            creator: Kiba::Tms::Jobs::NameCompile::RelatedDuplicates,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_related_duplicates.csv'),
            desc: 'Only related terms from initial compiled terms flagged as duplicates',
            tags: %i[names],
            lookup_on: :fingerprint
          }
          register :note_duplicates, {
            creator: Kiba::Tms::Jobs::NameCompile::NoteDuplicates,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_note_duplicates.csv'),
            desc: 'Only note terms from initial compiled terms flagged as duplicates',
            tags: %i[names],
            lookup_on: :fingerprint
          }
          register :duplicates_flagged, {
            creator: Kiba::Tms::Jobs::NameCompile::DuplicatesFlagged,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_duplicates_flagged.csv'),
            desc: Kiba::Tms::Jobs::NameCompile::DuplicatesFlagged.send(:desc),
            tags: %i[names],
            dest_special_opts: {initial_headers: %i[sort]}
          }
          register :unique, {
            creator: Kiba::Tms::Jobs::NameCompile::Unique,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_unique.csv'),
            desc: Kiba::Tms::Jobs::NameCompile::Unique.send(:desc),
            tags: %i[names],
            dest_special_opts: {initial_headers: %i[sort]}
          }
          register :from_con_org_plain, {
            creator: Kiba::Tms::Jobs::NameCompile::FromConOrgPlain,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_con_org_plain.csv'),
            desc: 'Org MAIN TERMS from Constituents',
            tags: %i[names constituents]
          }
          register :from_con_org_with_inst, {
            creator: Kiba::Tms::Jobs::NameCompile::FromConOrgWithInst,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_con_org_with_inst.csv'),
            desc: 'From Constituents orgs with institution field',
            tags: %i[names constituents]
          }
          register :from_con_org_with_name_parts, {
            creator: Kiba::Tms::Jobs::NameCompile::FromConOrgWithNameParts,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_con_org_with_name_parts.csv'),
            desc: 'From Constituents orgs with multipe core name detail elements OR (a single core name detail element AND a position value)',
            tags: %i[names constituents]
          }
          register :from_con_org_with_single_name_part_no_position, {
            creator: Kiba::Tms::Jobs::NameCompile::FromConOrgWithSingleNamePartNoPosition,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_con_org_with_single_name_part_no_position.csv'),
            desc: 'From Constituents orgs with a single core name detail element, and no position value',
            tags: %i[names constituents]
          }
          register :from_con_person_plain, {
            creator: Kiba::Tms::Jobs::NameCompile::FromConPersonPlain,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_con_person_plain.csv'),
            desc: 'Person MAIN TERMS from Constituents',
            tags: %i[names constituents]
          }
          register :from_con_person_with_inst, {
            creator: Kiba::Tms::Jobs::NameCompile::FromConPersonWithInst,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_con_person_with_inst.csv'),
            desc: 'From Constituents persons with institution value',
            tags: %i[names constituents]
          }
          register :from_con_person_with_position_no_inst, {
            creator: Kiba::Tms::Jobs::NameCompile::FromConPersonWithPositionNoInst,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_con_person_with_position_no_inst.csv'),
            desc: 'From Constituents persons with position value but no institution value',
            tags: %i[names constituents]
          }
          register :from_can_typematch_alt_established, {
            creator: Kiba::Tms::Jobs::NameCompile::FromCanTypematchAltEstablished,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_can_typematch_alt_established.csv'),
            desc: 'From ConAltNames where type is same for main and alt name, and alt name matches an established constituent name',
            tags: %i[names con_alt_names]
          }
          register :from_can_main_person_alt_org_established, {
            creator: Kiba::Tms::Jobs::NameCompile::FromCanMainPersonAltOrgEstablished,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_can_main_person_alt_org_established.csv'),
            desc: 'From ConAltNames where main name is Person, and alt name matches an established organization name',
            tags: %i[names con_alt_names]
          }
          register :from_can_main_org_alt_person_established, {
            creator: Kiba::Tms::Jobs::NameCompile::FromCanMainOrgAltPersonEstablished,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_can_main_org_alt_person_established.csv'),
            desc: 'From ConAltNames where main name is Organization, and alt name matches an established person name',
            tags: %i[names con_alt_names]
          }
          register :from_can_typematch, {
            creator: Kiba::Tms::Jobs::NameCompile::FromCanTypematch,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_can_typematch.csv'),
            desc: 'Adds :treatment field to rows from ConAltNames where main and alt name types match AND altname is not established as separate constituent name',
            tags: %i[names con_alt_names]
          }
          register :from_can_typematch_variant, {
            creator: Kiba::Tms::Jobs::NameCompile::FromCanTypematchVariant,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_can_typematch_variant.csv'),
            desc: 'name_compile__from_can_typematch variants',
            tags: %i[names con_alt_names]
          }
          register :from_can_typematch_separate, {
            creator: Kiba::Tms::Jobs::NameCompile::FromCanTypematchSeparate,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_can_typematch_separate.csv'),
            desc: 'name_compile__from_can_typematch separates',
            tags: %i[names con_alt_names]
          }
          register :from_can_typematch_separate_names, {
            creator: Kiba::Tms::Jobs::NameCompile::FromCanTypematchSeparateNames,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_can_typematch_separate_names.csv'),
            desc: 'output main name rows from alt names in name_compile__from_can_typematch separates',
            tags: %i[names con_alt_names]
          }
          register :from_can_typematch_separate_notes, {
            creator: Kiba::Tms::Jobs::NameCompile::FromCanTypematchSeparateNotes,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_can_typematch_separate_notes.csv'),
            desc: 'output related name note rows from alt names in name_compile__from_can_typematch separates',
            tags: %i[names con_alt_names]
          }
          register :from_can_typemismatch_main_person, {
            creator: Kiba::Tms::Jobs::NameCompile::FromCanTypemismatchMainPerson,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_can_typemismatch_main_person.csv'),
            desc: 'ConAltNames rows where altname is not established, alt name type is Organization, and main name type is Person',
            tags: %i[names con_alt_names]
          }
          register :from_can_typemismatch_main_org, {
            creator: Kiba::Tms::Jobs::NameCompile::FromCanTypemismatchMainOrg,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_can_typemismatch_main_org.csv'),
            desc: 'ConAltNames rows where altname is not established, alt name type is Person, and main name type is Organization',
            tags: %i[names con_alt_names]
          }
          register :from_can_no_altnametype, {
            creator: Kiba::Tms::Jobs::NameCompile::FromCanNoAltnametype,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled_from_can_no_altnametype.csv'),
            desc: 'ConAltNames rows where altname is not established, alt name type is empty',
            tags: %i[names con_alt_names]
          }
          register :from_assoc_parents_for_con, {
            creator: Kiba::Tms::Jobs::NameCompile::FromAssocParentsForCon,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_assoc_parents_for_con.csv'),
            desc: 'Names extracted from AssocParents (for constituents) table',
            tags: %i[names assoc_parents]
          }
          register :from_reference_master, {
            creator: Kiba::Tms::Jobs::NameCompile::FromReferenceMaster,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_reference_master.csv'),
            desc: 'Names extracted from reference_master table',
            tags: %i[names reference_master]
          }
          register :from_uncontrolled_name_tables, {
            creator: Kiba::Tms::Jobs::NameCompile::FromUncontrolledNameTables,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'names_from_uncontrolled_name_tables.csv'
            ),
            desc: 'Names from uncontrolled fields in tables, compiled, '\
              'normalized, termsource changed to "Uncontrolled field '\
              'value. Normalized value is in :constituentid field',
            tags: %i[names],
            lookup_on: :constituentid
          }
          register :variants_from_duplicate_constituents, {
            creator: Kiba::Tms::Jobs::NameCompile::VariantsFromDuplicateConstituents,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_variants_from_duplicate_constituents.csv'),
            desc: 'Variant names from duplicate (after normalization!) constituent names that are not literally duplicates',
            tags: %i[names constituents]
          }
        end

        Kiba::Tms.registry.namespace('name_type_cleanup') do
          register :from_base_data, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::FromBaseData,
            path: File.join(Kiba::Tms.datadir, 'working', 'name_type_cleanup_from_base_data.csv'),
            desc: 'Data from main/base data source used to create Name Type review/cleanup worksheet',
            tags: %i[names cleanup]
          }
          register :worksheet, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::Worksheet,
            path: File.join(
              Kiba::Tms.datadir,
              'to_client',
              'name_type_cleanup_worksheet.csv'
            ),
            tags: %i[names cleanup],
            dest_special_opts: {initial_headers: Tms::NameTypeCleanup.initial_headers}
          }
          register :worksheet_prev_version, {
            path: File.join(
              Kiba::Tms.datadir,
              'to_client',
              'name_type_cleanup_worksheet_prev.csv'
            ),
            supplied: true,
            lookup_on: :constituentid
          }
          register :worksheet_completed, {
            path: File.join(
              Tms.datadir,
              'supplied',
              'nametype_cleanup_worksheet_complete.csv'
            ),
            desc: 'Completed nametype cleanup worksheet',
            tags: %i[names cleanup],
            supplied: true,
            lookup_on: :constituentid
          }
          register :corrected_orgs, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::CorrectedOrgs,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'name_type_cleanup_corrected_orgs.csv'
            ),
            tags: %i[names cleanup],
            desc: 'For merge into source data tables',
            lookup_on: :orignorm
          }
          register :corrected_persons, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::CorrectedPersons,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'name_type_cleanup_corrected_persons.csv'
            ),
            tags: %i[names cleanup],
            desc: 'For merge into source data tables',
            lookup_on: :orignorm
          }
          register :returned_prep, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::ReturnedPrep,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'name_type_cleanup_returned_prep.csv'
            ),
            tags: %i[names cleanup],
            desc: 'Prepares supplied cleanup spreadsheet for use in '\
              'overlaying cleaned up data and generating phase 2 name '\
              'cleanup worksheet'
          }
          ntc_supp_path = Tms.registry
            .resolve(:name_type_cleanup__worksheet_completed)[:path]
            .to_s
          register :convert_returned_to_uncontrolled, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::ConvertReturnedToUncontrolled,
            path: ntc_supp_path.sub('.csv', '_converted.csv'),
            tags: %i[names cleanup]
          }
          register :for_con_alt_names, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::ForConAltNames,
            path: File.join(Kiba::Tms.datadir, 'working', 'name_type_cleanup_for_con_alt_names.csv'),
            tags: %i[names cleanup],
            lookup_on: :altnameid
          }
          register :for_constituents, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::ForConstituents,
            path: File.join(Kiba::Tms.datadir, 'working', 'name_type_cleanup_for_constituents.csv'),
            tags: %i[names cleanup],
            lookup_on: :constituentid
          }
          register :for_con_org_with_name_parts, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::ForConOrgWithNameParts,
            path: File.join(Kiba::Tms.datadir, 'working', 'name_type_cleanup_for_con_org_with_name_parts.csv'),
            tags: %i[names cleanup],
            lookup_on: :constituentid
          }
          register :for_con_person_with_inst, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::ForConPersonWithInst,
            path: File.join(Kiba::Tms.datadir, 'working', 'name_type_cleanup_for_con_person_with_inst.csv'),
            tags: %i[names cleanup],
            lookup_on: :constituentid
          }
          register :for_uncontrolled_name_tables, {
            creator: Kiba::Tms::Jobs::NameTypeCleanup::ForUncontrolledNameTables,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'name_type_cleanup_for_uncontrolled_tables.csv'
            ),
            tags: %i[names cleanup],
            lookup_on: :constituentid          }
        end

        Kiba::Tms.registry.namespace('names') do
          register :compiled, {
            creator: Kiba::Tms::Jobs::Names::CompiledData,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_compiled.csv'),
            desc: 'Compiled names',
            tags: %i[names],
            dest_special_opts: {
              initial_headers:
              %i[
                 termsource normalized_form approx_normalized duplicate inconsistent_org_names missing_last_name
                 migration_action constituenttype preferred_name_form variant_name_form alt_names
                 institution contact_person contact_role
                 salutation nametitle firstname middlename lastname suffix
                 begindateiso enddateiso nationality culturegroup school
                 biography remarks
                 approved active isstaff is_private_collector code
                ] }
          }
          register :prep_map_by_norm, {
            creator: Kiba::Tms::Jobs::Names::PrepMapByNorm,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'allnames_prep_map_by_norm.csv'
            ),
            desc: 'Simplifies :name_compile__unique to only normalized '\
              ':contype, :name, and :norm values, where :norm is the '\
              'normalized ORIG value of the name',
            tags: %i[names],
            lookup_on: :norm
          }
          register :map_by_norm, {
            creator: Kiba::Tms::Jobs::Names::MapByNorm,
            path: File.join(Kiba::Tms.datadir, 'working', 'allnames_map_by_norm.csv'),
            desc: 'With lookup on normalized version of original name value (i.e. '\
              'from any table, not controlled by constituentid), gives '\
              '`:person` and `:organization` column from which to merge '\
              'authorized form of name',
            tags: %i[names],
            lookup_on: :norm
          }
          register :by_constituentid, {
            creator: Kiba::Tms::Jobs::Names::ByConstituentid,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'names_by_constituentid.csv'
            ),
            desc: Proc.new{ Kiba::Tms::Jobs::Names::ByConstituentid.desc },
            tags: %i[names],
            lookup_on: :constituentid
          }
          register :orgs, {
            creator: Kiba::Tms::Jobs::Names::Orgs,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'names_orgs.csv'
            ),
            tags: %i[names],
            lookup_on: :constituentid
          }
          register :flagged_duplicates, {
            creator: Kiba::Tms::Jobs::Names::CompiledDataDuplicatesFlagged,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents_flagged_duplicates.csv'),
            desc: 'Names extracted from constituents table and flagged as duplicates',
            tags: %i[names con],
            lookup_on: :norm
          }
          register :initial_compile, {
            creator: Kiba::Tms::Jobs::Names::CompiledDataRaw,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents_initial_compile.csv'),
            desc: 'Names extracted from constituents table and other sources, with only subsequent duplicates flagged',
            tags: %i[names con]
          }
          register :from_constituents, {
            creator: Kiba::Tms::Jobs::Names::FromConstituents,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents.csv'),
            desc: 'Names extracted from constituents table',
            tags: %i[names con]
          }
          register :from_constituents_orgs_from_persons, {
            creator: Kiba::Tms::Jobs::Names::OrgsFromConstituentPersons,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents_orgs_from_persons.csv'),
            desc: 'Names extracted from institution field of Person constituents',
            tags: %i[names con]
          }
          register :from_constituents_persons_from_orgs, {
            creator: Kiba::Tms::Jobs::Names::PersonsFromConstituentOrgs,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents_persons_from_orgs.csv'),
            desc: 'Names extracted from Organization constituents when the name part values are populated',
            tags: %i[names con]
          }
          register :from_loans, {
            creator: Kiba::Tms::Jobs::Names::FromLoans,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_loans.csv'),
            desc: 'Names extracted from loans table',
            tags: %i[names loans]
          }
          register :from_loc_approvers, {
            creator: Kiba::Tms::Jobs::Names::FromLocApprovers,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_loc_approvers.csv'),
            desc: 'Names extracted from LocApprovers table',
            tags: %i[names loc_approvers]
          }
          register :from_loc_handlers, {
            creator: Kiba::Tms::Jobs::Names::FromLocHandlers,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_loc_handlers.csv'),
            desc: 'Names extracted from LocHandlers table',
            tags: %i[names loc_handlers]
          }
          register :from_obj_accession, {
            creator: Kiba::Tms::Jobs::Names::FromObjAccession,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_obj_accession.csv'),
            desc: 'Names extracted from obj_accession table',
            tags: %i[names obj_accession]
          }
          register :from_obj_incoming, {
            creator: Kiba::Tms::Jobs::Names::FromObjIncoming,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_obj_incoming.csv'),
            desc: 'Names extracted from obj_incoming table',
            tags: %i[names obj_incoming]
          }
          register :from_obj_locations, {
            creator: Kiba::Tms::Jobs::Names::FromObjLocations,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_obj_locations.csv'),
            desc: 'Names extracted from obj_locations table',
            tags: %i[names obj_locations]
          }
          register :from_reference_master, {
            creator: Kiba::Tms::Jobs::Names::FromReferenceMaster,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_reference_master.csv'),
            desc: 'Names extracted from reference_master table',
            tags: %i[names reference_master]
          }
          register :from_assoc_parents_for_con, {
            creator: Kiba::Tms::Jobs::Names::FromAssocParentsForCon,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_assoc_parents_for_con.csv'),
            desc: 'Names extracted from AssocParents (for constituents) table',
            tags: %i[names assoc_parents]
          }
        end

        Kiba::Tms.registry.namespace('obj_accession') do
          register :in_migration, {
            creator: Kiba::Tms::Jobs::ObjAccession::InMigration,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'obj_accession_in_migration.csv'
            ),
            tags: %i[objaccession setup],
            desc: 'Removes rows for objects linked to loansin, if configured '\
              'to do so. Otherwise passes through all rows.'
          }
          register :linked_lot, {
            creator: Kiba::Tms::Jobs::ObjAccession::LinkedLot,
            path: File.join(Kiba::Tms.datadir, 'working', 'obj_accession_linked_lot.csv'),
            tags: %i[objaccession setup],
            desc: 'Rows from which acquisitions will be created using LinkedLot approach'
          }
          register :linked_set, {
            creator: Kiba::Tms::Jobs::ObjAccession::LinkedSet,
            path: File.join(Kiba::Tms.datadir, 'working', 'obj_accession_linked_set.csv'),
            tags: %i[objaccession setup],
            desc: 'Rows from which acquisitions will be created using LinkedSet approach'
          }
          register :lot_number, {
            creator: Kiba::Tms::Jobs::ObjAccession::LotNumber,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'obj_accession_lot_number.csv'
            ),
            tags: %i[objaccession setup],
            desc: 'Rows from which acquisitions will be created using '\
              'LotNumber approach'
          }
          register :acq_number, {
            creator: Kiba::Tms::Jobs::ObjAccession::AcqNumber,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'obj_accession_acq_number.csv'
            ),
            tags: %i[objaccession setup],
            desc: 'Rows from which acquisitions will be created using '\
              'AcqNumber approach'
          }
          register :one_to_one, {
            creator: Kiba::Tms::Jobs::ObjAccession::OneToOne,
            path: File.join(Kiba::Tms.datadir, 'working', 'obj_accession_one_to_one.csv'),
            tags: %i[objaccession setup],
            desc: 'Rows from which acquisitions will be created using OneToOne approach'
          }
        end

        Kiba::Tms.registry.namespace('obj_components') do
          register :with_object_numbers, {
            desc: %q{Merges in the human-readable :objectnumber value for each row; Flags "top objects", i.e. not separate components, i.e. :objectnumber = :componentnumber; Adds :existingobject field, which, if populated, means there is an object in Objects table with the same ID as the component (this is expected for "top objects" but not other rows.},
            creator: Kiba::Tms::Jobs::ObjComponents::WithObjectNumbers,
            path: File.join(Kiba::Tms.datadir, 'reports', 'obj_components_with_object_numbers.csv'),
            tags: %i[obj_components reports cleanup],
            dest_special_opts: {
              initial_headers:
              %i[
                 parentobjectnumber componentnumber is_top_object problemcomponent existingobject duplicate
                 componentname parentname parenttitle
                 physdesc parentdesc
                 component_type objcompstatus active
                 physdesc
                ] },
            lookup_on: :objectid
          }
          register :actual_components, {
            creator: Kiba::Tms::Jobs::ObjComponents::ActualComponents,
            path: File.join(Kiba::Tms.datadir, 'working', 'obj_components_actual.csv'),
            tags: %i[obj_components],
            lookup_on: :componentid
          }
          register :parent_objects, {
            creator: Kiba::Tms::Jobs::ObjComponents::ParentObjects,
            path: File.join(Kiba::Tms.datadir, 'working', 'obj_components_parent_objects.csv'),
            tags: %i[obj_components],
            lookup_on: :componentid
          }
          register :objects, {
            creator: Kiba::Tms::Jobs::ObjComponents::Objects,
            path: File.join(Kiba::Tms.datadir, 'working', 'obj_components_objects.csv'),
            tags: %i[obj_components objects],
            desc: 'Converts rows from :actual_components to object records'
          }
        end

        Kiba::Tms.registry.namespace('obj_incoming') do
          register :for_initial_review, {
            creator: Kiba::Tms::Jobs::ObjIncoming::ForInitialReview,
            path: File.join(Kiba::Tms.datadir, 'reports', 'obj_incoming_initial_review.csv'),
            tags: %i[obj_incoming reports],
            desc: 'Merges object number from object table into prepped obj_incoming table',
            dest_special_opts: {
              initial_headers: %i[objincomingid objectnumber] }
          }
        end

        Kiba::Tms.registry.namespace('obj_locations') do
          register :location_names_merged, {
            creator: Kiba::Tms::Jobs::ObjLocations::LocationNamesMerged,
            path: File.join(Kiba::Tms.datadir, 'working', 'obj_locations_location_names_merged.csv'),
            tags: %i[obj_locations],
            desc: 'Merges location names (using fulllocid) into location, prevloc, nextloc, and scheduled loc fields',
            lookup_on: :objectnumber
          }
          register :fulllocid_lookup, {
            creator: Kiba::Tms::Jobs::ObjLocations::FulllocidLookup,
            path: File.join(Kiba::Tms.datadir, 'working', 'obj_locations_by_fulllocid.csv'),
            tags: %i[obj_locations],
            desc: 'Deletes everything else. Used to get counts of location usages',
            lookup_on: :fulllocid
          }
          register :not_matching_components, {
            creator: Kiba::Tms::Jobs::ObjLocations::NotMatchingComponents,
            path: File.join(Kiba::Tms.datadir, 'reports', 'obj_locations_not_matching_obj_components.csv'),
            tags: %i[obj_locations obj_components reports]
          }
          register :flag_not_matching_locations, {
            creator: Kiba::Tms::Jobs::ObjLocations::FlagNotMatchingLocations,
            path: File.join(Kiba::Tms.datadir, 'working', 'obj_locations_flag_not_matching_locations.csv'),
            tags: %i[obj_locations],
            dest_special_opts: {
              initial_headers: %i[no_loc_data action] },
          }
          register :prev_next_sched_loc_merge, {
            creator: Kiba::Tms::Jobs::ObjLocations::PrevNextSchedLocMerge,
            path: File.join(Kiba::Tms.datadir, 'working', 'obj_locations_prev_next_sched_merged.csv'),
            tags: %i[obj_locations obj_components reports]
          }
        end

        Kiba::Tms.registry.namespace('obj_titles') do
          register :note_review, {
            creator: Kiba::Tms::Jobs::ObjTitles::NoteReview,
            path: File.join(Kiba::Tms.datadir, 'reports', 'obj_titles_note_review.csv'),
            desc: 'Object title notes for client review/cleanup',
            tags: %i[obj_titles objects postmigcleanup]
          }
        end

        Kiba::Tms.registry.namespace('objecthierarchy') do
          register :from_obj_components, {
            creator: Kiba::Tms::Jobs::Objecthierarchy::FromObjComponents,
            path: File.join(Kiba::Tms.datadir, 'working', 'objecthierarchy_from_obj_components.csv'),
            tags: %i[objecthierarchy obj_components]
          }
        end

        Kiba::Tms.registry.namespace('objects') do
          register :by_number, {
            creator: Kiba::Tms::Jobs::Objects::ByNumber,
            path: File.join(Kiba::Tms.datadir, 'working', 'objects_by_number.csv'),
            desc: 'Original TMS Objects table rows, lookedup by :objectnumber',
            lookup_on: :objectnumber,
            tags: %i[objects]
          }
          register :number_lookup, {
            path: File.join(
              Kiba::Tms.datadir,
              'prepped',
              'object_number_lookup.csv'
            ),
            creator: Kiba::Tms::Jobs::Objects::NumberLookup,
            desc: 'Just id and objectnumber, retrievable by id',
            lookup_on: :objectid,
            tags: %i[objects]
          }
          register :loan_in_creditlines, {
            creator: Kiba::Tms::Jobs::Objects::LoanInCreditlines,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'loan_in_creditlines.csv'
            ),
            tags: %i[objects loansin],
            desc: ':creditline values for objects linked to loansin',
            lookup_on: :objectid
          }
          register :classification_report, {
            path: File.join(
              Kiba::Tms.datadir,
              'reports',
              'obj_title_name_class.csv'
            ),
            creator: Kiba::Tms::Jobs::Objects::ClassificationReport,
            desc: 'Object number, title, objectname, and classification '\
              'values for client review/decision making',
            tags: %i[objects]
          }
        end

        Kiba::Tms.registry.namespace('one_to_one_acq') do
          register :obj_rows, {
            creator: Kiba::Tms::Jobs::OneToOneAcq::ObjRows,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'one_to_one_acq_obj_rows.csv'
            ),
            desc: 'ObjAccession rows to be processed with :onetoone approach',
            tags: %i[acquisitions]
          }
          register :prep, {
            creator: Kiba::Tms::Jobs::OneToOneAcq::Prep,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'one_to_one_acq_prepped.csv'
            ),
            desc: 'ObjAccession rows to be processed with :onetoone '\
              'approach, prepped',
            tags: %i[acquisitions]
          }
          register :acq_obj_rel, {
            creator: Kiba::Tms::Jobs::OneToOneAcq::AcqObjRel,
            path: File.join(
              Kiba::Tms.datadir,
              'working',
              'one_to_one_acq_nhr.csv'
            ),
            tags: %i[acquisitions objects nhr]
          }
        end

        Kiba::Tms.registry.namespace('orgs') do
          register :by_constituentid, {
            creator: Kiba::Tms::Jobs::Orgs::ByConstituentId,
            path: File.join(Kiba::Tms.datadir, 'working', 'orgs_by_constituent_id.csv'),
            desc: 'Org authority values lookup by constituentid',
            lookup_on: :fp_constituentid,
            tags: %i[orgs]
          }
          register :by_norm, {
            creator: Kiba::Tms::Jobs::Orgs::ByNorm,
            path: File.join(Kiba::Tms.datadir, 'working', 'orgs_by_norm.csv'),
            desc: 'Org authority values lookup by normalized value',
            lookup_on: :norm,
            tags: %i[orgs]
          }
          register :cspace, {
            creator: Kiba::Tms::Jobs::Orgs::Cspace,
            path: File.join(Kiba::Tms.datadir, 'working', 'orgs_for_cspace.csv'),
            tags: %i[orgs cspace],
            dest_special_opts: {initial_headers: %i[termdisplayname]},
          }
          register :brief, {
            creator: Kiba::Tms::Jobs::Orgs::Brief,
            path: File.join(Kiba::Tms.datadir, 'cs', 'orgs_brief.csv'),
            tags: %i[orgs cspace],
            desc: 'Only termdisplayname values, for bootstrap ingests'
          }
        end

        Kiba::Tms.registry.namespace('org_contacts') do
          register :prep, {
            creator: Kiba::Tms::Jobs::OrgContacts::Prep,
            path: File.join(Kiba::Tms.datadir, 'working', 'org_contacts_prepped.csv'),
            tags: %i[orgs cspace],
            dest_special_opts: {initial_headers: %i[norm contact_person contact_norm merge_contact contact_role]},
          }
          register :without_person, {
            creator: Kiba::Tms::Jobs::OrgContacts::WithoutPerson,
            path: File.join(Kiba::Tms.datadir, 'reports', 'org_contacts_without_person.csv'),
            tags: %i[orgs cspace reports]
          }
          register :to_merge, {
            creator: Kiba::Tms::Jobs::OrgContacts::ToMerge,
            path: File.join(Kiba::Tms.datadir, 'working', 'org_contacts_to_merge.csv'),
            tags: %i[orgs cspace],
            lookup_on: :norm
          }
        end

        Kiba::Tms.registry.namespace('persons') do
          register :by_constituentid, {
            creator: Kiba::Tms::Jobs::Persons::ByConstituentId,
            path: File.join(Kiba::Tms.datadir, 'working', 'persons_by_constituent_id.csv'),
            desc: 'Person authority values lookup by constituentid',
            lookup_on: :fp_constituentid,
            tags: %i[persons]
          }
          register :by_norm, {
            creator: Kiba::Tms::Jobs::Persons::ByNorm,
            path: File.join(Kiba::Tms.datadir, 'working', 'persons_by_norm.csv'),
            desc: 'Person authority values lookup by normalized value',
            lookup_on: :norm,
            tags: %i[persons]
          }
          register :cspace, {
            creator: Kiba::Tms::Jobs::Persons::Cspace,
            path: File.join(Kiba::Tms.datadir, 'working', 'persons_for_cspace.csv'),
            tags: %i[persons cspace],
            dest_special_opts: {initial_headers: %i[termdisplayname]},
          }
          register :brief, {
            creator: Kiba::Tms::Jobs::Persons::Brief,
            path: File.join(Kiba::Tms.datadir, 'cs', 'persons_brief.csv'),
            tags: %i[persons cspace],
            desc: 'Only termdisplayname values, for bootstrap ingests'
          }
        end

        Kiba::Tms.registry.namespace('registration_sets') do
          register :for_ingest, {
            creator: Kiba::Tms::Jobs::RegistrationSets::ForIngest,
            path: File.join(Kiba::Tms.datadir, 'working', 'reg_set_for_ingest.csv'),
            desc: 'Acquisitions for ingest, derived from RegSets. RegSet id removed.',
            tags: %i[acquisitions]
          }
          register :not_linked, {
            creator: Kiba::Tms::Jobs::RegistrationSets::NotLinked,
            path: File.join(Kiba::Tms.datadir, 'reports', 'reg_sets_not_linked.csv'),
            desc: 'RegistrationSet rows not linked to objects in ObjAccession',
            tags: %i[acquisitions]
          }
          register :obj_rels, {
            creator: Kiba::Tms::Jobs::RegistrationSets::ObjRels,
            path: File.join(Kiba::Tms.datadir, 'working', 'reg_set_acq_obj_rels.csv'),
            tags: %i[nhr acquisitions objects]
          }
        end

        Kiba::Tms.registry.namespace('status_flags') do
          register :new_tables, {
            creator: Kiba::Tms::Jobs::StatusFlags::NewTables,
            path: File.join(Kiba::Tms.datadir, 'reports', 'status_flags_new_tables.csv'),
            desc: 'Status flags for merge into tables we do not have set up yet. Non-zero count means work to do!',
            tags: %i[status_flags todochk]
          }
        end

        Kiba::Tms.registry.namespace('terms') do
          register :used_in_xrefs, {
            creator: Kiba::Tms::Jobs::Terms::UsedInXrefs,
            path: File.join(Kiba::Tms.datadir, 'reference', 'terms_used_in_xrefs.csv'),
            desc: 'Terms table rows for term IDs used in ThesXrefs',
            lookup_on: :termid,
            tags: %i[termdata terms reference]
          }
          register :used_row_data, {
            creator: Kiba::Tms::Jobs::Terms::UsedRowData,
            path: File.join(Kiba::Tms.datadir, 'reference', 'terms_used_row_data.csv'),
            desc: 'All Terms rows having termmasterid that appears in Terms row used in ThesXrefs. (Allowing merging of alternate terms, etc.)',
            lookup_on: :termid,
            tags: %i[termdata terms reference]
          }
          register :preferred, {
            creator: Kiba::Tms::Jobs::Terms::Preferred,
            path: File.join(Kiba::Tms.datadir, 'working', 'terms_preferred.csv'),
            lookup_on: :termid,
            tags: %i[termdata terms]
          }
        end

        Kiba::Tms.registry.namespace('term_master_thes') do
          register :used_in_xrefs, {
            creator: Kiba::Tms::Jobs::TermMasterThes::UsedInXrefs,
            path: File.join(Kiba::Tms.datadir, 'reference', 'term_master_thes_used_in_xrefs.csv'),
            desc: 'TermMasterThes table rows referenced by Terms referenced in ThesXrefs',
            lookup_on: :termmasterid,
            tags: %i[termdata terms reference]
          }
        end

        Kiba::Tms.registry.namespace('text_entries') do

          register :for_reference_master, {
            creator: Kiba::Tms::Jobs::TextEntries::ForReferenceMaster,
            path: File.join(Kiba::Tms.datadir, 'working', 'text_entries_for_reference_master.csv'),
            tags: %i[textentries reference_master],
            lookup_on: :tablerowid
          }
        end

        Kiba::Tms.registry.namespace('thes_xrefs') do
          register :term_ids_used, {
            creator: Kiba::Tms::Jobs::ThesXrefs::TermIdsUsed,
            path: File.join(Kiba::Tms.datadir, 'reference', 'term_ids_used_in_thes_xrefs.csv'),
            desc: 'List of term ids used in ThesXrefs.',
            tags: %i[termdata thesxrefs terms reference],
            lookup_on: :termid
          }
        end

        Kiba::Tms.registry.namespace('valuation_control') do
          register :from_accession_lot, {
            creator: Kiba::Tms::Jobs::ValuationControl::FromAccessionLot,
            path: File.join(Kiba::Tms.datadir, 'working', 'vc_from_accessionlot.csv'),
            tags: %i[valuation acquisitions]
          }
          register :nhrs, {
            creator: Kiba::Tms::Jobs::ValuationControl::Nhrs,
            path: File.join(Kiba::Tms.datadir, 'working', 'nhr_vc.csv'),
            tags: %i[valuation nhr]
          }
          register :nhr_acq_accession_lot, {
            creator: Kiba::Tms::Jobs::ValuationControl::NhrAcqAccessionLot,
            path: File.join(Kiba::Tms.datadir, 'working', 'nhr_acq_vc_from_accessionlot.csv'),
            tags: %i[valuation acquisitions nhr]
          }
          register :nhr_obj_accession_lot, {
            creator: Kiba::Tms::Jobs::ValuationControl::NhrObjAccessionLot,
            path: File.join(Kiba::Tms.datadir, 'working', 'nhr_obj_vc_from_accessionlot.csv'),
            tags: %i[valuation objects nhr]
          }
        end

        Kiba::Tms.registry.namespace('works') do
          register :compiled, {
            creator: Kiba::Tms::Jobs::Works::Compiled,
            path: File.join(Kiba::Tms.datadir, 'working', 'works_compiled.csv'),
            tags: %i[works]
          }
          register :from_object_departments, {
            creator: Kiba::Tms::Jobs::Works::FromObjectDepartments,
            path: File.join(Kiba::Tms.datadir, 'working', 'works_from_obj_depts.csv'),
            tags: %i[works]
          }
        end
      end
    end
  end
end
