# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Names
        class CompilePrefVarAlt
          def initialize(authority_type:, prefixes: nil)
            @type = authority_type
            @prefixes = get_prefixes(prefixes)
            @combiners = generate_combiners
          end

          # @private
          def process(row)
            combiners.each{ |combiner| combiner.process(row) }
            clean_up_variants(row)
            row
          end
          
          private

          attr_reader :type, :prefixes, :combiners

          def base_fields
            %w[termdisplayname termflag termsourcenote]
          end

          def clean_up_variants(row)
            return unless type == :person
            return if Tms.constituents.include_flipped_as_variant

            fields.map{ |field| "var_#{field}".to_sym}
              .each{ |field| row.delete(field) }
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

          def get_prefixes(prefixes)
            return prefixes if prefixes
            return %w[pref alt] if type == :person && Tms.constituents.include_flipped_as_variant == false
            
            %w[pref var alt]
          end

          def person_fields
            %w[salutation title forename middlename surname nameadditions]
          end

          def prefixed(field)
            prefixes.map{ |prefix| "#{prefix}_#{field}".delete_prefix('_').to_sym }
          end
        end
      end
    end
  end
end
