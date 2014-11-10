Spree::OrdersController.class_eval do

  def update
    phone = nil
    if params[:phone].present?
      if params[:phone_code] != '' && params[:phone] != ''
        phone = ['+7', params[:phone_code], params[:phone]].join('')
        if (phone =~ /^\+7\d{10}$/).nil?
          flash[:error] = 'Неверно введён телефон.'
          redirect_to cart_path and return
        end
      end
      if phone.nil?
        flash[:error] = 'Необходимо ввести телефон.'
        redirect_to cart_path and return
      end
    end

    if params[:fast_order].present?

      @order.assign_by_phone phone
      authenticate_user_if_needed @order.user
      @order.add_payment_if_needed!
      @order.set_type :express
      @order.cart

      @order.complete

      if @order.completed?
        @current_order = nil
        session[:order_id] = nil
        flash.notice = Spree.t(:order_processed_successfully)
        flash['order_completed'] = true
        redirect_to order_path(@order)
      else
        flash[:error] = 'Ошибка в быстром заказе. Попробуйте перейти к оформлению заказа.'
        redirect_to cart_path and return
      end
    elsif @order.contents.update_cart(order_params)
      respond_with(@order) do |format|
        format.html do
          if params.has_key?(:checkout)
            @order.assign_by_phone phone
            authenticate_user_if_needed @order.user
            @order.add_payment_if_needed!
            @order.set_type :site
            @order.order if @order.cart?
            redirect_to checkout_state_path(@order.checkout_steps.first)
          else
            respond_with(@order)
          end
        end
        format.js
      end
    else
      respond_with(@order)
    end
  end

  def print
    @user = spree_current_user
    @order = Spree::Order.find_by_number(params[:id])
    raise ActiveRecord::RecordNotFound if @order.nil? || @user.nil? || !(@order.user_id == @user.id || @user.admin?)

    if @order.status == 'cart'
      flash[:error] = 'Заказ не оформлен!'
      redirect_to :back
    else
      render layout: false
    end
  end

  private
    def authenticate_user_if_needed(user)
      if flash['order_completed'] && user
        # Раскомментировать, если хотим сразу залогинить вновь созданного пользователя:
        set_flash_message(:notice, :signed_up)
        sign_in(:spree_user, user)
        session[:spree_user_signup] = true
      end
    end

end