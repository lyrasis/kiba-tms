# frozen_string_literal: true

require 'csv'

module Kiba
  module Tms
    module Mixins
      # Mixin module providing consistent methods for accessing the db table for a config module
      #
      # ## Implementation details
      #
      # Modules mixing this in must:
      #
      # - `extend Dry::Configurable`
      # - define `delete_fields` (Array) and `empty_fields` (Hash) config settings
      # - `extend Tms::Mixins::Tableable`
      # - If the module name matches a TMS supplied table name, that is all
      # - If the module name does not match a TMS supplied table name, you must also define a
      #   `source_job_key` (the registry entry key of the job that produces the source data
      #   for the module you are configuring
      module Tableable
        def all_fields
          unless File.exist?(table_path)
            if respond_to?(:source_job_key) && Tms.registry.key?(source_job_key)
              Kiba::Extend::Command::Run.job(source_job_key)
            else
              []
            end
          end
          
          CSV.foreach(table_path)
            .first
            .map(&:downcase)
            .map(&:to_sym)
        end

        def delete_omitted_fields(hash)
          omitted_fields.each{ |field| hash.delete(field) if hash.key?(field) }
          hash
        end

        def emptyfields
          return [] unless empty_fields

          case empty_fields.class.to_s
          when 'Array'
            empty_fields
          when 'Hash'
            empty_fields.keys
          end
        end

        def fields
          return [] if all_fields.empty?

          all_fields - Tms.tms_fields - delete_fields - emptyfields
        end

        def filekey
          return nil unless used?

          table.filekey
        end

        def omitted_fields
          ( delete_fields + emptyfields ).uniq
        end

        def omitting_fields?
          true unless omitted_fields.empty?
        end

        def table_path
          table.type == :tms ? table.supplied_data_path : table.filename
        end
        
        def subtract_omitted_fields(arr)
          arr - omitted_fields
        end

        def table
          if Tms::Table::List.include?(table_name)
            Tms::Table::Obj.new(table_name)
          elsif self.respond_to?(:source_job_key)
            Tms::Table::Obj.new(source_job_key)
          else
            Tms::Table::Obj.new('UnknownTable')
          end
        end

        def table_name
          name.split('::').last
        end

        # whether or not table is used in client migration project
        def used
          used?
        end

        def used?
          if respond_to?(:populated)
            return populated ? true : false
          end

          table.included
        end
      end
    end
  end
end
