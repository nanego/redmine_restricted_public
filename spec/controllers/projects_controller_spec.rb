# frozen_string_literal: true

require "spec_helper"

describe ProjectsController, :type => :controller do
  fixtures :users, :email_addresses, :roles, :projects, :members, :member_roles, :enabled_modules

  before do
    @request.session[:user_id] = 1
  end

  it "sets a project as restricted public" do
    put :update, :params => { :id => 2, :project => { :publicity => 'restricted' } }

    project = Project.find(2)
    expect([project.is_public, project.restricted_public]).to eq [false, true]
  end

  it "makes a restricted public project public" do
    Project.find(2).update_columns(restricted_public: true)

    put :update, :params => { :id => 2, :project => { :publicity => 'public' } }

    project = Project.find(2)
    expect([project.is_public, project.restricted_public]).to eq [true, false]
  end
end
