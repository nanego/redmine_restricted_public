# frozen_string_literal: true

require_dependency 'principal'
require_dependency 'user'

module RedmineRestrictedPublic
  # For an internal user, a restricted public project behaves like a public one
  module UserPatch
    # internal_user? is provided by redmine_internal_users
    def restricted_public_access?(project)
      project.restricted_public? && !project.is_public? && internal_user?
    end

    def reload(*)
      @restricted_public_roles_merged = nil
      super
    end

    def roles_for_project(project)
      roles = super
      return roles if project.nil? || project.archived? || membership(project) || !restricted_public_access?(project)

      roles | project.override_roles(builtin_role)
    end

    # Same as core, without the "public project or member role" guard
    def allowed_to?(action, context, options = {}, &block)
      return super unless context.is_a?(Project) && !admin? && restricted_public_access?(context)
      return false unless context.allows_to?(action)

      roles_for_project(context).any? do |role|
        role.allowed_to?(action, @oauth_scope) &&
          (block ? yield(role, self) : true)
      end
    end

    # Adds the custom roles given to the builtin non-member group on restricted
    # public projects. The builtin Non member role must not be added here: it is
    # handled by Project.public_projects_condition.
    def project_ids_by_role
      result = super
      return result if @restricted_public_roles_merged

      @restricted_public_roles_merged = true
      return result unless internal_user?

      Project.unscoped do
        rows = Member.joins(:project, :member_roles)
                     .where(:user_id => GroupNonMember.unscoped.pick(:id))
                     .where(:projects => { :restricted_public => true, :is_public => false })
                     .where.not(:projects => { :status => Project::STATUS_ARCHIVED })
                     .where.not(:project_id => project_ids)
                     .pluck("#{MemberRole.table_name}.role_id", :project_id)
        roles = Role.where(:id => rows.map(&:first).uniq).index_by(&:id)
        rows.each do |role_id, project_id|
          role = roles[role_id]
          result[role] = result[role] | [project_id] if role
        end
      end
      result
    end
  end
end

User.prepend RedmineRestrictedPublic::UserPatch
