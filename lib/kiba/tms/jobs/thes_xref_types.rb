# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ThesXrefTypes
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__thes_xref_types,
              destination: :prep__thes_xref_types
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::Fields, fields: %i[multiselect archivedeletes showguideterms broadesttermfirst
                                                 numlevels alwaysdisplayfullpath]
            transform FilterRows::FieldMatchRegexp, action: :reject, field: :thesxreftype, value: '^\([Nn]ot [Aa]ssigned\)$'
            transform FilterRows::FieldPopulated, action: :keep, field: :term
          end
        end
      end
    end
  end
end
