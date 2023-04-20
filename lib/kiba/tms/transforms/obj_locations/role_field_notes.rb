# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        # Collapses handler/approver/requestedby name notes and notes to a
        #   the single available CS field
        class RoleFieldNotes
          # @param target [:inventory, :movement] affects target note field
          #   and label of role-note
          def initialize(target:)
            @target = "#{target}note".to_sym
            @role_note_label = {
              "handler"=>"Handling",
              "approver"=>"Approval",
              "requestedby"=>"#{target.capitalize} request"
            }
            @role_name_label = {
              "handler"=>"Handled by: ",
              "approver"=>"Approved by: ",
              "requestedby"=>"Requested by: "
            }
            @role_note_field = {
              "handler"=>:handling_note,
              "approver"=>:approval_note,
              "requestedby"=>:request_note
            }
            @roles = %w[requestedby approver handler]
            @include_name_notes = Tms::ObjLocations.note_from_role_names
          end

          def process(row)
            row[target] = roles.map{ |role| notes_for(role, row) }
              .reject{ |val| val.blank? }
              .join("%CR%")

            roles.map{ |role| ["#{role}_person", "#{role}_organization",
                               "#{role}_note"] }
              .flatten
              .map(&:to_sym)
              .each{ |field| row.delete(field) }

            row
          end

          private

          attr_reader :target, :role_note_label, :role_name_label,
            :role_note_field, :roles, :include_name_notes

          def notes_for(role, row)
            [
              name_notes_for(role, row),
              role_note_for(role, row)
            ].flatten
              .join("%CR%")
          end

          def name_notes_for(role, row)
            return [] unless include_name_notes

            %w[person organization].map{ |auth| "#{role}_#{auth}".to_sym }
              .map{ |field| row[field] }
              .reject{ |val| val.blank? }
              .map{ |val| "#{role_name_label[role]}#{val}" }
          end

          def role_note_for(role, row)
            val = row["#{role}_note".to_sym]
            return [] if val.blank?

            ["#{role_note_label[role]} note: #{val}"]
          end
        end
      end
    end
  end
end
