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
                  classification_notations__used
                  tms__thesaurus_bases
                  terms__preferred
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

              transform Merge::MultiRowLookup,
                keycolumn: :primarycnid,
                lookup: classification_notations__used,
                fieldmap: {
                  cn: :cn,
                  cn_nodedepth: :nodedepth,
                  cn_children: :children,
                  cn_rootleveltmid: :rootleveltmid,
                  cn_thesaurusbaseid: :thesaurusbaseid
                }
              transform Delete::Fields, fields: :primarycnid

              transform Merge::MultiRowLookup,
                keycolumn: :cn_thesaurusbaseid,
                lookup: tms__thesaurus_bases,
                fieldmap: {
                  thesaurus_name: :thesaurusbase,
                  thesaurus_version: :installedversion
                }
              transform Delete::Fields, fields: :cn_thesaurusbaseid

              transform Rename::Field,
                from: :term,
                to: :termused
              transform Merge::MultiRowLookup,
                lookup: terms__preferred,
                keycolumn: :preferredtermid,
                fieldmap: {termpreferred: :term}
            end
          end
        end
      end
    end
  end
end
