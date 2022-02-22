# frozen_string_literal: true

module Kiba
  module Tms
    module MediaFiles
      extend self
      
      def file_names
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :tms__media_files,
            destination: :media_files__file_names
          },
          transformer: file_names_xforms
        )
      end

      def file_names_xforms
        Kiba.job_segment do
          transform Delete::FieldsExcept, keepfields: %i[filename]
          transform FilterRows::FieldPopulated, action: :keep, field: :filename
        end
      end
    end
  end
end
