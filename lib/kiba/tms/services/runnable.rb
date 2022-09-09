# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      # Mixin module with methods to facilitate running a job and extracting data from the result
      #
      # ## Implementation details
      #
      # Mixing-in classes must:
      #
      # - implement :job_key instance method
      module Runnable

        def row_count(job_key)
          result = run_job(job_key)
          return :failure unless result.is_a?(Kiba::Extend::Jobs::Job)
          
          result.context.instance_variable_get(:@outrows)
        end
        
        def resolve_job(job_key)
          Tms.registry.resolve(job_key)
        rescue Dry::Container::KeyError
          puts "No job with key: #{job_key}"
          :failure
        end

        def resolve_creator(job)
          creator = job.creator
          return creator if creator

          puts "No creator method for #{job.key}"
          :failure
        end

        def run_job(job_key)
          job = resolve_job(job_key)
          return if job == :failure

          creator = resolve_creator(job)
          return if creator == :failure

          creator.call
        end
      end
    end
  end
end
