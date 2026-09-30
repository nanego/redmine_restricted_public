# frozen_string_literal: true

require_dependency 'project'

module RedmineRestrictedPublic
  # A restricted public project is stored as a private one (is_public = false) with
  # restricted_public = true: any code reading is_public treats it as private.
  module ProjectPatch
    PUBLICITIES = %w(public restricted private).freeze

    def self.prepended(base)
      base.singleton_class.prepend(ClassMethods)
      base.class_eval do
        before_validation :clear_restricted_public_if_public

        # Same condition as core is_public (select_project_publicity permission)
        is_public_options = safe_attributes.detect { |attrs, _| attrs.include?('is_public') }&.last
        is_public_options ||= { :if => lambda { |_project, user| user.admin? } }
        safe_attributes 'publicity', 'restricted_public', is_public_options
      end
    end

    module ClassMethods
      # Restricted public projects are open to internal non-members, like public ones
      def public_projects_condition(user)
        condition = super
        return condition unless user.internal_user?

        "(#{condition} OR #{Project.table_name}.restricted_public = #{connection.quoted_true})"
      end
    end

    def publicity
      if is_public?
        'public'
      elsif restricted_public?
        'restricted'
      else
        'private'
      end
    end

    def publicity=(value)
      return unless PUBLICITIES.include?(value.to_s)

      self.is_public = (value.to_s == 'public')
      self.restricted_public = (value.to_s == 'restricted')
    end

    private

    def clear_restricted_public_if_public
      self.restricted_public = false if is_public?
    end
  end
end

Project.prepend RedmineRestrictedPublic::ProjectPatch
