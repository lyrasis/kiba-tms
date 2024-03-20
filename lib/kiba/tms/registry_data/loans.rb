# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module Loans
        module_function

        def register
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
              desc: "Loans with :loantype not `loan in` or `loan out`. "\
                "Non-zero means work to do!",
              tags: %i[loans todochk]
            }
          end

          Kiba::Tms.registry.namespace("loansin") do
            register :prep, {
              creator: Kiba::Tms::Jobs::Loansin::Prep,
              path: File.join(Kiba::Tms.datadir, "working",
                "loansin__prep.csv"),
              tags: %i[loans loansin],
              lookup_on: :loanid
            }
            register :ingest, {
              creator: Kiba::Tms::Jobs::Loansin::Ingest,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "loansin.csv"),
              tags: %i[loans loansin ingest]
            }
            register :lender_contact_structure_review, {
              creator: Kiba::Tms::Jobs::Loansin::LenderContactStructureReview,
              path: File.join(Kiba::Tms.datadir, "postmigcleanup",
                "loansin_lender_contact_structure_review.csv"),
              tags: %i[loans loansin postmigcleanup],
              desc: "Contact names may be stored in the :contact field in TMS "\
                "and/or merged in from ConXrefs tables. Lender names are "\
                "merged in from ConXrefs tables. There is no explicit "\
                "relationship expressing which contact name goes with which "\
                "lender name. Further, even if there were, details of how "\
                "this data must be structured for ingest into CS (multiple "\
                "possible lender names from two different authorities, that "\
                "need to be lined up with contact names from one authority) "\
                "make it vulnerable to getting messed up if there is more "\
                "than one name value for lender and contact."
            }
          end

          Kiba::Tms.registry.namespace("loan_obj_xrefs") do
            register :by_obj, {
              creator: Kiba::Tms::Jobs::LoanObjXrefs::Prep,
              path: File.join(Kiba::Tms.datadir, "prepped",
                "loan_obj_xrefs.csv"),
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
        end
      end
    end
  end
end
