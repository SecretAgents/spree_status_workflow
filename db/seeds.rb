# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

Spree::Taxonomy.find_or_create_by!(
   :name => 'Категории'
)

Spree::Taxonomy.find_or_create_by!(
   :name => 'Каталог производителей'
)

tax_cat = Spree::TaxCategory.find_or_create_by!(:name => 'Стандартный', :is_default => true)

zone = Spree::Zone.create!(
    :name => 'Россия',
    :default_tax => true
)
zone.kind = 'country'
zone.country_ids << Spree::Country.find_by_iso3('RUS').id
zone.save

Spree::PaymentMethod.find_or_create_by!(
    :type => 'Spree::CashOnDelivery::PaymentMethod',
    :name => 'Оплата при доставке',
    :active => true,
    :environment => Rails.env
)

Spree::ShippingCategory.destroy_all
ship_cat = Spree::ShippingCategory.create!(
    :name => 'Москва и область'
)
ship_cat_all = Spree::ShippingCategory.create!(
    :name => 'Россия'
)
ship_method = Spree::ShippingMethod.new(
    :name => 'Доставка курьером',
    :admin_name => 'courier',
    :tax_category_id => tax_cat.id
)
ship_method.zones << zone
ship_method.shipping_categories << ship_cat
ship_method.calculator = Spree::ShippingCalculator.create!(
    :type => 'Spree::Calculator::Shipping::FlatRate',
    :preferences => {
        :amount => 400,
        :currency => 'RUB'
    }
)
ship_method.save
ship_method = Spree::ShippingMethod.new(
    :name => 'Доставка курьером',
    :admin_name => 'courier_mkad_x',
    :tax_category_id => tax_cat.id
)
ship_method.zones << zone
ship_method.shipping_categories << ship_cat
ship_method.calculator = Spree::ShippingCalculator.create!(
    :type => 'Spree::Calculator::Shipping::FlatRate',
    :preferences => {
        :amount => 400,
        :currency => 'RUB'
    }
)
ship_method.save

ship_method_tk = Spree::ShippingMethod.new(
    :name => 'Транспортная компания',
    :admin_name => 'tk',
    :tax_category_id => tax_cat.id
)
ship_method_tk.zones << zone
ship_method_tk.shipping_categories << ship_cat_all
ship_method_tk.calculator = Spree::ShippingCalculator.create!(
    :type => 'Spree::Calculator::Shipping::FlatRate',
    :preferences => {
        :amount => 400,
        :currency => 'RUB'
    }
)
ship_method_tk.save

ship_method_pickup = Spree::ShippingMethod.new(
    :name => 'Самовывоз',
    :admin_name => 'pickup',
    :tax_category_id => tax_cat.id
)
ship_method_pickup.zones << zone
ship_method_pickup.shipping_categories << ship_cat_all
ship_method_pickup.calculator = Spree::ShippingCalculator.create!(
    :type => 'Spree::Calculator::Shipping::FlatRate',
    :preferences => {
        :amount => 0,
        :currency => 'RUB'
    }
)
ship_method_pickup.save

ship_method_pickup = Spree::ShippingMethod.new(
    :name => 'Самовывоз со скидкой',
    :admin_name => 'pickup_discount',
    :tax_category_id => tax_cat.id
)
ship_method_pickup.zones << zone
ship_method_pickup.shipping_categories << ship_cat_all
ship_method_pickup.calculator = Spree::ShippingCalculator.create!(
    :type => 'Spree::Calculator::Shipping::FlatRate',
    :preferences => {
        :amount => 0,
        :currency => 'RUB'
    }
)
ship_method_pickup.save

Spree::StockLocation.destroy_all
Spree::StockLocation.create!(
    :name => 'Москва',
    :admin_name => 'Склад',
    :city => 'Москва',
    :active => true,
    :backorderable_default => true,
    :propagate_all_variants => true,
    :country_id => Spree::Country.find_by_iso3('RUS').id
)