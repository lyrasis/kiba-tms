# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module NotesUncontrolledForNormLookup
          module_function

          def job
            return unless Tms::NameCompile.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__from_uncontrolled_name_tables,
                destination: :name_compile__notes_uncontrolled_for_norm_lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::Names::AddDefaultContype
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  contype = row[:contype]
                  contype &&
                    contype.start_with?('Note')
                end

              transform Rename::Field,
                from: Tms::Constituents.preferred_name_field,
                to: :name
              transform Delete::FieldsExcept,
                fields: %i[name prefnormorig contype]
            end
          end
        end
      end
    end
  end
end
