# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Mixin module
      #
      # Modules including this should have the following methods defined:
      #
      # - :target_tables (Array)
      module MultiTableMergeable
        def for?(table)
          target_tables.any?(table)
        end

        def build_registry_namespace(ns_name, targets, field)
          Dry::Container::Namespace.new(ns_name) do
            targets.each do |target|
              targetobj = Tms::Table::Obj.new(target)
              register targetobj.filekey, Tms::Mixins::MultiTableMergeable.target_job_hash(ns_name, targetobj, field)
            end
          end
        end

        def self.target_job_hash(ns_name, targetobj, field)
          key = targetobj.filekey
          tags = [ns_name, key].map(&:to_s)
            .map{ |val| val.gsub('_', '') }
            .map(&:to_sym)
          tabletag = tags.shift
          tags << tabletag.to_s.delete_suffix('_for').to_sym
          
          {
            path: File.join(Tms.datadir, 'working', "#{ns_name}_#{key}.csv"),
            creator: {callee: Tms::Jobs::ForTable,
                      args: {
                        source: "prep_#{ns_name}".to_sym,
                        dest: "#{ns_name}__#{key}".to_sym,
                        targettable: targetobj.tablename,
                        field: field
                      }
                     },
            tags: tags
          }
        end
        
        def register_per_table_jobs(field = :tablename)
          key = filekey
          return unless key

          ns_name = "#{key}_for"
          targets = target_tables
          Tms.registry.import(build_registry_namespace(ns_name, targets, field))
        end
      end
    end
  end
end
