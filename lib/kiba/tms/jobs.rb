# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module_function
      
      def extend_configured_jobs
        job_namespaces.each{ |namespace| extend_configured_job(namespace) }
      end

      def config_list
        @config_list ||= Kiba::Tms.constants.select do |constant|
          evaled = Kiba::Tms.const_get(constant)
          evaled.is_a?(Module) && evaled.ancestors.any?(Dry::Configurable)
        end
      end
      private_class_method :config_list
      
      def extend_configured_job(namespace)
        parent = Kiba::Tms::Jobs.const_get(namespace)
        parent.constants.each do |job|
          jobmod = parent.const_get(job)
          jobmod.extend(Tms::Mixins::ConfiguredJob)
        end
      end
      private_class_method :extend_configured_job
      
      def has_config?(constant)
        config_list.any?(constant)
      end
      private_class_method :has_config?
      
      def job_namespaces
        Tms::Jobs.constants.select{ |constant| has_config?(constant) }
      end
      private_class_method :job_namespaces
    end
  end
end
