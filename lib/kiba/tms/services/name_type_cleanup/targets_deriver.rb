# frozen_string_literal: true

require 'dry/monads'

module Kiba
  module Tms
    module Services
      module NameTypeCleanup
        class TargetsDeriver
          include Dry::Monads[:result]

          def self.call(...)
            self.new(...).call
          end

          def initialize(counter: Tms::Services::RowCounter)
            @counter = counter
            @targets = []
          end

          def call
            set_targets.either(
              ->(success){ Success(targets) },
              ->(failure){ Failure(failure) }
            )
          end

          private

          attr_reader :counter, :targets

          def set_targets
            return Success(targets) unless Tms::NameTypeCleanup.done

            if counter.call(:name_type_cleanup__for_con_alt_names) > 0
              targets << 'ConAltNames'
            end
            if counter.call(:name_type_cleanup__for_constituents) > 0
              targets << 'Constituents'
            end
            if counter.call(
              :name_type_cleanup__for_con_org_with_name_parts
            ) > 0
              targets << 'Constituents.orgs_name_detail'
            end
            if counter.call(
              :name_type_cleanup__for_con_person_with_inst
            ) > 0
              targets << 'Constituents.person_with_institution'
            end
            Tms::NameCompile.uncontrolled_name_source_tables
              .keys
              .map{ |key| Tms.const_get(key) }
              .each do |mod|
                jobkey = "name_type_cleanup_for__#{mod.filekey}".to_sym
                if counter.call(jobkey) > 0
                  targets << mod.to_s.split('::').last
                end
              end
          rescue StandardError => err
            Failure(err)
          else
            Success()
          end
        end
      end
    end
  end
end
