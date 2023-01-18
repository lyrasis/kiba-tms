# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module NameTypeCleanup
      module_function

      extend Dry::Configurable

      setting :source_job_key,
        default: :name_type_cleanup__from_base_data,
        reader: true

      extend Tms::Mixins::Tableable

      def used?
        true
      end

      # Indicates whether any cleanup has been returned. If not, we run
      #   everything on base data. If yes, we merge in/overlay cleanup on the
      #   affected base data tables
      setting :done, default: false, reader: true

      setting :untyped_treatment,
        default: 'Person',
        reader: true
      # Client-specific transform to clean returned worksheet before any further
      #   processing is done
      setting :returned_cleaner, default: nil, reader: true
      # List returned worksheets, most recent first. Assumes they are in the
      #   client project directory/supplied subdir
      setting :returned_files,
        default: [],
        reader: true,
        constructor: proc{ |value| value.map do |filename|
              File.join(Kiba::Tms.datadir, 'supplied', filename)
            end
        }

      setting :targets, default: [], reader: true

      setting :configurable, default: {
        targets: proc{ Tms::Services::NameTypeCleanup::TargetsDeriver.call }
      },
        reader: true

      def initial_headers
        base = %i[
                  name correctname authoritytype correctauthoritytype termsource
                  constituentid
                 ]
        base.unshift(:to_review) if done
        base
      end

      def returned_file_jobs
        returned_files.map.with_index do |filename, idx|
          "name_type_cleanup__worksheet_completed_#{idx}".to_sym
        end
      end

      # worksheet version stuff
      def prev_worksheet_exist?
        File.exist?(prev_worksheet_path)
      end

      def prev_worksheet_path
        base = worksheet_path.delete_suffix('.csv')
        "#{base}_prev.csv"
      end

      def worksheet_path
        Tms.registry
          .resolve(:name_type_cleanup__worksheet)
          .path
          .to_s
      end


      # def register_uncontrolled_ntc_jobs
      #   ns = build_registry_namespace(
      #     "name_type_cleanup_for",
      #     Tms::NameCompile.uncontrolled_name_source_tables.keys
      #       .map{ |n| Tms.const_get(n) }
      #       .select{ |mod| mod.used? }
      #   )
      #   Tms.registry.import(ns)
      # end

      # def build_registry_namespace(ns_name, tables)
      #   bind = binding
      #   Dry::Container::Namespace.new(ns_name) do
      #     compilemod = bind.receiver
      #     tables.each do |tablemod|
      #       params = [compilemod, ns_name, tablemod]
      #       register tablemod.filekey, compilemod.send(:target_job_hash, *params)
      #     end
      #   end
      # end

      # def target_job_hash(compilemod, ns_name, tablemod)
      #   {
      #     path: File.join(Tms.datadir,
      #                     'working',
      #                     "#{ns_name}_#{tablemod.filekey}.csv"
      #                    ),
      #     creator: {callee: Tms::Jobs::NameTypeCleanup::ForUncontrolledNameTable,
      #               args: {
      #                 mod: tablemod
      #               }
      #              },
      #     tags: %i[nametypecleanup nametypecleanupfor],
      #     lookup_on: :constituentid
      #   }
      # end
    end
  end
end
