class ChangeAddressValuesCapacity < ActiveRecord::Migration
  def change
    change_column :spree_addresses, :housing, :numeric, :precision => 0, :limit => 11
    change_column :spree_addresses, :building, :numeric, :precision => 0, :limit => 11
    change_column :spree_addresses, :room, :numeric, :precision => 0, :limit => 11
    change_column :spree_addresses, :porch, :numeric, :precision => 0, :limit => 11
    change_column :spree_addresses, :floor, :numeric, :precision => 0, :limit => 11
  end
end
