# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module ExternalDatesMerged
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__objects,
                destination: :objects__dates,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :obj_context__dates if Tms::ObjContext.used? &&
              !Tms::ObjContext.date_fields.empty?
            base << :prep__obj_dates if Tms::ObjDates.used?
            base.select { |job| Tms.job_output?(job) }
          end

          def content_fields
            base = config.date_fields.dup
            if lookups.any?(:obj_context__dates)
              base << Tms::ObjContext.date_fields
            end
            if lookups.any?(:prep__obj_dates)
              base << Tms::ObjDates.content_fields
            end
            base.flatten
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              lookups = bind.receiver.send(:lookups)

              keep = %i[objectid objectnumber] + config.date_fields
              transform Delete::FieldsExcept, fields: keep
              transform Delete::FieldValueMatchingRegexp,
                fields: config.date_fields,
                match: "^0$"

              if lookups.any?(:obj_context__periods)
                transform Merge::MultiRowLookup,
                  lookup: obj_context__periods,
                  keycolumn: :objectid,
                  fieldmap: Tms::ObjContext.date_or_chronology_fields
                    .map { |field| [field, field] }
                    .to_h
              end

              if lookups.any?(:prep__obj_dates)
                warn("Need to implement merge obj_dates into objects__dates")
              end

              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: bind.receiver.send(:content_fields)

              if config.date_field_cleaner
                transform config.date_field_cleaner
              end
            end
          end
        end
      end
    end
  end
end
