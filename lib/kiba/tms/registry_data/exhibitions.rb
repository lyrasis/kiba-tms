# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module Exhibitions
        module_function

        def register
          Kiba::Tms.registry.namespace("exhibitions") do
            register :venue_count, {
              creator: Kiba::Tms::Jobs::Exhibitions::VenueCount,
              path: File.join(
                Kiba::Tms.datadir, "working", "exhibitions_venue_count.csv"
              ),
              desc: "Number of venues for each exhibit",
              tags: %i[exhibitions],
              lookup_on: :exhibitionid
            }
            register :shaped, {
              creator: Kiba::Tms::Jobs::Exhibitions::Shaped,
              path: File.join(
                Kiba::Tms.datadir, "working", "exhibitions_shaped.csv"
              ),
              desc: "Reshape prepped exhibition data",
              tags: %i[exhibitions],
              lookup_on: :exhibitionid
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
            register :merge_venue_details, {
              creator: Kiba::Tms::Jobs::Exhibitions::MergeVenueDetails,
              path: File.join(
                Kiba::Tms.datadir, "working",
                "exhibitions_venue_details_merged.csv"
              ),
              desc: "Merges data from exh_venues_xrefs that does not map to "\
                "Venue field group",
              tags: %i[exhibitions]
            }
            register :ingest, {
              creator: Kiba::Tms::Jobs::Exhibitions::Ingest,
              path: File.join(
                Kiba::Tms.datadir, "ingest", "exhibitions.csv"
              ),
              tags: %i[exhibitions ingest]
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
              desc: "Compiles exhibition-loanin and exhibition-loanout nhrs",
              tags: %i[exhibitions loansin loansout loans nhr]
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

          Kiba::Tms.registry.namespace("exh_venues_xrefs") do
            register :single_venue, {
              creator: Kiba::Tms::Jobs::ExhVenuesXrefs::SingleVenue,
              path: File.join(
                Kiba::Tms.datadir, "working",
                "exh_venues_xrefs_single_venue.csv"
              ),
              desc: "Data from table for exhibitions having only one venue. "\
                "Data can be merged into exhibition record in a "\
                "straightforward way",
              tags: %i[exhibitions exh_venues_xrefs],
              lookup_on: :exhibitionid
            }
            register :multi_venue, {
              creator: Kiba::Tms::Jobs::ExhVenuesXrefs::MultiVenue,
              path: File.join(
                Kiba::Tms.datadir, "working",
                "exh_venues_xrefs_multi_venue.csv"
              ),
              desc: "Data from table for exhibitions having multiplevenue. "\
                "Data cannot be merged into exhibition record in a "\
                "straightforward way",
              tags: %i[exhibitions exh_venues_xrefs],
              lookup_on: :exhibitionid
            }
          end

          Kiba::Tms.registry.namespace("exh_ven_obj_xrefs") do
            register :report, {
              creator: Kiba::Tms::Jobs::ExhVenObjXrefs::Report,
              path: File.join(
                Kiba::Tms.datadir, "reports",
                "exhibited_object_at_venue_report.csv"
              ),
              tags: %i[exhibitions objects exh_ven_obj_xrefs]
            }
          end
        end
      end
    end
  end
end
