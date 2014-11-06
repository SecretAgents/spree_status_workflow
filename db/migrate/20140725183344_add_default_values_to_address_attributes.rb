class AddDefaultValuesToAddressAttributes < ActiveRecord::Migration
  def change
    change_column :spree_addresses, :housing, :string, :default => ''
    change_column :spree_addresses, :building, :string, :default => ''
    change_column :spree_addresses, :room, :string, :default => ''
    change_column :spree_addresses, :porch, :string, :default => ''
    change_column :spree_addresses, :floor, :string, :default => ''
  end
end
