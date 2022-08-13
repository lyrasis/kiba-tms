# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module Constituents
        # Person name in preferred format from name parts
        class PersonFromNameParts
          def initialize
            @name_builder = set_name_builder
          end

          def call(row)
            name_builder.call(row)
          end

          private

          attr_reader :name_builder

          def set_name_builder
            if Tms::Constituents.preferred_name_field == :displayname
              Tms::Services::Constituents::PersonDisplaynameConstructor.new
            else
              Tms::Services::Constituents::PersonNameAlphasortConstructor.new
            end
          end
        end
      end
    end
  end
end
