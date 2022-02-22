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
            @filename = table.filename.delete_suffix('.csv')
            @filekey = table.filekey
          end

          def call
            return abstract if klass.nil?
            return abstract unless has_prep_method?

            klass.method(:prep)
          end
        
          private

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
            # define_klass            
            # klass_name.constantize
          end

          def klass_name
            "Kiba::Tms::Jobs::#{filename}"
          end

          def has_prep_method?
            klass.methods.any?(:prep)
          end
          

          attr_reader :filename, :filekey
        end
      end
    end
  end
end
