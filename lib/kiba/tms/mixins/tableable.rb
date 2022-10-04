# frozen_string_literal: true

require 'csv'

module Kiba
  module Tms
    module Mixins
      # Mixin module providing consistent methods for accessing the db or derived
      #   table for a config module
      #
      # - defines `delete_fields` (Array) and `empty_fields` (Hash) config
      #   settings if they are not manually set in the config module
      #
      # ## Implementation details
      #
      # Modules mixing this in must:
      #
      # - `extend Dry::Configurable`
      # - `extend Tms::Mixins::Tableable`
      # - **If the module name does not match a TMS supplied table name**, you must
      #   also define a `source_job_key` (the registry entry key of the job that
      #   produces the source data for the module you are configuring
      module Tableable
        def self.extended(mod)
          self.set_delete_fields_setting(mod)
          self.set_empty_fields_setting(mod)
          self.set_non_content_fields_setting(mod)
          self.check_source_job_key(mod)
        end

        def is_tableable?
          true
        end

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

        # non-omitting, non-fields that are not ids or other non-primary content
        #   bearing fields
        def content_fields
          fields - non_content_fields
        end

        def delete_omitted_fields(hash)
          omitted_fields.each{ |field| hash.delete(field) if hash.key?(field) }
          hash
        end

        def empty_candidates
          all_fields - delete_fields - Tms.tms_fields - non_content_fields
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
          base = ( delete_fields + emptyfields ).uniq
          return base unless all_fields.any?(:conservationentityid)

          unless Tms::ConservationEntities.used?
            base << :conservationentityid
          end
          base
        end

        def omitting_fields?
          true unless omitted_fields.empty?
        end

        def table_path
          table.type == :tms ? table.supplied_data_path : table.filename
        end

        def supplied?
          return false if table.tablename == 'UnknownTable'

          true if table.type == :tms
        end

        def subtract_omitted_fields(arr)
          arr - omitted_fields
        end

        def table
          if Tms::Table::List.all.any?(table_name)
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

        def self.check_source_job_key(mod)
          return if mod.supplied?
          return if mod.respond_to?(:source_job_key)

          warn("#{mod} needs :source_job_key defined before extending Tableable")
        end
        private_class_method :check_source_job_key

        def self.set_delete_fields_setting(mod)
          return if mod.respond_to?(:delete_fields)

          mod.module_eval('setting :delete_fields, default: [], reader: true')
        end
        private_class_method :set_delete_fields_setting

        def self.set_empty_fields_setting(mod)
          return if mod.respond_to?(:empty_fields)

          mod.module_eval('setting :empty_fields, default: {}, reader: true')
        end

        def self.set_non_content_fields_setting(mod)
          return if mod.respond_to?(:non_content_fields)

          mod.module_eval('setting :non_content_fields, default: [], reader: true')
        end
      end
    end
  end
end
