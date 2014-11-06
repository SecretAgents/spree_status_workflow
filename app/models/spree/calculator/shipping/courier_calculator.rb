require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping
    class CourierCalculator < ShippingCalculator
      preference :free_ship_price, :string, default: 2000

      def self.description
        'Цена в соотвествии с общей суммой заказа'
      end

      def compute_package(package)
        content_items = package.contents
        item_total = total(content_items)
        return 0 if item_total >= self.preferred_free_ship_price.to_i
        return 400 if item_total >= 1000 && item_total <= 1999
        500
      end
    end
  end
end