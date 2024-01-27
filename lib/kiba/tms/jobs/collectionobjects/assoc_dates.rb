# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Collectionobjects
        module AssocDates
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_dates__merge_translated,
                destination: :collectionobjects__assoc_dates,
                lookup: :obj_dates__merge_translated
              },
              transformer: get_xforms
            )
          end

          def get_xforms
            base = [xforms]
            base.unshift(config.sample_xforms) if config.sampleable?
            base.compact
          end

          # @todo extract this to project specific config, since it may
          #   differ between projects
          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[objectnumber objectid]
              transform Deduplicate::Table,
                field: :objectid
              fieldmap = Tms::DatesTranslated.cs_date_fields
                .map { |field| [field, field] }
                .to_h
              transform Merge::MultiRowLookup,
                lookup: obj_dates__merge_translated,
                keycolumn: :objectid,
                fieldmap: fieldmap,
                delim: Tms.delim,
                sorter: Lookup::RowSorter.new(
                  on: :objdateid, as: :to_i
                )
              transform Delete::Fields,
                fields: %i[objectid]

              transform Merge::ConstantValue,
                target: :date_field_group,
                value: "assocStructuredDateGroup"
            end
          end
        end
      end
    end
  end
end
