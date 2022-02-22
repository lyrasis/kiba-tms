# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__alt_nums,
              destination: :prep__alt_nums
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::Fields, fields: %i[altnumid]
            transform Tms::Transforms::TmsTableNames
            transform Clean::RegexpFindReplaceFieldVals, fields: :description, find: '\\\\n', replace: ''
            transform Clean::RegexpFindReplaceFieldVals, fields: :all, find: '^(%CR%%LF%)+', replace: ''
            transform Clean::RegexpFindReplaceFieldVals, fields: :all, find: '(%CR%%LF%)+$', replace: ''
            transform Clean::DowncaseFieldValues, fields: :description
          end
        end

        def for_objects
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__alt_nums,
              destination: :alt_nums__for_objects
            },
            transformer: for_table_xforms(table: 'Objects')
          )
        end

        def for_refs
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__alt_nums,
              destination: :alt_nums__for_refs
            },
            transformer: for_table_xforms(table: 'ReferenceMaster')
          )
        end

        def for_constituents
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__alt_nums,
              destination: :alt_nums__for_constituents
            },
            transformer: for_table_xforms(table: 'Constituents')
          )
        end

        def for_table_xforms(table:)
          Kiba.job_segment do
            transform FilterRows::FieldEqualTo, action: :keep, field: :tablename, value: table
          end
        end

        def for_objects_todo
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :alt_nums__for_objects,
              destination: :alt_nums__for_objects_todo
            },
            transformer: for_objects_todo_xforms
          )
        end

        def for_objects_todo_xforms
          Kiba.job_segment do
            transform FilterRows::FieldPopulated, action: :keep, field: :endisodate
          end
        end

        def for_refs_todo
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :alt_nums__for_refs,
              destination: :alt_nums__for_refs_todo
            },
            transformer: for_refs_todo_xforms
          )
        end

        def for_refs_todo_xforms
          Kiba.job_segment do
            transform CombineValues::FromFieldsWithDelimiter,
              sources: %i[beginisodate endisodate],
              target: :combined,
              sep: '',
              delete_sources: false
            transform FilterRows::FieldPopulated, action: :keep, field: :combined
          end
        end

        def description_occs
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__alt_nums,
              destination: :alt_nums__description_occs,
              lookup: :prep__alt_nums
            },
            transformer: description_occs_xforms
          )
        end

        def description_occs_xforms
          Kiba.job_segment do
            transform FilterRows::FieldPopulated, action: :keep, field: :description
            transform Count::MatchingRowsInLookup,
              lookup: prep__alt_nums,
              keycolumn: :description,
              targetfield: :desc_occs
          end
        end

        def single_occ_description
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :alt_nums__description_occs,
              destination: :alt_nums__single_occ_description
            },
            transformer: single_occ_description_xforms
          )
        end

        def single_occ_description_xforms
          Kiba.job_segment do
            transform FilterRows::FieldEqualTo, action: :keep, field: :desc_occs, value: '1'
          end
        end

        def no_description
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__alt_nums,
              destination: :alt_nums__no_description
            },
            transformer: no_description_xforms
          )
        end

        def no_description_xforms
          Kiba.job_segment do
            transform FilterRows::FieldPopulated, action: :reject, field: :description
          end
        end

        def types
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :alt_nums__description_occs,
              destination: :alt_nums__types
            },
            transformer: types_xforms
          )
        end

        def types_xforms
          Kiba.job_segment do
            transform Delete::FieldsExcept, keepfields: %i[description tablename desc_occs]
            transform CombineValues::FromFieldsWithDelimiter, sources: %i[tablename description], target: :combined,
              sep: ': ', delete_sources: false
            transform Deduplicate::Table, field: :combined, delete_field: true
          end
        end
      end
    end
  end
end
