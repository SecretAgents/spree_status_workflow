class ChangeCalculatorInPickupShipmethod < ActiveRecord::Migration
  def up
    method = Spree::ShippingMethod.where(:admin_name => 'pickup_discount').first
    if method.present?
      method.calculator = Spree::ShippingCalculator.create!(
          :type => 'Spree::Calculator::Shipping::PickupCalculator',
          :preferences => {
              :percent => 5,
          }
      )
      method.save
    end
    method = Spree::ShippingMethod.where(:admin_name => 'courier').first
    if method.present?
      method.calculator = Spree::ShippingCalculator.create!(
          :type => 'Spree::Calculator::Shipping::CourierCalculator',
          :preferences => {
              :free_ship_price => 2000,
          }
      )
      method.save
    end
  end
end