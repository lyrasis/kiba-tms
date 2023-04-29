# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Works
        module FromObjectDepartments
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__departments,
                destination: :works__from_object_departments
              },
              transformer: xforms,
              helper: Tms::Works.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :tablename,
                value: "Objects"
              transform Delete::FieldsExcept, fields: :department
              transform Deduplicate::Table, field: :department
              if Tms::Objects.department_coll_prefix
                transform Prepend::ToFieldValue,
                  field: :department,
                  value: Tms::Objects.department_coll_prefix
              end
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :department, target: :norm
              transform Rename::Field, from: :department, to: :termdisplayname
              transform Merge::ConstantValue,
                target: :worktype,
                value: "Collection, Internal use"
              if Tms::Names.set_term_source
                transform Merge::ConstantValue,
                  target: :termsource,
                  value: "TMS Objects.department"
              end
            end
          end
        end
      end
    end
  end
end
