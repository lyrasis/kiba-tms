# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ThesXrefs
        extend self

        def for_term_report
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__thes_xrefs,
              destination: :thes_xrefs__for_term_report
            },
            transformer: for_term_report_xforms
          )
        end

        def for_term_report_xforms
          Kiba.job_segment do
            transform Delete::Fields, fields: %i[table_row_id remarks]
            transform CombineValues::FromFieldsWithDelimiter, sources: %i[tablename thesxreftype], target: :term_usage,
              sep: '/', delete_sources: true
          end
        end

        def with_notation
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :thes_xrefs__for_term_report,
              destination: :thes_xrefs__with_notation
            },
            transformer: with_notation_xforms
          )
        end

        def with_notation_xforms
          Kiba.job_segment do
            transform FilterRows::FieldPopulated, action: :keep, field: :notation
          end
        end

        def with_notation_usage_type_lookup
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :thes_xrefs__with_notation,
              destination: :thes_xrefs__with_notation_usage_type_lookup
            },
            transformer: with_notation_usage_type_lookup_xforms
          )
        end

        def with_notation_usage_type_lookup_xforms
          Kiba.job_segment do
            transform Delete::Fields, fields: %i[term]
            transform CombineValues::FromFieldsWithDelimiter, sources: %i[notation term_usage], target: :combined,
              sep: ' ', delete_sources: false
            transform Deduplicate::Table, field: :combined, delete_field: true
          end
        end

        def with_notation_uniq
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :thes_xrefs__with_notation,
              destination: :thes_xrefs__with_notation_uniq
            },
            transformer: with_notation_uniq_xforms
          )
        end

        def with_notation_uniq_xforms
          Kiba.job_segment do
            transform Deduplicate::Table, field: :notation, delete_field: false
          end
        end

        def with_notation_uniq_typed
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :thes_xrefs__with_notation_uniq,
              destination: :thes_xrefs__with_notation_uniq_typed,
              lookup: :thes_xrefs__with_notation_usage_type_lookup
            },
            transformer: with_notation_uniq_typed_xforms
          )
        end

        def with_notation_uniq_typed_xforms
          Kiba.job_segment do
            transform Merge::MultiRowLookup,
              keycolumn: :notation,
              lookup: thes_xrefs__with_notation_usage_type_lookup,
              fieldmap: { term_usage: :term_usage },
              delim: Tms.delim
          end
        end

        def without_notation
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :thes_xrefs__for_term_report,
              destination: :thes_xrefs__without_notation
            },
            transformer: without_notation_xforms
          )
        end

        def without_notation_xforms
          Kiba.job_segment do
            transform FilterRows::FieldPopulated, action: :reject, field: :notation
          end
        end

        def without_notation_usage_type_lookup
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :thes_xrefs__without_notation,
              destination: :thes_xrefs__without_notation_usage_type_lookup
            },
            transformer: without_notation_usage_type_lookup_xforms
          )
        end

        def without_notation_usage_type_lookup_xforms
          Kiba.job_segment do
            transform Delete::Fields, fields: %i[notation]
            transform CombineValues::FromFieldsWithDelimiter, sources: %i[term term_usage], target: :combined,
              sep: ' ', delete_sources: false
            transform Deduplicate::Table, field: :combined, delete_field: true
          end
        end
        
        def without_notation_uniq
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :thes_xrefs__without_notation,
              destination: :thes_xrefs__without_notation_uniq
            },
            transformer: without_notation_uniq_xforms
          )
        end

        def without_notation_uniq_xforms
          Kiba.job_segment do
            transform Replace::EmptyFieldValues, fields: :term, value: '%NULLVALUE%'
            transform Deduplicate::Table, field: :term, delete_field: false
          end
        end

        def without_notation_uniq_typed
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :thes_xrefs__without_notation_uniq,
              destination: :thes_xrefs__without_notation_uniq_typed,
              lookup: :thes_xrefs__without_notation_usage_type_lookup
            },
            transformer: without_notation_uniq_typed_xforms
          )
        end

        def without_notation_uniq_typed_xforms
          Kiba.job_segment do
            transform Merge::MultiRowLookup,
              keycolumn: :term,
              lookup: thes_xrefs__without_notation_usage_type_lookup,
              fieldmap: { term_usage: :term_usage },
              delim: Tms.delim
          end
        end
      end
    end
  end
end
