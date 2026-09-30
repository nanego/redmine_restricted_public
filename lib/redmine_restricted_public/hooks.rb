# frozen_string_literal: true

module RedmineRestrictedPublic
  class Hooks < Redmine::Hook::Listener
    def after_plugins_loaded(_context = {})
      require_relative 'project_patch'
      require_relative 'user_patch'
      require_relative 'project_query_patch'
    end
  end
end
