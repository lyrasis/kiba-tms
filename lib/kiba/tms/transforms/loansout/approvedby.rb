# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Loansout
        class Approvedby
          include Tms::Transforms::ValueAppendable

          def initialize(delim: Tms.delim)
            @delim = delim
            @person_source = :approvedby_person
            @org_source = :approvedby_org
            @date_source = :approveddate
            @treatment = Tms::Loansout.approvedby_handling
            @status_fields = Tms::Loansout.status_targets
            @status_builder = Tms::Transforms::FieldGroupSources.new(
              grouped_fields: status_fields,
              prefix: "app",
              value_map: {
                loangroup: :org,
                loanindividual: :person,
                loanstatusdate: :date
              },
              constant_map: {loanstatus: "approved"}
            )
          end

          def process(row)
            dateval = row[date_source]
            if row[person_source].blank? && row[org_source].blank?
              handle_date_only(dateval, row)
            else
              handle_person_values(dateval, row)
              handle_org_values(dateval, row)
            end
            [person_source, org_source, date_source].each { |f| row.delete(f) }
            row
          end

          private

          attr_reader :delim, :person_source, :org_source, :date_source,
            :treatment, :status_fields, :status_builder

          def handle_date_only(date, row)
            tmprow = {person: nil, date: date, org: nil}
            call_status_builder(tmprow, row)
          end

          def handle_person_values(date, row)
            person_val = row[person_source]
            case person_type(person_val)
            when :single
              set_auth_values(person_val, date, row)
            when :multi
              persons = person_val.split(delim)
              set_auth_values(persons.shift, date, row)
              persons.each do |person|
                tmprow = {person: person, date: date, org: nil}
                call_status_builder(tmprow, row)
              end
            end
          end

          def handle_org_values(date, row)
            orgvals = row[org_source]
            return if orgvals.blank?

            orgvals.split(delim).each do |org|
              tmprow = {org: org, date: date, person: nil}
              call_status_builder(tmprow, row)
            end
          end

          def person_type(val)
            if val.blank?
              :none
            elsif val[delim]
              :multi
            else
              :single
            end
          end

          def set_auth_values(person, date, row)
            name_target = "#{treatment}sauthorizer".to_sym
            date_target = "#{treatment}sauthorizationdate".to_sym
            row[name_target] = person
            row[date_target] = date
          end

          def call_status_builder(tmprow, row)
            tmpsrcs = %i[date org person]
            status_builder.process(tmprow)
              .each do |field, val|
                next if tmpsrcs.include?(field)

                append_value(row, field, val, delim)
              end
          end
        end
      end
    end
  end
end
