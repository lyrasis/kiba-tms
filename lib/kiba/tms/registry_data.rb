# frozen_string_literal: true

module Kiba
  module Tms
    # Central place to register the expected jobs/files used and produced by your project
    #
    # Populates file registry provided by Kiba::Extend
    module RegistryData
      def self.register
        register_supplied_files
        register_files
      end

      def self.register_supplied_files
        tables = Tms::Table::List.call.map{ |table| Tms::Table::Obj.new(table) }
          .select(&:included)
        
        Kiba::Tms.registry.namespace('tms') do
          tables.each{ |table| register table.filekey, Tms::Table::Supplied::RegistryHashCreator.call(table) }
        end
      end
      
      def self.register_files
        Kiba::Tms.registry.namespace('prep') do
          register :alt_nums, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'alt_nums.csv'),
            creator: Kiba::Tms::Jobs::AltNums.method(:prep),
            lookup_on: :description,
            tags: %i[altnums prep]
          }
          register :classification_notations, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'classification_notations.csv'),
            creator: Kiba::Tms::Jobs::ClassificationNotations.method(:prep),
            lookup_on: :classificationnotationid,
            tags: %i[classificationnotations prep]
          }
          register :classification_xrefs, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'classification_xrefs.csv'),
            creator: Kiba::Tms::Jobs::ClassificationXrefs.method(:prep),
            lookup_on: :id,
            tags: %i[classificationxrefs prep]
          }
          register :classifications, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'classifications.csv'),
            creator: Kiba::Tms::Jobs::Classifications.method(:prep),
            lookup_on: :classificationid,
            tags: %i[classifications prep]
          }
          register :constituents, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'constituents.csv'),
            creator: Kiba::Tms::Jobs::Constituents.method(:prep),
            lookup_on: :constituentid,
            dest_special_opts: { initial_headers: %i[constituentid constituenttype displayname defaultnameid] },
            tags: %i[con prep]
          }
          register :con_types, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'con_types.csv'),
            creator: Kiba::Tms::Jobs::ConTypes.method(:prep),
            lookup_on: :constituenttypeid,
            tags: %i[con contypes prep]
          }
          register :con_alt_names, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'con_alt_names.csv'),
            creator: Kiba::Tms::Jobs::ConAltNames.method(:prep),
            lookup_on: :altnameid,
            dest_special_opts: {
              initial_headers:
              %i[constituentid constituentdefaultnameid altnameid constituentdisplayname constituenttype
                 nametype displayname]
            },
            tags: %i[con conaltnames prep]
          }
          register :con_dates, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'con_dates.csv'),
            creator: Kiba::Tms::Jobs::ConDates.method(:prep),
            dest_special_opts: {
              initial_headers:
              %i[constituentdisplayname constituenttype datedescription remarks
                 datebegsearch monthbegsearch daybegsearch
                 dateendsearch monthendsearch dayendsearch]
            },
            tags: %i[con condates prep]
          }
          register :departments, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'departments.csv'),
            creator: Kiba::Tms::Jobs::Departments.method(:prep),
            lookup_on: :departmentid,
            tags: %i[departments prep]
          }
          register :exh_ven_obj_xrefs, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'exh_ven_obj_xrefs.csv'),
            creator: Kiba::Tms::Jobs::ExhVenObjXrefs.method(:prep),
            tags: %i[exhibitions objects venues rels prep]
          }
          register :indemnity_responsibilities, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'indemnity_responsibilities.csv'),
            creator: Kiba::Tms::Jobs::IndemnityResponsibilities.method(:prep),
            lookup_on: :responsibilityid,
            tags: %i[ins indemnityresponsibilities prep]
          }
          register :insurance_responsibilities, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'insurance_responsibilities.csv'),
            creator: Kiba::Tms::Jobs::InsuranceResponsibilities.method(:prep),
            lookup_on: :responsibilityid,
            tags: %i[ins insuranceresponsibilities prep]
          }
          register :loan_obj_xrefs, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'loan_obj_xrefs.csv'),
            creator: Kiba::Tms::Jobs::LoanObjXrefs.method(:prep),
            tags: %i[loans objects rels prep]
          }
          register :obj_ins_indem_resp, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'obj_ins_indem_resp.csv'),
            creator: Kiba::Tms::Jobs::ObjInsIndemResp.method(:prep),
            lookup_on: :objinsindemrespid,
            tags: %i[ins indemnityresponsibilities insuranceresponsibilitie prep]
          }
          register :object_number_lookup, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'object_number_lookup.csv'),
            creator: Kiba::Tms::Jobs::Objects.method(:object_number_lookup),
            lookup_on: :objectid,
            tags: %i[objects lookup prep]
          }
          register :object_numbers, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'object_numbers.csv'),
            creator: Kiba::Tms::Jobs::Objects.method(:object_numbers),
            lookup_on: :objectnumber,
            tags: %i[objects lookup prep]
          }
          register :objects, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'objects.csv'),
            creator: Kiba::Tms::Jobs::Objects.method(:prep),
            lookup_on: :objectnumber,
            dest_special_opts: {
              initial_headers:
              %i[objectnumber department classification classificationxref objectname objectstatus title]
            },
            tags: %i[objects prep]
          }
          register :object_statuses, {
            path: File.join(Kiba::Tms.datadir, 'prepped', 'object_statuses.csv'),
            creator: Kiba::Tms::Jobs::ObjectStatuses.method(:prep),
            lookup_on: :objectstatusid,
            tags: %i[objectstatuses prep]
          }
          register :term_master, {
            creator: Kiba::Tms::Jobs::TermMaster.method(:prep),
            path: File.join(Kiba::Tms.datadir, 'prepped', 'term_master.csv'),
            lookup_on: :termmasterid,
            tags: %i[termdata termmaster prep]
          }
          register :term_master_geo, {
            creator: Kiba::Tms::Jobs::TermMasterGeo.method(:prep),
            path: File.join(Kiba::Tms.datadir, 'prepped', 'term_master_geo.csv'),
            lookup_on: :termmastergeoid,
            tags: %i[termdata termmastergeo prep]
          }
          register :term_types, {
            creator: Kiba::Tms::Jobs::TermTypes.method(:prep),
            path: File.join(Kiba::Tms.datadir, 'prepped', 'term_types.csv'),
            lookup_on: :termtypeid,
            tags: %i[termdata termtypes prep]
          }
          register :terms, {
            creator: Kiba::Tms::Jobs::Terms.method(:prep),
            path: File.join(Kiba::Tms.datadir, 'prepped', 'terms.csv'),
            lookup_on: :termid,
            dest_special_opts: { initial_headers: %i[termid termmasterid termtype term termsource termsourceid] },
            tags: %i[termdata terms prep]
          }
          register :thes_xrefs, {
            creator: Kiba::Tms::Jobs::ThesXrefs.method(:prep),
            path: File.join(Kiba::Tms.datadir, 'prepped', 'thes_xrefs.csv'),
            dest_special_opts: { initial_headers: %i[tablename table_row_id thesxreftype term] },
            tags: %i[termdata thesxrefs prep]
          }
          register :thes_xref_types, {
            creator: Kiba::Tms::Jobs::ThesXrefTypes.method(:prep),
            path: File.join(Kiba::Tms.datadir, 'prepped', 'thes_xref_types.csv'),
            lookup_on: :thesxreftypeid,
            tags: %i[termdata thesxreftypes prep]
          }
        end

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

        Kiba::Tms.registry.namespace('constituents') do
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
