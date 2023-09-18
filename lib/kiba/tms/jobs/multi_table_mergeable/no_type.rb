# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MultiTableMergeable
        module NoType
          module_function

          # @param source [Symbol] a reportable for table like
          #   :alt_nums_reportable_for__objects
          # @param dest [Symbol] like
          #   :alt_nums_reportable_for__objects_no_type
          # @param mod [Module] mergeable module
          def job(source:, dest:, mod:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source,
                destination: dest
              },
              transformer: xforms(mod)
            )
          end

          def xforms(mod)
            Kiba.job_segment do
              typefield = mod.type_field

              transform FilterRows::FieldPopulated,
                action: :reject,
                field: typefield
              transform Rename::Field,
                from: typefield,
                to: mod.type_field_target
            end
          end
        end
      end
    end
  end
end
