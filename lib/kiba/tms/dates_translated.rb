# frozen_string_literal: true

module Kiba
  module Tms
    module DatesTranslated
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      def used?
        !lookup_sources.empty?
      end

      setting :cs_date_fields,
        default: %i[datedisplaydate dateperiod dateassociation datenote
                    dateearliestsingleyear dateearliestsinglemonth
                    dateearliestsingleday dateearliestsingleera
                    dateearliestsinglecertainty dateearliestsinglequalifier
                    dateearliestsinglequalifiervalue
                    dateearliestsinglequalifierunit datelatestyear
                    datelatestmonth datelatestday datelatestera
                    datelatestcertainty datelatestqualifier
                    datelatestqualifiervalue datelatestqualifierunit
                    dateearliestscalarvalue datelatestscalarvalue
                    scalarvaluescomputed],
        reader: true

      # Name of file(s) to be compiled into CS detailed date field lookup table.
      #   Must have an `:orig` column, containing date string that has been
      #   translated into CS date details. Assumed to be in the `supplied`
      #   directory
      setting :lookup_sources,
        default: [],
        reader:true,
        constructor: ->(value){
          value.map{ |file| "#{Tms.datadir}/supplied/#{file}" }
        }

      def lookup_source_jobs
        lookup_sources.map.with_index do |src, idx|
          "dates_translated__source_orig_#{idx}".to_sym
        end
      end

      def merge_fieldmap(target_prefix = "")
        cs_date_fields.map{ |field|
          prefix = target_prefix.empty? ? "" : "#{target_prefix}_"
          ["#{prefix}#{field}".to_sym, field]
        }.to_h
      end

      def merge_xforms(keycolumn:, target_prefix: "")
        fieldmap = merge_fieldmap(target_prefix)
        date_fields = cs_date_fields

        Kiba.job_segment do
          transform Merge::MultiRowLookup,
            lookup: dates_translated__lookup,
            keycolumn: keycolumn,
            fieldmap: fieldmap,
            multikey: true,
            null_placeholder: Tms.nullvalue,
            delim: Tms.delim
          transform Delete::EmptyFieldValues,
            fields: date_fields,
            delim: Tms.delim,
            usenull: true
          transform Delete::EmptyFields
          # transform Delete::Fields, fields: keycolumn
          # transform Clean::EnsureConsistentFields
        end
      end
    end
  end
end
