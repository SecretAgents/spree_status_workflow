Spree::Admin::OrdersController.class_eval do
  def new
    @order = Spree::Order.create
    @order.created_by = try_spree_current_user
    @order.set_type :phone
    @order.state = 'ordering'
    @order.save
    redirect_to edit_admin_order_url(@order)
  end

  def cancel
    if %w{cart ordering}.include? @order.state
      @order.destroy
      redirect_to '/admin/orders' and return
    end
    if @order.state == 'canceled'
      redirect_to :back
    else
      @order.cancel!
      flash[:success] = Spree.t(:order_canceled)
      redirect_to :back
    end
  end

  private

  def initialize_order_events
    @order_events = %w{cancel resume}
  end

end
