class ChangeAddressAttributesIntoString < ActiveRecord::Migration
  def change
    change_column :spree_addresses, :housing, :string
    change_column :spree_addresses, :building, :string
    change_column :spree_addresses, :room, :string
    change_column :spree_addresses, :porch, :string
    change_column :spree_addresses, :floor, :string
  end
end
