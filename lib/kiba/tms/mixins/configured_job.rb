# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # {Services::ConfiguredJobExtender} automatically extends jobs
      #   with this mixin module
      #
      # It provides the :config method on the job, so the job can
      #   interact directly with the config module associated with the
      #   job namespace.
      #
      # For example, all jobs under `Tms::Jobs::ObjComponents` will return
      #   `Tms::ObjComponents` if `:config` is called.
      module ConfiguredJob
        def config
          Object.const_get(config_module_name)
        end

        def config_module_name
          if class_variable_defined?(:@@config_module_name)
            return class_variable_get(:@@config_module_name)
          end

          nameparts = name.split("::")
          nameparts.pop
          nameparts.delete("Jobs")
          class_variable_set(:@@config_module_name, nameparts.join("::"))
          class_variable_get(:@@config_module_name)
        end
        private :config_module_name
      end
    end
  end
end
