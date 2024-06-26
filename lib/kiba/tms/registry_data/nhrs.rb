# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module Nhrs
        module_function

        def register
          Kiba::Tms.registry.namespace("nhrs") do
            register :acquisition_object, {
              creator: Kiba::Tms::Jobs::Nhrs::AcquisitionObject,
              path: File.join(
                Kiba::Tms.datadir, "ingest", "nhr_acquisition_object.csv"
              ),
              tags: %i[acquisitions collectionobjects nhr ingest],
              lookup_on: :item2_id
            }
            register :acquisition_valuation, {
              creator: Kiba::Tms::Jobs::Nhrs::AcquisitionValuation,
              path: File.join(
                Kiba::Tms.datadir, "ingest", "nhr_acquisition_valuation.csv"
              ),
              tags: %i[acquisitions valuation nhr ingest]
            }
            register :exhibition_loanin, {
              creator: Kiba::Tms::Jobs::Nhrs::ExhibitionLoanin,
              path: File.join(
                Kiba::Tms.datadir, "ingest", "nhr_exhibition_loanin.csv"
              ),
              desc: "Creates all NHRs between exhibitions and loans in",
              tags: %i[exhibitions loansin nhr ingest]
            }
            register :exhibition_loanout, {
              creator: Kiba::Tms::Jobs::Nhrs::ExhibitionLoanout,
              path: File.join(
                Kiba::Tms.datadir, "ingest", "nhr_exhibition_loanout.csv"
              ),
              desc: "Creates all NHRs between exhibitions and loans out",
              tags: %i[exhibitions loansout nhr ingest]
            }
            register :loanin_object, {
              creator: Kiba::Tms::Jobs::Nhrs::LoaninObject,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "nhr_loanin_object.csv"),
              tags: %i[loans loansin collectionobjects nhr ingest]
            }
            register :loanin_valuation, {
              creator: Kiba::Tms::Jobs::Nhrs::LoaninValuation,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "nhr_loanin_valuation.csv"),
              tags: %i[loans loansin valuation nhr ingest]
            }
            register :loanout_object, {
              creator: Kiba::Tms::Jobs::Nhrs::LoanoutObject,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "nhr_loanout_object.csv"),
              tags: %i[loans loansout collectionobjects nhr ingest]
            }
            register :loanout_valuation, {
              creator: Kiba::Tms::Jobs::Nhrs::LoanoutValuation,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "nhr_loanout_valuation.csv"),
              tags: %i[loans loansout valuation nhr ingest]
            }
            register :media_object, {
              creator: Kiba::Tms::Jobs::Nhrs::MediaObject,
              path: File.join(
                Kiba::Tms.datadir, "ingest", "nhr_media_object.csv"
              ),
              tags: %i[nhr collectionobjects media ingest]
            }
            register :object_object, {
              creator: Kiba::Tms::Jobs::Nhrs::ObjectObject,
              path: File.join(
                Kiba::Tms.datadir, "ingest", "nhr_object_object.csv"
              ),
              tags: %i[nhr collectionobjects ingest]
            }
            register :object_objectexit, {
              creator: Kiba::Tms::Jobs::Nhrs::ObjectObjectexit,
              path: File.join(
                Kiba::Tms.datadir, "ingest", "nhr_object_objectexit.csv"
              ),
              tags: %i[nhr collectionobjects objectexit ingest]
            }
            register :object_valuation, {
              creator: Kiba::Tms::Jobs::Nhrs::ObjectValuation,
              path: File.join(
                Kiba::Tms.datadir, "ingest", "nhr_object_valuation.csv"
              ),
              tags: %i[nhr collectionobjects valuation ingest]
            }
            register :objectexit_valuation, {
              creator: Kiba::Tms::Jobs::Nhrs::ObjectexitValuation,
              path: File.join(
                Kiba::Tms.datadir, "ingest", "nhr_objectexit_valuation.csv"
              ),
              tags: %i[nhr objectexit valuation ingest]
            }

            register :exhibition_loanin_direct, {
              creator: Kiba::Tms::Jobs::Nhrs::ExhibitionLoaninDirect,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_exhibition_loanin_direct.csv"
              ),
              desc: "Creates direct NHRs between exhibitions and loans in",
              tags: %i[exhibitions loansin nhr]
            }
            register :exhibition_loanin_indirect, {
              creator: Kiba::Tms::Jobs::Nhrs::ExhibitionLoaninIndirect,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_exhibition_loanin_indirect.csv"
              ),
              desc: "Creates direct NHRs between exhibitions and loans in "\
                "through objects",
              tags: %i[exhibitions loansin nhr]
            }
            register :exhibition_loanout_direct, {
              creator: Kiba::Tms::Jobs::Nhrs::ExhibitionLoanoutDirect,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_exhibition_loanout_direct.csv"
              ),
              desc: "Creates direct NHRs between exhibitions and loans in",
              tags: %i[exhibitions loansout nhr]
            }
            register :exhibition_loanout_indirect, {
              creator: Kiba::Tms::Jobs::Nhrs::ExhibitionLoanoutIndirect,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_exhibition_loanout_indirect.csv"
              ),
              desc: "Creates direct NHRs between exhibitions and loans in "\
                "through objects",
              tags: %i[exhibitions loansout nhr]
            }
          end
        end
      end
    end
  end
end
