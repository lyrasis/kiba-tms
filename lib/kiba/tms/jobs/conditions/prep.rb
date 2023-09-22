# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Conditions
        module Prep
          module_function

          def desc
            "- Deletes TMS fields\n"\
              "- Delete config empty and deleted fields\n"\
              "- Merge in number of related CondLineItem rows\n"\
              "- Delete rows with no content_field values and "\
              "no CondLineItem rows"\
              "- Merge in examiner names from Constituents\n"\
              "- Merge in TMS table names\n"\
              "- Merge in object numbers for Objects rows\n"\
              "- Merge in survey type\n"\
              "- Merge in overall conditions\n"\
              "- Merge TextEntries if they exist\n"
          end

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__conditions,
                destination: :prep__conditions,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
              objects__number_lookup
              names__by_constituentid
            ]
            base << :prep__survey_types if Tms::SurveyTypes.used?
            base << :prep__overall_conditions if Tms::OverallConditions.used?
            base << :tms__cond_line_items if Tms::CondLineItems.used?
            base.select { |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner

              if lookups.any?(:tms__cond_line_items)
                transform Count::MatchingRowsInLookup,
                  lookup: tms__cond_line_items,
                  keycolumn: :conditionid,
                  targetfield: :condlineitem_ct,
                  result_type: :int
              else
                transform Merge::ConstantValue,
                  target: :condlineitem_ct,
                  value: 0
              end
              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.content_fields,
                target: :index,
                delim: " ",
                delete_sources: false
              transform FilterRows::WithLambda,
                action: :reject,
                lambda: ->(row) {
                  (row[:index].blank? || row[:index].match?(/^[ 0]+$/)) &&
                    row[:condlineitem_ct] == 0
                }
              transform Delete::Fields, fields: :index

              transform Tms::Transforms::TmsTableNames

              # We handle this here with conditional logic so that prepped
              #   table will be as human-readable as possible
              if lookups.any?(:objects__number_lookup)
                transform Merge::MultiRowLookup,
                  lookup: objects__number_lookup,
                  keycolumn: :id,
                  fieldmap: {objectnumber: :objectnumber},
                  conditions: ->(row, rows) {
                    (row[:tablename] == "Objects") ? rows : []
                  }
              end
              # If any other target tables exist, add their conditional number
              #   lookups before deleting :id
              transform Delete::Fields, fields: :id

              if lookups.any?(:names__by_constituentid)
                %i[person org].each do |type|
                  transform Merge::MultiRowLookup,
                    lookup: names__by_constituentid,
                    keycolumn: :examinerid,
                    fieldmap: {"examiner_#{type}".to_sym => type}
                end
              end
              transform Delete::Fields, fields: :examinerid

              if lookups.any?(:prep__survey_types)
                transform Merge::MultiRowLookup,
                  lookup: prep__survey_types,
                  keycolumn: :surveytypeid,
                  fieldmap: {survey_type: :surveytype}
              end
              transform Delete::Fields, fields: :surveytypeid

              if lookups.any?(:prep__overall_conditions)
                transform Merge::MultiRowLookup,
                  lookup: prep__overall_conditions,
                  keycolumn: :overallconditionid,
                  fieldmap: {overallcondition: :overallcondition}
              end
              transform Delete::Fields, fields: :overallconditionid

              if Tms::TextEntries.for?("Conditions") &&
                  Tms::TextEntriesForConditions.merger_xforms
                Tms::TextEntriesForConditions.merger_xforms.each do |xform|
                  transform xform
                end
              end
            end
          end
        end
      end
    end
  end
end
