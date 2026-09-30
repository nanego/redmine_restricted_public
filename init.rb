# frozen_string_literal: true

require 'redmine'
require_relative 'lib/redmine_restricted_public/hooks'

Rails.autoloaders.main.ignore("#{__dir__}/lib")

Redmine::Plugin.register :redmine_restricted_public do
  name 'Redmine Restricted Public plugin'
  description 'Adds a "restricted public" project mode: public for internal users, private for external users'
  author 'Vincent ROBERT'
  url 'https://github.com/nanego/redmine_restricted_public'
  version '1.0.0'
  requires_redmine :version_or_higher => '6.1.0'
  requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.3' if Rails.env.test?
  requires_redmine_plugin :redmine_base_deface, :version_or_higher => '0.0.1'
  # Both loaded first thanks to the alphabetical order:
  # redmine_internal_users provides User#internal_user?,
  # redmine_organizations provides Project.public_projects_condition
  requires_redmine_plugin :redmine_internal_users, :version_or_higher => '1.0.0'
  requires_redmine_plugin :redmine_organizations, :version_or_higher => '6.1.0'
end
