Spree::Order::Checkout.class_eval do

  def change_status
    @order.status = @order.state
  end
end