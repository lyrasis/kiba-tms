# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Person
        class VariantName
          include Kiba::Extend::Transforms::Helpers

          def initialize(lookup:)
            fieldmap = {
              var_termdisplayname: :variant_term,
              var_salutation: :salutation,
              var_title: :nametitle,
              var_forename: :firstname,
              var_middlename: :middlename,
              var_surname: :lastname,
              var_nameadditions: :suffix,
              var_termflag: :variant_qualifier
            }
            if Tms::Names.set_term_source
              fieldmap[:var_termsource] = :termsource
            end

            constantmap = {
              var_termsourcenote: Tms.nullvalue
            }
            if Tms::Names.set_term_pref_for_lang
              constantmap[:var_termprefforlang] = 'false'
            end
            @xforms = [
              Merge::MultiRowLookup.new(
                lookup: lookup,
                keycolumn: :namemergenorm,
                fieldmap: fieldmap,
                constantmap: constantmap,
                conditions: ->(_pref, rows) do
                  rows.select{ |row| row[:contype] &&
                      row[:contype].start_with?('Person') }
                end,
                delim: Tms.delim,
                null_placeholder: Tms.nullvalue
              )
              ]
          end

          def process(row)
            xforms.each{ |xform| xform.process(row) }
            row
          end

          private

          attr_reader :xforms
        end
      end
    end
  end
end
