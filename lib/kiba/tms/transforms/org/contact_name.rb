# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Org
        class ContactName
          include Kiba::Extend::Transforms::Helpers

          def initialize(lookup:)
            fieldmap = {
              contactname: :related_term,
              contactrole: :related_role
            }
            @xforms = [
              Merge::MultiRowLookup.new(
                lookup: lookup,
                keycolumn: :namemergenorm,
                fieldmap: fieldmap,
                delim: Tms.delim,
                null_placeholder: Tms.nullvalue
              )
            ]
          end

          def process(row)
            xforms.each { |xform| xform.process(row) }
            row
          end

          private

          attr_reader :xforms
        end
      end
    end
  end
end
