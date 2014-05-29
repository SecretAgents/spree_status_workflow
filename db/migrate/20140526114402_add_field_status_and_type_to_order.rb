class AddFieldStatusAndTypeToOrder < ActiveRecord::Migration
  def change
    change_table :spree_orders do |t|
      t.string :status
      t.integer :order_type, :default => 0
    end
  end
end