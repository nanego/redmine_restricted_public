# frozen_string_literal: true

require_dependency 'query'
require_dependency 'project_query'

module RedmineRestrictedPublic
  module ProjectQueryPatch
    def initialize_available_filters
      super
      add_available_filter("restricted_public",
                           :type => :list,
                           :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]])
    end
  end
end

ProjectQuery.prepend RedmineRestrictedPublic::ProjectQueryPatch

unless ProjectQuery.available_columns.any? { |c| c.name == :restricted_public }
  ProjectQuery.available_columns << QueryColumn.new(:restricted_public, :sortable => "#{Project.table_name}.restricted_public", :groupable => true)
end
