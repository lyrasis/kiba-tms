# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ForTable
        extend Tms::Mixins::ForTable
        module_function

        def job(source:, dest:, targettable:, field: :tablename, xforms: [])
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: source,
              destination: dest
            },
            transformer: for_table_xforms(table: targettable, field: field, xforms: [])
          )
        end
      end
    end
  end
end

