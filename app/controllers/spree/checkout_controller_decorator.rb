# encoding: utf-8

Spree::CheckoutController.class_eval do
  skip_filter :check_registration
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
    unless params[:order][:comment][:comment].blank?
      @order.create_comment
      @order.comments.first.comment = params[:order][:comment][:comment]
      @order.comments.first.comment.save
      params[:order].delete :comment
    end
    if @order.update_from_params(params, attributes, request.headers.env)
      @order.temporary_address = !params[:save_user_address]
      unless @order.complete
        flash[:error] = @order.errors.full_messages.join("\n")
        redirect_to checkout_state_path(@order.state) and return
      end

      if @order.completed?
        @current_order = nil
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

end