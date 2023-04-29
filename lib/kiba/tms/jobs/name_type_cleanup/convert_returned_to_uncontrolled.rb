# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module ConvertReturnedToUncontrolled
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_type_cleanup__worksheet,
                destination: :name_type_cleanup__convert_returned_to_uncontrolled
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Append::NilFields, fields: %i[norm origname sourceflag]

              # flag affected rows
              transform do |row|
                srcs = Tms::NameCompile.uncontrolled_name_source_tables
                  .keys
                src = row[:termsource]
                next row unless srcs.any? { |s| src.match?(s) }

                row[:sourceflag] = "y"
                row
              end

              # extract orig name from constituentid to origname
              # normalize origname into norm
              extractor = Tms::Transforms::NameTypeCleanup::ExtractIdSegment.new(
                target: :origname,
                segment: :name
              )
              normer = Kiba::Extend::Transforms::Cspace::NormalizeForID.new(
                source: :origname,
                target: :norm
              )
              transform do |row|
                next row unless row[:sourceflag]

                extractor.process(row)
                normer.process(row)
                row[:constituentid] = row[:norm]
                row[:termsource] = "Uncontrolled"
                row
              end

              transform Delete::Fields, fields: %i[norm origname sourceflag]
            end
          end
        end
      end
    end
  end
end
