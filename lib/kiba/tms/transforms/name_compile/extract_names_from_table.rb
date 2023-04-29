# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class ExtractNamesFromTable
          # @param table [String]
          # @param fields [Array(Symbol)]
          def initialize(table:, fields:)
            @table = table
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields
            )
            @names = {}
            @namefield = Tms::Constituents.preferred_name_field
            @orgchecker = Tms::Services::Names::OrgNameChecker.new(field: namefield)
          end

          def process(row)
            vals = getter.call(row)
            return nil if vals.empty?

            populate_names(vals)
            nil
          end

          def close
            names.transform_values!{ |vals| vals.sort.join(".") }
            names.map{ |name, fields| build_name_row(name, fields) }
              .each{ |row| yield row }
          end

          private

          attr_reader :table, :getter, :names, :namefield, :orgchecker

          def add_source(field, name)
            target = names[name]
            return if target.any?(field)

            target << field
          end

          def build_name_row(name, fields)
            row = {
              namefield => name,
              termsource: "TMS #{table}.#{fields}",
              relation_type: "_main term",
              constituentid: "#{table}.#{name}"
            }
            row[:contype] = orgchecker.call(row) ? "Organization?" : nil
            row
          end

          def new_name(field, name)
            names[name] = [field]
          end

          def populate_names(vals)
            vals.each{ |field, name| populate_names_from(field, name) }
          end

          def populate_names_from(field, name)
            names.key?(name) ? add_source(field, name) : new_name(field, name)
          end
        end
      end
    end
  end
end
