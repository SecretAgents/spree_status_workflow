Spree::Admin::Orders::CustomerDetailsController.class_eval do
        before_filter :default_params

        def default_params
          stock = Spree::StockLocation.first
          @order.email ||= 'empty@empty.ru'
          @order.bill_address ||= Spree::Address.create({
                                                           address1: '-',
                                                           city: '-',
                                                           phone: 7,
                                                           zipcode: 000,
                                                           country: Spree::Country.find_by_name!("Russian Federation"),
                                                           state_name: stock.name,
                                                           state_id: stock.id
                                                       })

        end

end
