# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module Constituents
        # Returns contact name value for Organizations
        class ContactNamer
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @name_builder = set_name_builder
          end

          def call(row)
            return nil unless org?(row)

            name_builder.call(row)
          end

          private

          attr_reader :name_builder

          def org?(row)
            row.fetch(:constituenttype, nil) == 'Organization'
          end

          def set_name_builder
            if Tms.constituents.preferred_name_field == :displayname
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
