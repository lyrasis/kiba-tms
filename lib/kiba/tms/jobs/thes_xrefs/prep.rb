# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ThesXrefs
        module Prep
        module_function
        
        def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__thes_xrefs,
              destination: :prep__thes_xrefs,
              lookup: [:prep__thes_xref_types, :terms__descriptors, :prep__classification_notations]
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform FilterRows::FieldEqualTo, action: :reject, field: :active, value: '0'
            transform Delete::Fields, fields: %i[active removedloginid removeddate thesxrefid displayorder thesxreftableid]
            transform Merge::MultiRowLookup,
              keycolumn: :thesxreftypeid,
              lookup: prep__thes_xref_types,
              fieldmap: { thesxreftype: :thesxreftype }
            transform Delete::Fields, fields: :thesxreftypeid

            transform Tms::Transforms::TmsTableNames
            transform Rename::Field, from: :id, to: :table_row_id

            transform Merge::MultiRowLookup,
              keycolumn: :termid,
              lookup: terms__descriptors,
              fieldmap: { term: :term }

            transform Merge::MultiRowLookup,
              keycolumn: :primarycnid,
              lookup: prep__classification_notations,
              fieldmap: { notation: :cn }
            transform Delete::Fields, fields: :primarycnid
          end
        end
        end
      end
    end
  end
end
