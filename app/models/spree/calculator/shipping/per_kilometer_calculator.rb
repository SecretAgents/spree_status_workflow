require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping
    class PerKilometer < ShippingCalculator
      preference :kilometers, :integer, default: 1
      preference :amount, :decimal, default: 0
      preference :currency, :string, default: ->{ Spree::Config[:currency] }

      def self.description
        'Фиксированная стоимость за километр'
      end

      def compute_package(package)
        self.preferred_amount
      end
    end
  end
end
