require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping
    class PickupCalculator < ShippingCalculator
      preference :percent, :decimal, default: 5

      def self.description
        'Калькулятор самовывоза'
      end

      def compute_package(package)
        content_items = package.contents
        item_total = total(content_items)
        value = item_total * BigDecimal(self.preferred_percent.to_s)*(-1) / 100.0
        (value * 100).round.to_f / 100

      end
    end
  end
end