# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      module Prep
        # Return creator method
        class CreatorGetter
          def self.call(table)
            self.new(table).call
          end

          def initialize(table)
            @tablename = table.tablename
            @filekey = table.filekey
            @meth = Kiba::Extend.default_job_method_name
          end

          def call
            return abstract if klass.nil?
            return prep_klass.constantize.method(meth) if has_prep_class?
            return klass.method(:prep) if has_prep_method?
            
            abstract
          end
        
          private

          attr_reader :tablename, :filekey, :meth

          def abstract
            Kiba::Tms::Jobs::AbstractPrep.new(filekey).method(:prep)
          end
          
          def define_klass
            klass_name.constantize = Class.new(Kiba::Tms::Jobs::AbstractPrep) do
              @key = filekey
            end
          end
          
          def klass
            klass_name.constantize
          rescue NameError
            nil
          end

          def klass_name
            "Kiba::Tms::Jobs::#{tablename}"
          end

          def has_prep_class?
            prep_klass.constantize
          rescue NameError
            false
          else
            return true if prep_klass.constantize.methods.any?(meth)

            false
          end
          
          def has_prep_method?
            klass.methods.any?(:prep)
          end

          def prep_klass
            "Kiba::Tms::Jobs::#{tablename}::Prep"
          end
        end
      end
    end
  end
end
