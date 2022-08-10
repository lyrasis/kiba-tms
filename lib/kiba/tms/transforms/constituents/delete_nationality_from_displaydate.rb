# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class DeleteNationalityFromDisplaydate
          def process(row)
            nationality = row[:nationality]
            return row if nationality.blank?

            dd = row[:displaydate]
            return row if dd.blank?
            return row unless dd.downcase[nationality.downcase]

            row[:displaydate] = clean(dd, nationality)
            row
          end

          private

          def clean(dd, nationality)
            pattern = Regexp.new("#{nationality},? *", Regexp::IGNORECASE)
            dd.gsub(pattern, '')
          end
        end
      end
    end
  end
end
