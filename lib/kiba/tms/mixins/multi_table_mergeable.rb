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

        # METHODS USED FOR RUNNING CHECKS
        #
        # Reports if there is a target_table with no matching setting defined in the config
        def check_needed_table_transform_settings
          needed = target_transform_settings_expected.reject{ |transform| self.respond_to?(transform) }
          return nil if needed.empty?

          "#{self.name}: add config settings: #{needed.join(', ')}"
        end

        # Reports if a defined for-target-table transform setting defined in the config,
        #   but no value (an actual transform class or :no_xform) has been assigned to the
        #   setting. These indicate there may be more work to be done.
        def check_undefined_table_transforms
          undefined = target_transform_settings - target_transform_settings_handled
          return nil if undefined.empty?

          "#{self.name}: no transforms defined for: #{undefined.join(', ')}"
        end
        
        def target_transform_settings
          self.settings
            .map(&:to_s)
            .select{ |meth| meth.match?(/^for_.*_transform$/) }
        end

        # These are defined with actual transform classes
        def target_transform_settings_defined
          target_transform_settings.reject do |setting|
            val = config.values[setting]
            val.nil? || val == :no_xform
          end
        end
        
        def target_transform_settings_expected
          target_tables.map do |target|
            tobj = Tms::Table::Obj.new(target)
            "for_#{tobj.filekey}_transform".to_sym
          end
        end

        # These are defined with actual transform classes or :no_xform placeholders to indicate
        #   we have analyzed the data and found no need for a specific transform
        def target_transform_settings_handled
          target_transform_settings.reject{ |setting| config.values[setting].nil? }
        end

        # Methods used for auto-registering for-table jobs
        def register_per_table_jobs(field = :tablename)
          key = filekey
          return unless key

          ns = build_registry_namespace(
            "#{key}_for",
            target_tables,
            field,
            target_transform_settings_defined
          )
          Tms.registry.import(ns)
        end
        
        def build_registry_namespace(ns_name, targets, field, xforms)
          bind = binding
          Dry::Container::Namespace.new(ns_name) do
            mod = bind.receiver
            targets.each do |target|
              targetobj = Tms::Table::Obj.new(target)
              targetxform = xforms.select{ |x| x.to_s == "for_#{targetobj.filekey}_transform" }
              register targetobj.filekey, mod.send(:target_job_hash, *[ns_name, targetobj, field, targetxform])
            end
          end
        end

        def target_job_hash(ns_name, targetobj, field, xforms)
          key = targetobj.filekey
          tags = [ns_name, key].map(&:to_s)
            .map{ |val| val.gsub('_', '') }
            .map(&:to_sym)
          tabletag = tags.shift
          [tabletag.to_s.delete_suffix('_for').to_sym, :for_table].each{ |tag| tags << tag }
          
          {
            path: File.join(Tms.datadir, 'working', "#{ns_name}_#{key}.csv"),
            creator: {callee: Tms::Jobs::ForTable,
                      args: {
                        source: "prep__#{ns_name}".delete_suffix('_for').to_sym,
                        dest: "#{ns_name}__#{key}".to_sym,
                        targettable: targetobj.tablename,
                        field: field,
                        xforms: xforms
                      }
                     },
            tags: tags
          }
        end
      end
    end
  end
end
