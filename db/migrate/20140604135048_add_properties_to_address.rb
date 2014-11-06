class AddPropertiesToAddress < ActiveRecord::Migration
  def change
    add_column :spree_addresses, :housing, :integer
    add_column :spree_addresses, :building, :integer
    add_column :spree_addresses, :room, :integer
    add_column :spree_addresses, :porch, :integer
    add_column :spree_addresses, :floor, :integer
    add_column :spree_addresses, :elevators, :integer
    add_column :spree_addresses, :subway_station, :string
    add_column :spree_addresses, :intercom_code, :string
  end
end
