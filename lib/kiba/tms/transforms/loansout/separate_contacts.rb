# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Loansout
        # moves :person values with a :personrole value of `Contact` to the :contact field
        class SeparateContacts
          def initialize(delim: Tms.delim)
            @delim = delim
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: %i[contact person personrole])
          end

          def process(row)
            vals = getter.call(row)
            return row if vals.empty?
            vals.transform_values!{ |val| val.split(delim, -1) }
            return row unless vals.key?(:personrole)
            
            roles = vals[:personrole]
            return row unless contact?(roles)

            moved = move_contact_persons(vals, roles)
            row.merge(moved)
          end

          private

          attr_reader :delim, :getter

          def add_to_contact(vals, index)
            newval = vals[:person][index]
            if vals.key?(:contact)
              vals[:contact] << newval
            else
              vals[:contact] = [newval]
            end
          end

          def clean_from_person(vals, index)
            %i[person personrole].each{ |field| vals[field].delete_at(index) }
          end
          
          def contact?(val)
            if val.is_a?(Array)
              val.any?{ |v| v.downcase == 'contact' }
            elsif val.is_a?(String)
              val.downcase == 'contact'
            end
          end
          
          def first_contact(roles)
            ind = []
            roles.each_with_index{ |r, i| ind << i if contact?(r) }
            return nil if ind.empty?

            ind.first
          end
          
          def move_contact_person(vals, roles)
            index = first_contact(roles)
            add_to_contact(vals, index)
            clean_from_person(vals, index)
          end

          def move_contact_persons(vals, roles)
            move_contact_person(vals, roles) until !contact?(roles)
            vals.transform_values!{ |val| val.empty? ? nil : val.join(delim) }
          end
        end
      end
    end
  end
end
