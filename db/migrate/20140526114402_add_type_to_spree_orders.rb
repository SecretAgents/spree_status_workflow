class AddTypeToSpreeOrders < ActiveRecord::Migration
  def change
    add_column :spree_products, :order_type, :integer, :default => 0
  end
end