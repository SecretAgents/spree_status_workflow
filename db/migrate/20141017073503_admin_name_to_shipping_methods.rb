class AdminNameToShippingMethods < ActiveRecord::Migration
  def change
    ship_cat_all = Spree::ShippingCategory.all

    zone = Spree::Zone.where(:default_tax => true).first
    if zone.nil?
      zone = Spree::Zone.create!(
          :name => 'Russian Zone',
          :description => 'Россия',
          :default_tax => true
      )
    end

    methods = [
        {
            :name => 'Самовывоз',
            :admin_name => 'pickup'
        },
        {
            :name => 'Москва (в пределах МКАД)',
            :admin_name => 'inside_mkad'
        },
        {
            :name => 'Транспортная компания',
            :admin_name => 'tk'
        },
        {
            :name => 'Курьер',
            :admin_name => 'courier'
        }
    ]

    tax_cat = Spree::TaxCategory.find_or_create_by!(:name => 'Default', :is_default => true)

    methods.each do |method|
      ship_method = Spree::ShippingMethod.find_by_name(method[:name])

      if ship_method.nil?
        ship_method = Spree::ShippingMethod.new(
            :name => method[:name],
            :admin_name => method[:admin_name],
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

      else
        ship_method.admin_name = method[:admin_name]
        ship_method.calculator.preferences = {
            amount: 0,
            currency: 'RUB'
        }
      end

      ship_method.save
    end

    if Spree::ShippingMethod.where(:admin_name => 'pickup_discount').first.nil?
      ship_method = Spree::ShippingMethod.find_by_name('Самовывоз (со скидкой)')
      if ship_method.nil?
        ship_method = Spree::ShippingMethod.new(
            :name => 'Самовывоз (со скидкой)',
            :admin_name => 'pickup_discount',
            :tax_category_id => tax_cat.id
        )
        ship_method.zones << zone
        ship_method.shipping_categories << ship_cat_all
        ship_method.calculator = Spree::ShippingCalculator.create!(
            :type => 'Spree::Calculator::Shipping::FlatPercentItemTotal',
            :preferences => {
                :flat_percent => -5.0
            }
        )
      else
        ship_method.admin_name = 'pickup_discount'
      end
      ship_method.save
    end

    if Spree::ShippingMethod.where(:admin_name => 'outside_mkad').first.nil?
      ship_method = Spree::ShippingMethod.find_by_name('Доставка за МКАД')
      if ship_method.nil?
        ship_method = Spree::ShippingMethod.new(
            :name => 'Доставка за МКАД',
            :admin_name => 'outside_mkad',
            :tax_category_id => tax_cat.id
        )
        ship_method.zones << zone
        ship_method.shipping_categories << ship_cat_all
        ship_method.calculator = Spree::ShippingCalculator.create!(
            :type => 'Spree::Calculator::Shipping::PerKilometer',
            :preferences => {
                :kilometers => 1,
                :amount => 30,
                :currency => 'RUB'
            }
        )
      else
        ship_method.admin_name = 'outside_mkad'
      end
      ship_method.save
    end

  end
end
