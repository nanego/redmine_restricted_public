# frozen_string_literal: true

Deface::Override.new :virtual_path => 'projects/_form',
                     :name => 'replace-is-public-checkbox-with-publicity',
                     :replace => 'erb[loud]:contains("f.check_box :is_public")',
                     :partial => 'restricted_public/project_publicity'

Deface::Override.new :virtual_path => 'projects/_form',
                     :name => 'replace-is-public-info-with-publicity-info',
                     :replace => 'erb[loud]:contains("text_project_is_public_non_member")',
                     :partial => 'restricted_public/project_publicity_info'
