# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Person
        class PrefName
          include Kiba::Extend::Transforms::Helpers

          def initialize
            @set_term_source = Tms::Names.set_term_source
            fieldmap = {
              name: :pref_termdisplayname,
              salutation: :pref_salutation,
              nametitle: :pref_title,
              firstname: :pref_forename,
              middlename: :pref_middlename,
              lastname: :pref_surname,
              suffix: :pref_nameadditions,
              birth_foundation_date: :birthdategroup,
              death_dissolution_date: :deathdategroup
            }
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
            if set_term_source
              row[:pref_termsource] = term_source(row)
            end
            xforms.each{ |xform| xform.process(row) }
            row
          end

          private

          attr_reader :set_term_source, :xforms

          def term_source(row)
            src = row[:termsource]
            return 'Migration cleanup processing' if src.blank?

            src
          end
        end
      end
    end
  end
end
