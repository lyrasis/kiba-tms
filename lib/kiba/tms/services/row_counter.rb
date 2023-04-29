# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      class RowCounter
        class << self
          def call(job_key)
            self.new(job_key).call
          end
        end
        
        def initialize(job_key)
          @job_key = job_key
          @job_entry = resolved
        end

        def call
          return 0 unless job_entry
          	
          result = run_and_count
          result == :failure ? 0 : result
        end

        private

        attr_reader :job_key, :job_entry

        def resolved
          Kiba::Extend.registry.resolve(job_key)
        rescue Dry::Container::KeyError
          culprit = caller.reject{ |line| line["tms/services/row_counter"] }.first
          puts "#{self.class.name}: No job with key: #{job_key}\n#{culprit}"
          nil
        end
        
        def run_and_count
          job = Kiba::Extend::Command::Run.job(job_key)
          return :failure unless job.is_a?(Kiba::Extend::Jobs::Job)


          job.outrows
        end
      end
    end
  end
end
