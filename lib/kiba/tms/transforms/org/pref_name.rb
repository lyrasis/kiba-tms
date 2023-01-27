# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Org
        class PrefName
          include Kiba::Extend::Transforms::Helpers

          def initialize
            @set_term_source = Tms::Names.set_term_source
            fieldmap = {
              name: :pref_termdisplayname
            }
            if set_term_source
              fieldmap[:termsource] = :pref_termsource
            end
            constantmap = {
              pref_termflag: Tms.nullvalue,
              pref_termsourcenote: Tms.nullvalue
            }
            if Tms::Names.set_term_pref_for_lang
              constantmap[:pref_termprefforlang] = 'true'
            end
            @xforms = [
              Rename::Fields.new(fieldmap: fieldmap),
              Replace::EmptyFieldValues.new(
                fields: fieldmap.values,
                value: Tms.nullvalue
              ),
              Merge::ConstantValues.new(constantmap: constantmap)
            ]
          end

          # @private
          def process(row)
            xforms.each{ |xform| xform.process(row) }
            row
          end

          private

          attr_reader :set_term_source, :xforms
        end
      end
    end
  end
end
