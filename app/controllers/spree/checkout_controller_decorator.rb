# encoding: utf-8

Spree::CheckoutController.class_eval do
  skip_filter :check_registration
  before_filter :set_order_status, :set_pickup_addresses
  # skip_before_filter :verify_authenticity_token, only: :update

  helper 'spree/products'

  def before_ordering
    before_address
    before_delivery
  end

  def update
    attributes = permitted_checkout_attributes + [
        :bill_address_attributes => permitted_address_attributes + new_address_params,
        :ship_address_attributes => permitted_address_attributes + new_address_params,
    ]
    if params[:order][:user].present?
      unless params[:order][:user][:password].blank?
        if @order.user.valid_password? params[:order][:user][:password]
          set_flash_message(:notice, :signed_up)
          sign_in(:spree_user, @order.user)
          session[:spree_user_signup] = true
        else
          flash[:error] = 'Не удалось войти в систему. Пароль неверен.'
        end
        params[:order][:user].delete :password
      end
      unless params[:order][:user][:email].blank?
        @order.user.email = params[:order][:user][:email]
      end
      unless params[:order][:user][:name].blank?
        @order.user.name = params[:order][:user][:name]
        @order.user.bill_address.firstname = params[:order][:user][:name]
      end
      unless params[:order][:user][:agreement].blank?
        @order.user.agreement = true
      end
      @order.user.save
    end
    if params[:order][:shipments_attributes].present?
      params[:order][:shipments_attributes].each do |key, order_shipment|
        shipment = @order.shipments.find_by_id order_shipment[:id]
        unless shipment.nil?
          shipment.selected_shipping_rate_id = order_shipment[:selected_shipping_rate_id]
          shipment.save
        end
      end
    end
    @order.state = :ordering if params[:state] == 'delivery'
    if @order.update_from_params(params, attributes, request.headers.env)
      @order.temporary_address = !params[:save_user_address]
      unless @order.complete
        flash[:error] = @order.errors.full_messages.join("\n")
        redirect_to checkout_state_path(@order.state) and return
      end

      if @order.completed?
        @current_order = nil
        session[:order_id] = nil
        flash.notice = Spree.t(:order_processed_successfully)
        flash['order_completed'] = true
        redirect_to order_path(@order)
      else
        flash[:error] = @order.errors.full_messages.join("\n")
        redirect_to checkout_state_path(@order.state)
      end
    else
      render :edit
    end
  end

  private

  def set_pickup_addresses
    @pickup_addresses = Spree::PickupAddress.all
  end

end