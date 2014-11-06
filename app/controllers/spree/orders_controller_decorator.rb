Spree::OrdersController.class_eval do

  def update
    phone = nil
    if params[:phone].present?
      if params[:phone_code][0] != '' && params[:phone][0] != ''
        phone = '+7' + params[:phone_code][0] + params[:phone][0]
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

      @user_just_registered = @order.assign_by_phone phone
      @order.add_payment_if_needed!
      @order.create_proposed_shipments
      @order.create_comment
      @order.order_type = Spree::Order.get_type_id :express
      @order.cart

      @order.complete

      if @order.completed?
        PreordersMailer.new_message(@order).deliver
        @current_order = nil
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
            @user_just_registered = @order.assign_by_phone phone
            @order.add_payment_if_needed!
            @order.create_proposed_shipments
            @order.create_comment
            @order.order_type = Spree::Order.get_type_id :site
            if @order.cart?
              @order.order
            end
            redirect_to checkout_state_path(@order.checkout_steps.first)
          else
            redirect_to cart_path
          end
        end
        format.js
      end
    else
      respond_with(@order)
    end
  end

end