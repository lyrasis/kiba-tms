# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Terms
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :terms__used_row_data,
                destination: :prep__terms,
                lookup: %i[
                  prep__term_types
                  term_master_thes__used_in_xrefs
                  terms__preferred
                  prep__dd_languages
                ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields, fields: %i[displayorder systemgenerated]

              transform Merge::MultiRowLookup,
                keycolumn: :termtypeid,
                lookup: prep__term_types,
                fieldmap: {termtype: :termtype}
              transform Delete::Fields, fields: :termtypeid

              transform Merge::MultiRowLookup,
                lookup: prep__dd_languages,
                keycolumn: :languageid,
                fieldmap: {language: :language}
              transform Delete::Fields, fields: :languageid

              transform Merge::MultiRowLookup,
                keycolumn: :termmasterid,
                lookup: term_master_thes__used_in_xrefs,
                fieldmap: {
                  termclassid: :termclassid,
                  description: :description,
                  guideterm: :guideterm,
                  primarycnid: :primarycnid,
                  preferredtermid: :preferredtermid,
                  termsource: :termsource,
                  sourcetermid: :sourcetermid
                }

              if Tms::TextEntries.for?("TermMasterThes")
                transform Tms::Transforms::TextEntries::ForTermMasterThesMerger
              end

              transform Delete::Fields, fields: :primarycnid

              transform Rename::Field,
                from: :term,
                to: :termused
              transform Merge::MultiRowLookup,
                lookup: terms__preferred,
                keycolumn: :preferredtermid,
                fieldmap: {termpreferred: :term}
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
