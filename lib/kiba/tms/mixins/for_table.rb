# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Defines transforms for "for_table" jobs defined by
      #   {MultiTableMergable}. Transforms are defined dynamically
      #   based on config derived from the module that extends
      #   {MultiTableMergable}. {Kiba::Tms::AltNums} is an example of
      #   a {MultiTableMergable} module.
      module ForTable
        module_function

        # @param table [String]
        # @param field [Symbol]
        # @param xforms [Array] of transform classes
        def for_table_xforms(table:, field: :tablename, xforms: [])
          Kiba.job_segment do
            transform FilterRows::FieldEqualTo,
              action: :keep,
              field: field,
              value: table
            unless xforms.empty?
              xforms.each { |xform| transform xform }
            end
            transform Delete::EmptyFields
          end
        end

        def reportable_for_table_xforms(config)
          Kiba.job_segment do
            transform Merge::MultiRowLookup,
              lookup: send(config[:sourcejob]),
              keycolumn: :recordid,
              fieldmap: {config[:numberfield] => config[:numberfield]}
          end
        end
      end
    end
  end
end
