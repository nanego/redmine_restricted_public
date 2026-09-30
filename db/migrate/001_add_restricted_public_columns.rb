class AddRestrictedPublicColumns < ActiveRecord::Migration[6.1]
  def change
    add_column :projects, :restricted_public, :boolean, :default => false, :null => false
  end
end
