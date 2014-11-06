class AllShipCategoryToAllShipMethods < ActiveRecord::Migration
  def up
    ship_cat_all = Spree::ShippingCategory.all

    Spree::ShippingMethod.all.each do |method|
      method.shipping_categories = ship_cat_all
      method.save
    end
  end
end
