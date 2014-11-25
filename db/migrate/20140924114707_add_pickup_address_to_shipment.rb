class AddPickupAddressToShipment < ActiveRecord::Migration
  def change
    add_column :spree_shipments, :pickup_address_id, :integer
  end
end
