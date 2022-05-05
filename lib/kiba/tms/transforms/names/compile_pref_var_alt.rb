# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Names
        class CompilePrefVarAlt
          def initialize(authority_type:)
            @type = authority_type
            @prefixes = %w[pref var alt]
            @combiners = generate_combiners
          end

          # @private
          def process(row)
            combiners.each{ |combiner| combiner.process(row) }
            row
          end
          
          private

          attr_reader :type, :prefixes, :combiners

          def base_fields
            %w[termdisplayname termflag termsourcenote]
          end
          
          def fields
            case type
            when :person
              list = [base_fields, person_fields].flatten
            when :org
              list = base_fields
            end
            list << 'termprefforlang' if Tms.names.set_term_pref_for_lang
            list << 'termsource' if Tms.names.set_term_source
            list
          end

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

          def person_fields
            %w[salutation title forename middlename surname nameadditions]
          end

          def prefixed(field)
            prefixes.map{ |prefix| "#{prefix}_#{field}".to_sym }
          end
        end
      end
    end
  end
end
