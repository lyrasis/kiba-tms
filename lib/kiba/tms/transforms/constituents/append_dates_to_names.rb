# frozen_string_literal: true

module Kiba::Tms::Transforms::Constituents
  class AppendDatesToNames
    include Kiba::Extend::Transforms::Helpers

    def initialize
      @name = Tms::Constituents.preferred_name_field
      @mode = Tms::Constituents.date_append_to_type
      @date_sep = Tms::Constituents.date_append_date_sep
      @name_date_sep = Tms::Constituents.date_append_name_date_sep
      @date_suffix = Tms::Constituents.date_append_date_suffix
      @date_getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
        fields: %i[birth_foundation_date death_dissolution_date]
      )
    end

    def process(row)
      @datevals = {}
      # prefer to skip running this transform in your job instead of
      #   passing all rows through a transform that is not going to do
      #   anything.
      return row if mode == :none

      append_dates(row) if appendable?(row)

      if mode == :duplicate
        %i[norm combined duplicate].each { |field| row.delete(field) }
      end

      row
    end

    private

    attr_reader :name, :mode, :date_sep, :name_date_sep, :date_suffix,
      :date_getter, :datevals

    def append_dates(row)
      nameval = row[name]
      date = construct_date(datevals)
      row[name] = "#{nameval}#{date}"
      row
    end

    def appendable?(row)
      name_appendable?(row) &&
        type_appendable?(row) &&
        date_appendable?(row)
    end

    def construct_date(dates)
      date_range = "#{dates[:birth_foundation_date]}#{date_sep}#{dates[:death_dissolution_date]}".strip
      "#{name_date_sep}#{date_range}#{date_suffix}"
    end

    def date_appendable?(row)
      @datevals = date_getter.call(row)
      return false if datevals.empty?

      true
    end

    def duplicate_appendable?(row)
      duplicate = row[:duplicate]
      return false if duplicate.blank?

      true if duplicate == "y"
    end

    def name_appendable?(row)
      nameval = row[name]
      return false if nameval.blank?

      true
    end

    def org?(row)
      type = row[:contype]
      return false if type.blank?

      true if type.start_with?("Org")
    end

    def person?(row)
      type = row[:contype]
      return false if type.blank?

      true if type["Person"]
    end

    def type_appendable?(row)
      case mode
      when :all
        true
      when :duplicate
        duplicate_appendable?(row)
      when :person
        person?(row)
      when :org
        org?(row)
      end
    end
  end
end
