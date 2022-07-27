# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Org
        class VariantName
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @null = '%NULLVALUE%'
            @pref_name_field = :pref_termdisplayname
            @var_name_field = Tms::Constituents.var_name_field
            @target = :var_termdisplayname
            @renamers = {
               var_name_field => target
             }.map{ |from, to| Rename::Field.new(from: from, to: to) }

            fields = [:var_termflag, :var_termsourcenote, target]
            fields << :var_termprefforlang if Tms.names.set_term_pref_for_lang
            fields << :var_termsource if Tms.names.set_term_source
            
            @constanters = fields.map{ |field| Merge::ConstantValue.new(target: field, value: nil) }
          end

          # @private
          def process(row)
            var_name = row[var_name_field]
            if var_name.blank?
              return_nulls(row)
              return row 
            end

            pref_name = row[pref_name_field]
            if var_name == pref_name
              return_nulls(row)
              return row 
            end

            renamers.each{ |renamer| renamer.process(row) }

            row[:var_termsourcenote] = null
            flag = Tms.names.flag_variant_form ? 'variant form of name' : null
            row[:var_termflag] = flag
            row[:var_termprefforlang] = null if Tms.names.set_term_pref_for_lang
            row[:var_termsource] = term_source(row) if Tms.names.set_term_source
            row
          end
          
          private

          attr_reader :null, :pref_name_field, :var_name_field, :target, :renamers, :copiers, :constanters

          def return_nulls(row)
            constanters.each{ |constanter| constanter.process(row) }
            row.delete(var_name_field)
          end
          
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
