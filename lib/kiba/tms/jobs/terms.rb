# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Terms
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__terms,
              destination: :prep__terms,
              lookup: %i[prep__term_types prep__term_master]
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
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
              lookup: prep__term_master,
              fieldmap: {
                termsource: :termsource,
                termsourceid: :sourcetermid
              }
          end
        end

        def descriptors
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__terms,
              destination: :terms__descriptors
            },
            transformer: descriptors_xforms
          )
        end

        def descriptors_xforms
          Kiba.job_segment do
            transform FilterRows::FieldEqualTo, action: :keep, field: :termtype, value: 'Descriptor'
          end
        end
      end
    end
  end
end
