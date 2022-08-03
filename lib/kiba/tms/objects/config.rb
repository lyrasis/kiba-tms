# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Objects
      module Config
        module_function
        extend Dry::Configurable

        setting :annotation_source_fields, default: %i[creditline], reader: true
        setting :annotation_target_fields, default: %i[annotationtype annotationnote], reader: true
        setting :consider_blank, default: {
                loanclassid: '0',
                objectlevelid: '0',
                objecttypeid: '0',
                publicaccess: '0',
                subclassid: '0',
                type: '0',
              },
          reader: true
        setting :comment_fields,
          reader: true,
          default: %i[comment],
          constructor: ->(default) do
            default << :alt_num_comment if Tms::AltNums.for?('Objects')
            default << :title_comment if Tms::Table::List.include?('ObjTitles')
            default
          end
          
        # default mapping will be skipped, fields will be left as-is in objects__prep job for handling
        #  in client project
        setting :custom_map_fields, default: [], reader: true
        # will be merged into `Rename::Fields` fieldmap
        setting :custom_rename_fieldmap, default: {}, reader: true
        # client-specfic fields to delete
        setting :delete_fields, default: [], reader: true
        # other supported values: :dept_namedcollection
        # If setting to :dept_namedcollection, see also the following configs:
        #   department_coll_prefix, named_coll_fields
        setting :department_target, default: :responsibledepartment, reader: true
        # necessary if :department_target = :dept_namedcollection. Should be a String value if populated
        setting :department_coll_prefix, default: nil, reader: true
        setting :named_coll_fields, default: [], reader: true
        setting :nontext_inscription_source_fields, default: %i[], reader: true
        setting :nontext_inscription_target_fields, default: %i[], reader: true
        setting :text_entry_lookup, default: nil, reader: true
        setting :text_inscription_source_fields, default: %i[signed inscribed markings], reader: true
        setting :text_inscription_target_fields, default: %i[inscriptioncontenttype inscriptioncontent], reader: true
      end
    end
  end
end
