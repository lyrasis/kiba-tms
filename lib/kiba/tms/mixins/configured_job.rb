# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      module ConfiguredJob
        def config
          Object.const_get(config_module_name)
        end

        def config_module_name
          return class_variable_get(:@@config_module_name) if class_variable_defined?(:@@config_module_name)

          nameparts = self.name.split('::')
          nameparts.pop
          nameparts.delete('Jobs')
          class_variable_set(:@@config_module_name, nameparts.join('::'))
          class_variable_get(:@@config_module_name)
        end
      end
    end
  end
end
