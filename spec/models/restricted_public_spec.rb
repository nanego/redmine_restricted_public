# frozen_string_literal: true

require "spec_helper"

describe "Restricted public projects" do
  fixtures :users, :email_addresses, :roles, :projects, :members, :member_roles,
           :trackers, :projects_trackers, :issue_statuses, :enumerations,
           :enabled_modules, :issues, :wikis, :wiki_pages

  let(:project) { Project.find(2) } # private, users 3 and 4 are not members
  let(:internal) { User.find(4).tap { |u| u.update_columns(internal: true) } }
  let(:external) { User.find(3) }

  before { project.update_columns(restricted_public: true) }

  def parity_holds?(user, permission)
    sql_ids = Project.allowed_to(user, permission).ids.sort
    ruby_ids = Project.where(status: [Project::STATUS_ACTIVE, Project::STATUS_CLOSED])
                      .select { |p| user.allowed_to?(permission, p) }.map(&:id).sort
    sql_ids == ruby_ids
  end

  describe "visibility" do
    it "keeps the project private for an external user" do
      expect(project.visible?(external)).to be false
      expect(Project.visible(external)).not_to include(project)
      expect(Issue.visible(external).where(project_id: project.id)).to be_empty
    end

    it "opens the project to an internal user like a public one" do
      expect(project.visible?(internal)).to be true
      expect(Project.visible(internal)).to include(project)
      expect(Issue.visible(internal).where(project_id: project.id)).not_to be_empty
      expect(internal.roles_for_project(project)).to eq [Role.non_member]
    end

    it "keeps the project closed to an anonymous user" do
      expect(project.visible?(User.anonymous)).to be false
      expect(Project.visible(User.anonymous)).not_to include(project)
    end

    it "does not open other private projects to an internal user" do
      expect(Project.find(5).visible?(internal)).to be false
      expect(Project.visible(internal)).not_to include(Project.find(5))
    end

    it "does not open an archived project" do
      project.update_columns(status: Project::STATUS_ARCHIVED)
      expect(project.visible?(internal)).to be false
      expect(Project.visible(internal)).not_to include(project)
    end

    it "keeps the member roles of a member" do
      member = User.find(2).tap { |u| u.update_columns(internal: true) }
      expect(member.roles_for_project(project)).to eq member.membership(project).roles.to_a
    end

    it "applies the roles given to the non-member group" do
      Member.create!(principal: Group.non_member, project: project, role_ids: [2])
      expect(internal.roles_for_project(project)).to eq [Role.find(2)]
      expect(internal.project_ids_by_role[Role.find(2)]).to include(project.id)
      expect(external.project_ids_by_role[Role.find(2)]).not_to include(project.id)
    end

    it "gives the same result in SQL and in Ruby" do
      Member.create!(principal: Group.non_member, project: Project.find(1), role_ids: [3])
      [internal, external, User.anonymous].each do |user|
        %i[view_project view_issues view_wiki_pages add_issues].each do |permission|
          expect(parity_holds?(user, permission)).to be(true), "#{user.login.presence || 'anonymous'} / #{permission}"
        end
      end
    end

    it "gives the same result in SQL and in Ruby with a non-member group override" do
      Member.create!(principal: Group.non_member, project: project, role_ids: [2])
      %i[view_project view_issues add_issues].each do |permission|
        expect(parity_holds?(internal, permission)).to be(true), permission.to_s
      end
    end
  end

  describe "publicity" do
    it "maps the three modes to both columns" do
      project.publicity = 'public'
      expect([project.is_public, project.restricted_public]).to eq [true, false]
      project.publicity = 'restricted'
      expect([project.is_public, project.restricted_public]).to eq [false, true]
      project.publicity = 'private'
      expect([project.is_public, project.restricted_public]).to eq [false, false]
    end

    it "ignores unknown values" do
      project.publicity = 'foo'
      expect(project.publicity).to eq 'restricted'
    end

    it "clears restricted_public when the project becomes public" do
      project.is_public = true
      project.save!
      expect(project.reload.restricted_public).to be false
    end

    it "is only settable by users allowed to select the project publicity" do
      expect(project.safe_attribute?('publicity', User.find(1))).to be true
      expect(project.safe_attribute?('publicity', internal)).to be false
    end

    it "is copied with the project" do
      copy = Project.copy_from(project)
      expect(copy.restricted_public).to be true
    end
  end

  describe "queries" do
    it "filters projects on restricted_public" do
      User.current = User.find(1)
      query = ProjectQuery.new(name: '_')
      query.filters = { 'restricted_public' => { operator: '=', values: ['1'] } }
      expect(query.results_scope.ids).to eq [project.id]
    end
  end
end
