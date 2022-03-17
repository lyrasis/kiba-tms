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
          register :for_objects, {
            creator: Kiba::Tms::Jobs::AltNums.method(:for_objects),
            path: File.join(Kiba::Tms.datadir, 'working', 'alt_nums_for_objects.csv'),
            desc: 'AltNums to be merged into Objects',
            tags: %i[altnums mergeable]
          }
          register :for_refs, {
            creator: Kiba::Tms::Jobs::AltNums.method(:for_refs),
            path: File.join(Kiba::Tms.datadir, 'working', 'alt_nums_for_refs.csv'),
            desc: 'AltNums to be merged into ReferenceMaster',
            tags: %i[altnums mergeable]
          }
          register :for_objects_todo, {
            creator: Kiba::Tms::Jobs::AltNums.method(:for_objects_todo),
            path: File.join(Kiba::Tms.datadir, 'working', 'alt_nums_for_objects_todo.csv'),
            desc: 'Reference AltNums with date values - need to map',
            tags: %i[altnums todochk]
          }
          register :for_refs_todo, {
            creator: Kiba::Tms::Jobs::AltNums.method(:for_refs_todo),
            path: File.join(Kiba::Tms.datadir, 'working', 'alt_nums_for_refs_todo.csv'),
            desc: 'Reference AltNums with date values - need to map',
            tags: %i[altnums todochk]
          }
          register :for_constituents, {
            creator: Kiba::Tms::Jobs::AltNums.method(:for_constituents),
            path: File.join(Kiba::Tms.datadir, 'working', 'alt_nums_for_constituents.csv'),
            desc: 'AltNums to be merged into Constituents',
            tags: %i[altnums mergeable]
          }
          register :single_occ_description, {
            creator: Kiba::Tms::Jobs::AltNums.method(:single_occ_description),
            path: File.join(Kiba::Tms.datadir, 'reports', 'alt_nums_description_single_occ.csv'),
            desc: 'AltNums with a description only used once'
          }
          register :description_occs, {
            creator: Kiba::Tms::Jobs::AltNums.method(:description_occs),
            path: File.join(Kiba::Tms.datadir, 'prepped', 'alt_nums_description_occs.csv'),
            desc: 'AltNums with count of description occurrences',
            tags: %i[altnums prep]
          }
          register :no_description, {
            creator: Kiba::Tms::Jobs::AltNums.method(:no_description),
            path: File.join(Kiba::Tms.datadir, 'reports', 'alt_nums_no_description.csv'),
            desc: 'AltNums without a description value',
            tags: %i[altnums reports]
          }
          register :types, {
            creator: Kiba::Tms::Jobs::AltNums.method(:types),
            path: File.join(Kiba::Tms.datadir, 'reports', 'alt_num_types.csv'),
            desc: 'AltNumber types',
            tags: %i[altnums reports]
          }
        end

        Kiba::Tms.registry.namespace('con_alt_names') do
          register :by_constituent, {
            creator: Kiba::Tms::Jobs::ConAltNames.method(:prep),
            path: File.join(Kiba::Tms.datadir, 'prepped', 'con_alt_names.csv'),
            tags: %i[con prep],
            lookup_on: :constituentid
          }
        end
        
        Kiba::Tms.registry.namespace('constituents') do
          register :alt_name_mismatch, {
            creator: Kiba::Tms::Jobs::Constituents.method(:alt_name_mismatch),
            path: File.join(Kiba::Tms.datadir, 'reports', 'constituents_alt_name_mismatch.csv'),
            desc: 'Constituents where value looked up on defaultnameid (in con_alt_names table) does
                   not match value of preferred name field in constituents table',
            tags: %i[con reports]
          }
          register :alt_names_merged, {
            creator: Kiba::Tms::Jobs::Constituents.method(:alt_names_merged),
            path: File.join(Kiba::Tms.datadir, 'working', 'constituents_alt_names_merged.csv'),
            desc: 'Constituents with non-default form of name merged in',
            tags: %i[con]
          }
          register :with_type, {
            creator: Kiba::Tms::Jobs::Constituents.method(:with_type),
            path: File.join(Kiba::Tms.datadir, 'reports', 'constituents_with_type.csv'),
            desc: 'Constituents with a constituent type entered',
            tags: %i[con reports]
          }
          register :without_type, {
            creator: Kiba::Tms::Jobs::Constituents.method(:without_type),
            path: File.join(Kiba::Tms.datadir, 'working', 'constituents_without_type.csv'),
            desc: 'Constituents without a constituent type entered',
            tags: %i[con]
          }
          register :with_name_data, {
            creator: Kiba::Tms::Jobs::Constituents.method(:with_name_data),
            path: File.join(Kiba::Tms.datadir, 'working', 'constituents_with_name_data.csv'),
            desc: 'Constituents with displayname or alphasort name',
            tags: %i[con]
          }
          register :without_name_data, {
            creator: Kiba::Tms::Jobs::Constituents.method(:without_name_data),
            path: File.join(Kiba::Tms.datadir, 'reports', 'constituents_without_name_data.csv'),
            desc: 'Constituents without displayname or alphasort name',
            tags: %i[con reports]
          }
          register :derived_type, {
            creator: Kiba::Tms::Jobs::Constituents.method(:derived_type),
            path: File.join(Kiba::Tms.datadir, 'reports', 'constituents_with_derived_type.csv'),
            desc: 'Constituents with a derived type',
            tags: %i[con reports]
          }
          register :no_derived_type, {
            creator: Kiba::Tms::Jobs::Constituents.method(:no_derived_type),
            path: File.join(Kiba::Tms.datadir, 'reports', 'constituents_without_derived_type.csv'),
            desc: 'Constituents without a derived type',
            tags: %i[con reports]
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

        Kiba::Tms.registry.namespace('names') do
          register :compiled, {
            creator: Kiba::Tms::Jobs::InBetween::NameCompilation.method(:compiled),
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
            creator: Kiba::Tms::Jobs::InBetween::NameCompilation.method(:flagged_duplicates),
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents_flagged_duplicates.csv'),
            desc: 'Names extracted from constituents table and flagged as duplicates',
            tags: %i[names con],
            lookup_on: :norm
          }
          register :initial_compile, {
            creator: Kiba::Tms::Jobs::InBetween::NameCompilation.method(:initial_compile),
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents_initial_compile.csv'),
            desc: 'Names extracted from constituents table, with only subsequent duplicates flagged',
            tags: %i[names con]
          }
          register :from_constituents, {
            creator: Kiba::Tms::Jobs::InBetween::NameCompilation.method(:from_constituents),
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents.csv'),
            desc: 'Names extracted from constituents table',
            tags: %i[names con]
          }
          register :from_constituents_orgs_from_persons, {
            creator: Kiba::Tms::Jobs::InBetween::NameCompilation.method(:from_constituents_orgs_from_persons),
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents_orgs_from_persons.csv'),
            desc: 'Names extracted from institution field of Person constituents',
            tags: %i[names con]
          }
          register :from_constituents_persons_from_orgs, {
            creator: Kiba::Tms::Jobs::InBetween::NameCompilation.method(:from_constituents_persons_from_orgs),
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_constituents_persons_from_orgs.csv'),
            desc: 'Names extracted from Organization constituents when the name part values are populated',
            tags: %i[names con]
          }
          register :from_loans, {
            creator: Kiba::Tms::Jobs::InBetween::NameCompilation.method(:from_loans),
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_loans.csv'),
            desc: 'Names extracted from loans table',
            tags: %i[names loans]
          }
          register :from_obj_accession, {
            creator: Kiba::Tms::Jobs::InBetween::NameCompilation.method(:from_obj_accession),
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_obj_accession.csv'),
            desc: 'Names extracted from obj_accession table',
            tags: %i[names obj_accession]
          }
          register :from_obj_locations, {
            creator: Kiba::Tms::Jobs::InBetween::NameCompilation.method(:from_obj_locations),
            path: File.join(Kiba::Tms.datadir, 'working', 'names_from_obj_locations.csv'),
            desc: 'Names extracted from obj_locations table',
            tags: %i[names obj_locations]
          }
        end

        Kiba::Tms.registry.namespace('terms') do
          register :descriptors, {
            creator: Kiba::Tms::Jobs::Terms.method(:descriptors),
            path: File.join(Kiba::Tms.datadir, 'prepped', 'terms_descriptors.csv'),
            desc: 'Thesaurus terms with type 1 = descriptor',
            lookup_on: :termid,
            tags: %i[termdata terms prep]
          }
        end
        
        Kiba::Tms.registry.namespace('thes_xrefs') do
          register :for_term_report, {
            creator: Kiba::Tms::Jobs::ThesXrefs.method(:for_term_report),
            path: File.join(Kiba::Tms.datadir, 'prepped', 'thes_xrefs_for_term_report.csv'),
            desc: 'Thesaurus xrefs prepped for term report',
            tags: %i[termdata thesxrefs prep]
          }
          register :with_notation, {
            creator: Kiba::Tms::Jobs::ThesXrefs.method(:with_notation),
            path: File.join(Kiba::Tms.datadir, 'working', 'thes_xrefs_with_notation.csv'),
            desc: 'Thesaurus xrefs with notation values',
            tags: %i[termdata thesxrefs]
          }
          register :without_notation, {
            creator: Kiba::Tms::Jobs::ThesXrefs.method(:without_notation),
            path: File.join(Kiba::Tms.datadir, 'working', 'thes_xrefs_without_notation.csv'),
            desc: 'Thesaurus xrefs without notation values',
            tags: %i[termdata thesxrefs]
          }
          register :with_notation_usage_type_lookup, {
            creator: Kiba::Tms::Jobs::ThesXrefs.method(:with_notation_usage_type_lookup),
            path: File.join(Kiba::Tms.datadir, 'working', 'thes_xrefs_with_notation_usage_type_lookup.csv'),
            lookup_on: :notation,
            tags: %i[termdata thesxrefs]
          }
          register :without_notation_usage_type_lookup, {
            creator: Kiba::Tms::Jobs::ThesXrefs.method(:without_notation_usage_type_lookup),
            path: File.join(Kiba::Tms.datadir, 'working', 'thes_xrefs_without_notation_usage_type_lookup.csv'),
            lookup_on: :term,
            tags: %i[termdata thesxrefs]
          }
          register :with_notation_uniq, {
            creator: Kiba::Tms::Jobs::ThesXrefs.method(:with_notation_uniq),
            path: File.join(Kiba::Tms.datadir, 'working', 'thes_xrefs_with_notation_uniq.csv'),
            desc: 'Thesaurus xrefs with notation values, deduplicated',
            tags: %i[termdata thesxrefs]
          }
          register :without_notation_uniq, {
            creator: Kiba::Tms::Jobs::ThesXrefs.method(:without_notation_uniq),
            path: File.join(Kiba::Tms.datadir, 'working', 'thes_xrefs_without_notation_uniq.csv'),
            desc: 'Thesaurus xrefs without notation values, deduplicated',
            tags: %i[termdata thesxrefs]
          }
          register :with_notation_uniq_typed, {
            creator: Kiba::Tms::Jobs::ThesXrefs.method(:with_notation_uniq_typed),
            path: File.join(Kiba::Tms.datadir, 'working', 'thes_xrefs_with_notation_uniq_typed.csv'),
            desc: 'Thesaurus xrefs with notation values, deduplicated',
            tags: %i[termdata thesxrefs]
          }
          register :without_notation_uniq_typed, {
            creator: Kiba::Tms::Jobs::ThesXrefs.method(:without_notation_uniq_typed),
            path: File.join(Kiba::Tms.datadir, 'working', 'thes_xrefs_without_notation_uniq_typed.csv'),
            desc: 'Thesaurus xrefs without notation values, deduplicated',
            tags: %i[termdata thesxrefs]
          }
        end
      end
    end
  end
end
