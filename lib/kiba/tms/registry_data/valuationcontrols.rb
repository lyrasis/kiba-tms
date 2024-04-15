# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module Valuationcontrols
        module_function

        def register
          Kiba::Tms.registry.namespace("obj_insurance") do
            register :migrating, {
              creator: Kiba::Tms::Jobs::ObjInsurance::Migrating,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_insurance_migrating.csv"),
              tags: %i[obj_insurance valuation]
            }
            register :shape, {
              creator: Kiba::Tms::Jobs::ObjInsurance::Shape,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_insurance_shape.csv"),
              tags: %i[obj_insurance valuation]
            }
            register :dropped, {
              creator: Kiba::Tms::Jobs::ObjInsurance::Dropped,
              path: File.join(Kiba::Tms.datadir, "postmigcleanup",
                "obj_insurance_dropped.csv"),
              tags: %i[obj_insurance valuation postmigcleanup]
            }
            register :dropped_in_context, {
              creator: Kiba::Tms::Jobs::ObjInsurance::DroppedInContext,
              path: File.join(Kiba::Tms.datadir, "reports",
                "obj_insurance_dropped_in_context.csv"),
              tags: %i[obj_insurance valuation reports],
              dest_special_opts:
              {initial_headers: %i[objectnumber dropping value currency]}
            }
          end

          Kiba::Tms.registry.namespace("valuationcontrols") do
            register :all, {
              creator: Kiba::Tms::Jobs::Valuationcontrols::All,
              path: File.join(Kiba::Tms.datadir, "working", "vc_all.csv"),
              tags: %i[valuation],
              lookup_on: :objinsuranceid
            }
            register :ingest, {
              creator: Kiba::Tms::Jobs::Valuationcontrols::Ingest,
              path: File.join(Kiba::Tms.datadir, "ingest", "valuation.csv"),
              tags: %i[valuation ingest]
            }
            register :from_accession_lot, {
              creator: Kiba::Tms::Jobs::Valuationcontrols::FromAccessionLot,
              path: File.join(Kiba::Tms.datadir, "working",
                "vc_from_accessionlot.csv"),
              tags: %i[valuation acquisitions]
            }
            register :from_obj_insurance, {
              creator: Kiba::Tms::Jobs::Valuationcontrols::FromObjInsurance,
              path: File.join(Kiba::Tms.datadir, "working",
                "vc_from_obj_insurance.csv"),
              tags: %i[valuation obj_insurance]
            }
            register :nhrs, {
              creator: Kiba::Tms::Jobs::Valuationcontrols::Nhrs,
              path: File.join(Kiba::Tms.datadir, "working", "nhr_vc.csv"),
              tags: %i[valuation nhr]
            }
            register :nhr_acq_accession_lot, {
              creator: Kiba::Tms::Jobs::Valuationcontrols::NhrAcqAccessionLot,
              path: File.join(Kiba::Tms.datadir, "working",
                "nhr_acq_vc_from_accessionlot.csv"),
              tags: %i[valuation acquisitions nhr]
            }
            register :nhr_obj_accession_lot, {
              creator: Kiba::Tms::Jobs::Valuationcontrols::NhrObjAccessionLot,
              path: File.join(Kiba::Tms.datadir, "working",
                "nhr_obj_vc_from_accessionlot.csv"),
              tags: %i[valuation objects nhr]
            }
            register :nhr_obj, {
              creator: Kiba::Tms::Jobs::Valuationcontrols::NhrObj,
              path: File.join(Kiba::Tms.datadir, "working",
                "nhr_obj_vc.csv"),
              tags: %i[valuation objects nhr]
            }
          end
        end
      end
    end
  end
end
