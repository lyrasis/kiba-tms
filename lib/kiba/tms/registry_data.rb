# frozen_string_literal: true

module Kiba
  module Tms
    # Central place to register the expected jobs/files used and produced by your project
    #
    # Populates file registry provided by Kiba::Extend
    module RegistryData
      def self.register
        register_files
        Kiba::Tms.registry.transform # Transforms the file hashes below into Kiba::Extend::Registry::FileRegistryEntry objects
      end

      def self.register_files
        Kiba::Tms.registry.namespace('tms') do
          register :alt_nums, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'AltNums.csv'),
            supplied: true
          }
          register :classification_notations, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'ClassificationNotations.csv'),
            supplied: true
          }
          register :classification_xrefs, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'ClassificationXRefs.csv'),
            supplied: true
          }
          register :classifications, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'Classifications.csv'),
            supplied: true
          }
          register :con_alt_names, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'ConAltNames.csv'),
            supplied: true
          }
          register :con_dates, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'ConDates.csv'),
            supplied: true
          }
          register :constituents, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'Constituents.csv'),
            supplied: true,
            lookup_on: :constituentid
          }
          register :con_types, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'ConTypes.csv'),
            supplied: true
          }
          register :departments, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'Departments.csv'),
            supplied: true,
            lookup_on: :departmentid
          }
          register :exh_ven_obj_xrefs, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'ExhVenObjXrefs.csv'),
            supplied: true
          }
          register :indemnity_responsibilities, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'IndemnityResponsibilities.csv'),
            supplied: true
          }
          register :insurance_responsibilities, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'InsuranceResponsibilities.csv'),
            supplied: true
          }
          register :loan_obj_xrefs, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'LoanObjXrefs.csv'),
            supplied: true
          }
          register :media_files, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'MediaFiles.csv'),
            supplied: true
          }
          register :media_renditions, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'MediaRenditions.csv'),
            supplied: true
          }
          register :objects, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'Objects.csv'),
            supplied: true
          }
          register :obj_ins_indem_resp, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'ObjInsIndemResp.csv'),
            supplied: true
          }
          register :object_statuses, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'ObjectStatuses.csv'),
            supplied: true
          }
          register :relationships, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'Relationships.csv'),
            supplied: true
          }
          register :term_master, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'TermMasterThes.csv'),
            supplied: true
          }
          register :term_master_geo, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'TermMasterGeo.csv'),
            supplied: true
          }
          register :term_types, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'TermTypes.csv'),
            supplied: true
          }
          register :terms, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'Terms.csv'),
            supplied: true
          }
          register :thes_xrefs, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'ThesXrefs.csv'),
            supplied: true
          }
          register :thes_xref_types, {
            path: File.join(Kiba::Tms.tmsdatadir, 'tms', 'ThesXrefTypes.csv'),
            supplied: true
          }
        end
        
        Kiba::Tms.registry.namespace('prep') do
        #   register :alt_nums, {
        #     path: File.join(Mmm.datadir, 'prepped', 'alt_nums.csv'),
        #     creator: Kiba::Tms::AltNums.method(:prep),
        #     lookup_on: :description,
        #     tags: %i[altnums prep]
        #   }
        #   register :classification_notations, {
        #     path: File.join(Mmm.datadir, 'prepped', 'classification_notations.csv'),
        #     creator: Kiba::Tms::ClassificationNotations.method(:prep),
        #     lookup_on: :classificationnotationid,
        #     tags: %i[classificationnotations prep]
        #   }
        #   register :classification_xrefs, {
        #     path: File.join(Mmm.datadir, 'prepped', 'classification_xrefs.csv'),
        #     creator: Kiba::Tms::ClassificationXrefs.method(:prep),
        #     lookup_on: :id,
        #     tags: %i[classificationxrefs prep]
        #   }
        #   register :classifications, {
        #     path: File.join(Mmm.datadir, 'prepped', 'classifications.csv'),
        #     creator: Kiba::Tms::Classifications.method(:prep),
        #     lookup_on: :classificationid,
        #     tags: %i[classifications prep]
        #   }
          register :constituents, {
            path: File.join(Mmm.datadir, 'prepped', 'constituents.csv'),
            creator: Kiba::Tms::Constituents.method(:prep),
            lookup_on: :constituentid,
            dest_special_opts: { initial_headers: %i[constituentid constituenttype displayname defaultnameid] },
            tags: %i[con prep]
          }
        #   register :con_types, {
        #     path: File.join(Mmm.datadir, 'prepped', 'con_types.csv'),
        #     creator: Kiba::Tms::ConTypes.method(:prep),
        #     lookup_on: :constituenttypeid,
        #     tags: %i[con contypes prep]
        #   }
        #   register :con_alt_names, {
        #     path: File.join(Mmm.datadir, 'prepped', 'con_alt_names.csv'),
        #     creator: Kiba::Tms::ConAltNames.method(:prep),
        #     lookup_on: :altnameid,
        #     dest_special_opts: {
        #       initial_headers:
        #       %i[constituentid constituentdefaultnameid altnameid constituentdisplayname constituenttype
        #          nametype displayname]
        #     },
        #     tags: %i[con conaltnames prep]
        #   }
        #   register :con_dates, {
        #     path: File.join(Mmm.datadir, 'prepped', 'con_dates.csv'),
        #     creator: Kiba::Tms::ConDates.method(:prep),
        #     dest_special_opts: {
        #       initial_headers:
        #       %i[constituentdisplayname constituenttype datedescription remarks
        #          datebegsearch monthbegsearch daybegsearch
        #          dateendsearch monthendsearch dayendsearch]
        #     },
        #     tags: %i[con condates prep]
        #   }
        #   register :departments, {
        #     path: File.join(Mmm.datadir, 'prepped', 'departments.csv'),
        #     creator: Kiba::Tms::Departments.method(:prep),
        #     lookup_on: :departmentid,
        #     tags: %i[departments prep]
        #   }
        #   register :exh_ven_obj_xrefs, {
        #     path: File.join(Mmm.datadir, 'prepped', 'exh_ven_obj_xrefs.csv'),
        #     creator: Kiba::Tms::ExhVenObjXrefs.method(:prep),
        #     tags: %i[exhibitions objects venues rels prep]
        #   }
        #   register :indemnity_responsibilities, {
        #     path: File.join(Mmm.datadir, 'prepped', 'indemnity_responsibilities.csv'),
        #     creator: Kiba::Tms::IndemnityResponsibilities.method(:prep),
        #     lookup_on: :responsibilityid,
        #     tags: %i[ins indemnityresponsibilities prep]
        #   }
        #   register :insurance_responsibilities, {
        #     path: File.join(Mmm.datadir, 'prepped', 'insurance_responsibilities.csv'),
        #     creator: Kiba::Tms::InsuranceResponsibilities.method(:prep),
        #     lookup_on: :responsibilityid,
        #     tags: %i[ins insuranceresponsibilities prep]
        #   }
        #   register :loan_obj_xrefs, {
        #     path: File.join(Mmm.datadir, 'prepped', 'loan_obj_xrefs.csv'),
        #     creator: Kiba::Tms::LoanObjXrefs.method(:prep),
        #     tags: %i[loans objects rels prep]
        #   }
        #   register :obj_ins_indem_resp, {
        #     path: File.join(Mmm.datadir, 'prepped', 'obj_ins_indem_resp.csv'),
        #     creator: Kiba::Tms::ObjInsIndemResp.method(:prep),
        #     lookup_on: :objinsindemrespid,
        #     tags: %i[ins indemnityresponsibilities insuranceresponsibilitie prep]
        #   }
        #   register :object_number_lookup, {
        #     path: File.join(Mmm.datadir, 'prepped', 'object_number_lookup.csv'),
        #     creator: Kiba::Tms::Objects.method(:object_number_lookup),
        #     lookup_on: :objectid,
        #     tags: %i[objects lookup prep]
        #   }
        #   register :object_numbers, {
        #     path: File.join(Mmm.datadir, 'prepped', 'object_numbers.csv'),
        #     creator: Kiba::Tms::Objects.method(:object_numbers),
        #     lookup_on: :objectnumber,
        #     tags: %i[objects lookup prep]
        #   }
        #   register :objects, {
        #     path: File.join(Mmm.datadir, 'prepped', 'objects.csv'),
        #     creator: Kiba::Tms::Objects.method(:prep),
        #     lookup_on: :objectnumber,
        #     dest_special_opts: {
        #       initial_headers:
        #       %i[objectnumber department classification classificationxref objectname objectstatus title]
        #     },
        #     tags: %i[objects prep]
        #   }
        #   register :object_statuses, {
        #     path: File.join(Mmm.datadir, 'prepped', 'object_statuses.csv'),
        #     creator: Kiba::Tms::ObjectStatuses.method(:prep),
        #     lookup_on: :objectstatusid,
        #     tags: %i[objectstatuses prep]
        #   }
        #   register :term_master, {
        #     creator: Kiba::Tms::TermMaster.method(:prep),
        #     path: File.join(Mmm.datadir, 'prepped', 'term_master.csv'),
        #     lookup_on: :termmasterid,
        #     tags: %i[termdata termmaster prep]
        #   }
        #   register :term_master_geo, {
        #     creator: Kiba::Tms::TermMasterGeo.method(:prep),
        #     path: File.join(Mmm.datadir, 'prepped', 'term_master_geo.csv'),
        #     lookup_on: :termmastergeoid,
        #     tags: %i[termdata termmastergeo prep]
        #   }
        #   register :term_types, {
        #     creator: Kiba::Tms::TermTypes.method(:prep),
        #     path: File.join(Mmm.datadir, 'prepped', 'term_types.csv'),
        #     lookup_on: :termtypeid,
        #     tags: %i[termdata termtypes prep]
        #   }
        #   register :terms, {
        #     creator: Kiba::Tms::Terms.method(:prep),
        #     path: File.join(Mmm.datadir, 'prepped', 'terms.csv'),
        #     lookup_on: :termid,
        #     dest_special_opts: { initial_headers: %i[termid termmasterid termtype term termsource termsourceid] },
        #     tags: %i[termdata terms prep]
        #   }
        #   register :thes_xrefs, {
        #     creator: Kiba::Tms::ThesXrefs.method(:prep),
        #     path: File.join(Mmm.datadir, 'prepped', 'thes_xrefs.csv'),
        #     dest_special_opts: { initial_headers: %i[tablename table_row_id thesxreftype term] },
        #     tags: %i[termdata thesxrefs prep]
        #   }
        #   register :thes_xref_types, {
        #     creator: Kiba::Tms::ThesXrefTypes.method(:prep),
        #     path: File.join(Mmm.datadir, 'prepped', 'thes_xref_types.csv'),
        #     lookup_on: :thesxreftypeid,
        #     tags: %i[termdata thesxreftypes prep]
        #   }
        end
      end
    end
  end
end
