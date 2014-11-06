Spree::Admin::Orders::CustomerDetailsController.class_eval do
        before_filter :default_params

        def default_params
          @order.email ||= ''
          @order.bill_address ||= Spree::Address.default(try_spree_current_user, "bill")
        end

end
