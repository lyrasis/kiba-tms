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
                fieldmap: { termtype: :termtype }
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
            end
          end
        end
      end
    end
  end
end
