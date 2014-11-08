Spree::Admin::OrdersController.class_eval do
  def new
    @order = Spree::Order.create
    @order.created_by = try_spree_current_user
    @order.order_type = 1
    @order.state = 'ordering'
    @order.save
    redirect_to edit_admin_order_url(@order)
  end
end
