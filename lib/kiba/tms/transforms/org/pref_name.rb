# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Org
        class PrefName
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @pref_name = Tms::Constituents.preferred_name_field
            @set_term_source = Tms.names.set_term_source
            @null = '%NULLVALUE%'
            map = {
              pref_name => :pref_termdisplayname
            }
            
            @renamers = map.map{ |from, to| Rename::Field.new(from: from, to: to) }

            @nullvaluer = Replace::EmptyFieldValues.new(
              fields: map.values,
              value: null
            )
          end

          # @private
          def process(row)
            row[:pref_termsource] = term_source(row) if set_term_source
            renamers.each{ |renamer| renamer.process(row) }
            nullvaluer.process(row)
            row[:pref_termflag] = null
            row[:pref_termsourcenote] = null
            if Tms.names.set_term_pref_for_lang
              row[:pref_termprefforlang] = 'true'
            end
            row
          end
          
          private

          attr_reader :pref_name, :set_term_source, :null, :renamers, :nullvaluer

          def term_source(row)
            src = row[:termsource]
            return 'Migration cleanup processing' if src.blank?
            return "#{src}.#{pref_name}" if src == 'TMS Constituents'

            src
          end
          
        end
      end
    end
  end
end
