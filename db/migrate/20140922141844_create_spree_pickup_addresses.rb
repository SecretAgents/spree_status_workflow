class CreateSpreePickupAddresses < ActiveRecord::Migration
  def change
    create_table :spree_pickup_addresses do |t|
      t.text :address
      t.string :link_to_map

      t.timestamps
    end
  end
end
