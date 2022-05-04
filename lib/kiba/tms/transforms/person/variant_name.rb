# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Person
        class VariantName
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @null = '%NULLVALUE%'
            @var_name_field = Tms.constituents.alt_name_field
            @target = :var_termdisplayname
            @renamers = {
               var_name_field => target
             }.map{ |from, to| Rename::Field.new(from: from, to: to) }
            copier_map = {
              pref_salutation: :var_salutation,
              pref_title: :var_title,
              pref_forename: :var_forename,
              pref_middlename: :var_middlename,
              pref_surname: :var_surname,
              pref_nameadditions: :var_nameadditions
            }
            @copiers = copier_map.map{ |from, to| Copy::Field.new(from: from, to: to) }
            fields = [copier_map.values, :var_termflag, :var_termsourcenote, target].flatten
            fields << :var_termprefforlang if Tms.names.set_term_pref_for_lang
            fields << :var_termsource if Tms.names.set_term_source
            
            @constanters = fields.map{ |field| Merge::ConstantValue.new(target: field, value: null) }
          end

          # @private
          def process(row)
            var_name = row[var_name_field]
            if var_name.blank?
              constanters.each{ |constanter| constanter.process(row) }
              return row
            end
            
            renamers.each{ |renamer| renamer.process(row) }
            copiers.each{ |copier| copier.process(row) }
            row[:var_termsourcenote] = null
            flag = Tms.names.flag_variant_form ? 'variant form of name' : null
            row[:var_termflag] = flag
            row[:var_termprefforlang] = null if Tms.names.set_term_pref_for_lang
            row[:var_termsource] = term_source(row) if Tms.names.set_term_source
            row
          end
          
          private

          attr_reader :null, :var_name_field, :target, :renamers, :copiers, :constanters

          def term_source(row)
            src = row[:termsource]
            return 'Migration cleanup processing' if src.blank?
            return "#{src}.#{var_name_field}" if src == 'TMS Constituents'

            src
          end
        end
      end
    end
  end
end
