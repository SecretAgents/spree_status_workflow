class AddAgreementToSpreeUsers < ActiveRecord::Migration
  def change
    add_column :spree_users, :agreement, :boolean, :default => false
  end
end