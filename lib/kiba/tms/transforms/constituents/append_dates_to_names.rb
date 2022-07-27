# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class AppendDatesToNames
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @name = Kiba::Tms::Constituents.preferred_name_field
            @appendable = Kiba::Tms::Constituents.date_append.to_types
            @date_sep = Kiba::Tms::Constituents.date_append.date_sep
            @name_date_sep = Kiba::Tms::Constituents.date_append.name_date_sep
            @date_suffix = Kiba::Tms::Constituents.date_append.date_suffix
          end

          def process(row)
            # prefer to skip running this transform in your job instead of passing all rows through
            #   a transform that is not going to do anything.
            return row if appendable == [:none]

            return append_dates(row) if appendable == [:all]

            appendable?(row) ? append_dates(row) : row
          end

          private

          attr_reader :name, :appendable, :date_sep, :name_date_sep, :date_suffix

          def append_dates(row)
            name_val = row.fetch(name, nil)
            return row if name_val.blank?
            
            dates = field_values(row: row, fields: %i[begindateiso enddateiso])
            return row if dates.empty?

            date = construct_date(dates)
            row[name] = "#{name_val}#{date}"
            row
          end
          
          def construct_date(dates)
            date_range = "#{dates[:begindateiso]}#{date_sep}#{dates[:enddateiso]}".strip
            "#{name_date_sep}#{date_range}#{date_suffix}"
          end

          def appendable?(row)
            type = row.fetch(:constituenttype, nil)
            appendable.any?(type)
          end
        end
      end
    end
  end
end
