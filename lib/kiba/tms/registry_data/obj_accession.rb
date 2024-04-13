# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module ObjAccession
        module_function

        def register
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
              path: File.join(Kiba::Tms.datadir, "working",
                "linked_set_acq.csv"),
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
            register :valuation_review, {
              creator: Kiba::Tms::Jobs::ObjAccession::ValuationReview,
              path: File.join(Tms.datadir, "reports",
                "obj_accession_valuation_review.csv"),
              tags: %i[obj_accessions reports],
              desc: "Includes rows with value/price data that are not linked to "\
                "ObjInsurance rows."
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

          Kiba::Tms.registry.namespace("registration_sets") do
            register :for_ingest, {
              creator: Kiba::Tms::Jobs::RegistrationSets::ForIngest,
              path: File.join(Kiba::Tms.datadir, "working",
                "reg_set_for_ingest.csv"),
              desc: "Acquisitions for ingest, derived from RegSets. RegSet id "\
                "removed.",
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
        end
      end
    end
  end
end
