# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Mixin module for use in job-definition modules
      #
      # See AltNums jobs as a model for use
      module ForTable
        module_function

        # @param table [String]
        # @param field [Symbol]
        # @param xforms [Array] of transform classes
        def for_table_xforms(table:, field: :tablename, xforms: [])
          Kiba.job_segment do
            transform FilterRows::FieldEqualTo, action: :keep, field: field, value: table
            unless xforms.empty?
              xforms.each{ |xform| transform xform }
            end
          end
        end

        def reportable_for_table_xforms(config)
          Kiba.job_segment do
            transform Merge::MultiRowLookup,
              lookup: send(config[:sourcejob]),
              keycolumn: :recordid,
              fieldmap: {config[:numberfield]=>config[:numberfield]}
          end
        end
      end
    end
  end
end
