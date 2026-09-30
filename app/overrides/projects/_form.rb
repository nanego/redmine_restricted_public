# frozen_string_literal: true

Deface::Override.new :virtual_path => 'projects/_form',
                     :name => 'replace-is-public-checkbox-with-publicity',
                     :replace => 'erb[loud]:contains("f.check_box :is_public")',
                     :partial => 'restricted_public/project_publicity'
