# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Names
        class CompilePrefVarAlt
          def initialize
            @prefixes = %w[pref var alt]
            @fields = %w[termdisplayname salutation title forename middlename surname nameadditions termflag termsourcenote]
            @fields << 'termprefforlang' if Tms.names.set_term_pref_for_lang
            @fields << 'termsource' if Tms.names.set_term_source
            @combiners = generate_combiners
          end

          # @private
          def process(row)
            combiners.each{ |combiner| combiner.process(row) }
            row
          end
          
          private

          attr_reader :prefixes, :fields, :combiners

          def generate_combiners
            fields.map do |field|
              CombineValues::FromFieldsWithDelimiter.new(
                sources: prefixed(field),
                target: field.to_sym,
                sep: Tms.delim,
                delete_sources: true
              )
            end
          end

          def prefixed(field)
            prefixes.map{ |prefix| "#{prefix}_#{field}".to_sym }
          end
        end
      end
    end
  end
end
