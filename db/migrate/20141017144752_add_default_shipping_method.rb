class AddDefaultShippingMethod < ActiveRecord::Migration
  def up
    ship_cat_all =  Spree::ShippingCategory.all

    zone = Spree::Zone.where(:default_tax => true).first
    if zone.nil?
      zone = Spree::Zone.create!(
          :name => 'Russian Zone',
          :description => 'Россия',
          :default_tax => true
      )
    end

    tax_cat = Spree::TaxCategory.find_or_create_by!(:name => 'Default', :is_default => true)

    ship_method = Spree::ShippingMethod.new(
        :name => 'Метод доставки не выбран',
        :admin_name => 'default_shipping',
        :tax_category_id => tax_cat.id
    )
    ship_method.zones << zone
    ship_method.shipping_categories << ship_cat_all
    ship_method.calculator = Spree::ShippingCalculator.create!(
        :type => 'Spree::Calculator::Shipping::FlatRate',
        :preferences => {
            :amount => 0,
            :currency => 'RUB'
        }
    )
    ship_method.save
  end
end
