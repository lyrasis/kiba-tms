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

        # register :object_number_lookup, {
        #   path: File.join(Kiba::Tms.datadir, 'prepped', 'object_number_lookup.csv'),
        #   creator: Kiba::Tms::Jobs::Objects.method(:object_number_lookup),
        #   lookup_on: :objectid,
        #   tags: %i[objects lookup prep]
        # }
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
            lookup_on: :constituentid
          }
          register :only_alt, {
            creator: Kiba::Tms::Jobs::ConAltNames::OnlyAlt,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_alt_names_only_alt.csv'),
            desc: 'Removes ConAltNames rows that duplicate Constituent names',
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
          register :for_review, {
            creator: Kiba::Tms::Jobs::ConDates::ForReview,
            path: File.join(Kiba::Tms.datadir, 'reports', 'con_dates_for_review.csv'),
            tags: %i[con condates reports cleanup]
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
            path: File.join(Kiba::Tms.datadir, 'working', 'con_phones_for_persons.csv'),
            tags: %i[con conphones],
            lookup_on: :person
          }
          register :for_orgs, {
            creator: Kiba::Tms::Jobs::ConPhones::ForOrgs,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_phones_for_orgs.csv'),
            tags: %i[con conphones],
            lookup_on: :org
          }
        end

        Kiba::Tms.registry.namespace('con_xref_details') do
          register :for_objects, {
            creator: Kiba::Tms::Jobs::ConXrefDetails::ForObjects,
            path: File.join(Kiba::Tms.datadir, 'working', 'con_xref_details_for_objects.csv'),
            tags: %i[con_xref_details objects],
            lookup_on: :recordid
          }
        end

        Kiba::Tms.registry.namespace('constituents') do
          register :alt_name_mismatch, {
            creator: Kiba::Tms::Jobs::Constituents::AltNameMismatch,
            path: File.join(Kiba::Tms.datadir, 'reports', 'constituents_alt_name_mismatch.csv'),
            desc: 'Constituents where value looked up on defaultnameid (in con_alt_names table) does
                   not match value of preferred name field in constituents table',
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

        Kiba::Tms.registry.namespace('flag_labels') do
          register :unmapped, {
            creator: Kiba::Tms::Jobs::FlagLabels::Unmapped,
            path: File.join(Kiba::Tms.datadir, 'reports', 'flag_labels_unmapped.csv'),
            desc: 'FlagLabel values needing to be added to Tms::FlagLabels.inventory_status_mapping. Non-zero count means work to do!',
            tags: %i[flag_labels todochk]
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

          Kiba::Tms.locations.authorities.each do |loc_type|
            register "#{loc_type}_hier".to_sym, {
              path: File.join(Kiba::Tms.datadir, 'working', "locations_#{loc_type}_hier.csv"),
              creator: {callee: Kiba::Tms::Jobs::LocsClean::HierarchyAdder, args: {type: loc_type}},
              tags: %i[locations],
            }
          end

          Kiba::Tms.locations.authorities.each do |loc_type|
            register "#{loc_type}_cspace".to_sym, {
              path: File.join(Kiba::Tms.datadir, 'working', "locations_#{loc_type}_cspace.csv"),
              creator: {callee: Kiba::Tms::Jobs::LocsClean::Cspace, args: {type: loc_type}},
              tags: %i[locations cspace],
            }
          end

          Kiba::Tms.locations.authorities.each do |loc_type|
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

        Kiba::Tms.registry.namespace('media_files') do
          register :file_names, {
            creator: Kiba::Tms::Jobs::MediaFiles.method(:file_names),
            path: File.join(Kiba::Tms.datadir, 'reports', 'media_file_names.csv'),
            desc: 'Media file names',
            tags: %i[mediafiles reports]
          }
        end

        Kiba::Tms.registry.namespace('nameclean') do
          register :by_constituentid, {
            creator: Kiba::Tms::Jobs::Names::Cleanup::ByConstituentId,
            path: File.join(Kiba::Tms.datadir, 'working', 'by_constituent_id.csv'),
            desc: 'Lookup authorized form by constituent id. Additional fields: person, org, alphasort, displayname',
            tags: %i[names],
            lookup_on: :constituentid
          }
        end
        
        Kiba::Tms.registry.namespace('nameclean0') do
          register :prep, {
            creator: Kiba::Tms::Jobs::Names::Cleanup0::Prep,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_cleaned_up.csv'),
            desc: 'First round of client name cleanup merged in; expands fingerprinted fields, removes rows marked skip, normalizzes cleaned up forms',
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
            desc: 'Names extracted from constituents table, with only subsequent duplicates flagged',
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
          register :from_obj_accession, {
            creator: Kiba::Tms::Jobs::Names::FromObjAccession,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_obj_accession.csv'),
            desc: 'Names extracted from obj_accession table',
            tags: %i[names obj_accession]
          }
          register :from_obj_locations, {
            creator: Kiba::Tms::Jobs::Names::FromObjLocations,
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_obj_locations.csv'),
            desc: 'Names extracted from obj_locations table',
            tags: %i[names obj_locations]
          }
        end

        Kiba::Tms.registry.namespace('obj_comp_statuses') do
          register :unmapped, {
            creator: Kiba::Tms::Jobs::ObjCompStatuses::Unmapped,
            path: File.join(Kiba::Tms.datadir, 'reports', 'obj_comp_statuses_unmapped.csv'),
            tags: %i[obj_components obj_comp_statuses todochk],
            desc: 'Non-zero count means work to do!'
          }
        end

        Kiba::Tms.registry.namespace('obj_comp_types') do
          register :unmapped, {
            creator: Kiba::Tms::Jobs::ObjCompTypes::Unmapped,
            path: File.join(Kiba::Tms.datadir, 'reports', 'obj_comp_types_unmapped.csv'),
            tags: %i[obj_components obj_comp_types todochk],
            desc: 'Non-zero count means work to do!'
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
                ] }
          }
          register :unhandled, {
            creator: Kiba::Tms::Jobs::ObjComponents::Unhandled,
            path: File.join(Kiba::Tms.datadir, 'reports', 'obj_components_unhandled_fields.csv'),
            tags: %i[obj_components todochk],
            desc: 'Rows where any fields expected to be empty are not. These fields are not yet handled by the code, so non-zero count means work to do!'
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
            tags: %i[obj_components objects]
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
        
        Kiba::Tms.registry.namespace('object_statuses') do
          register :unmapped, {
            creator: Kiba::Tms::Jobs::ObjectStatuses::Unmapped,
            path: File.join(Kiba::Tms.datadir, 'reports', 'object_statuses_unmapped.csv'),
            desc: 'ObjectStatuses values that need to be added to project Tms::ObjectStatuses.inventory_status_mapping. If non-zero count, there is work to do!',
            tags: %i[object_statuses todochk]
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
          register :for_constituents, {
            creator: Kiba::Tms::Jobs::TextEntries::ForConstituents,
            path: File.join(Kiba::Tms.datadir, 'working', 'text_entries_for_constituents.csv'),
            desc: 'Merges purpose, textdate, org_author, person_author, remarks, and text entry into one field for merge into person or org records',
            tags: %i[textentries con],
            lookup_on: :tablerowid
          }
          register :for_objects, {
            creator: Kiba::Tms::Jobs::TextEntries::ForObjects,
            path: File.join(Kiba::Tms.datadir, 'working', 'text_entries_for_objects.csv'),
            desc: 'Selects text entries for objects (does not merge text entry fields, as handling may be different per entry type)',
            tags: %i[textentries objects],
            lookup_on: :tablerowid
          }
          register :unknown_table, {
            creator: Kiba::Tms::Jobs::TextEntries::UnknownTable,
            path: File.join(Kiba::Tms.datadir, 'reports', 'text_entries_unknown_table.csv'),
            desc: 'TextEntries rows with tableid not in Tms::TABLES lookup',
            tags: %i[textentries todochk reports]
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
      end
    end
  end
end
