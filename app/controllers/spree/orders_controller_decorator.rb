Spree::OrdersController.class_eval do

  def update
    if params[:fast_order].present? or params[:checkout].present?
      phone = retrieve_phone
      if (phone =~ /^\+7\d{10}$/).nil?
        flash[:error] = 'Неверно введён телефон.'
        redirect_to cart_path and return
      end
      if phone.nil?
        flash[:error] = 'Ошибка оформления заказа. Пожалуйста, введите номер Вашего телефона.'
        redirect_to cart_path and return
      end
    end

    if params[:fast_order].present?
      if complete_fast_order phone
        redirect_to order_path(@order)
      else
        flash[:error] = 'Ошибка в быстром заказе. Попробуйте перейти к оформлению заказа.'
        redirect_to cart_path and return
      end
    elsif @order.contents.update_cart(order_params)
      respond_with(@order) do |format|
        if params.has_key?(:checkout)
          @order.assign_by_phone phone
          authenticate_user_if_needed @order.user
          @order.add_payment_if_needed!
          @order.set_type :site
          @order.order if @order.cart?
          format.html { redirect_to checkout_state_path(@order.checkout_steps.first) }
          format.js
        else
          respond_with(@order)
        end
      end
    else
      respond_with(@order)
    end
  end

  def fast_order
    variant = Spree::Variant.find(params[:variant_id])
    if variant.nil?
      flash[:error] = 'Продукт не найден'
      redirect_to products_path and return
    end
    phone = retrieve_phone
    if (phone =~ /^\+7\d{10}$/).nil?
      flash[:error] = 'Неверно введён телефон.'
      redirect_to product_path(variant.product) and return
    end
    if phone.nil?
      flash[:error] = 'Ошибка оформления заказа. Пожалуйста, введите номер Вашего телефона.'
      redirect_to product_path(variant.product) and return
    end

    @order = current_order(create_order_if_necessary: true)
    @order.contents.reset
    populator = Spree::OrderPopulator.new(@order, current_currency)
    if populator.populate(params[:variant_id], params[:quantity])
      current_order.ensure_updated_shipments
    else
      flash[:error] = 'Не удалось добавить товар в корзину.'
      redirect_to product_path(variant.product) and return
    end

    if complete_fast_order phone
      redirect_to order_path(@order)
    else
      flash[:error] = 'Ошибка в быстром заказе. Попробуйте перейти к оформлению заказа.'
      redirect_to product_path(variant.product) and return
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

  def retrieve_phone
    phone = nil
    unless params[:phone].nil?
      if params[:phone_code] != '' && params[:phone] != ''
        phone = ['+7', params[:phone_code], params[:phone]].join('')
      end
    end
    phone
  end

  def complete_fast_order(phone)

    @order.assign_by_phone phone
    authenticate_user_if_needed @order.user
    @order.add_payment_if_needed!
    @order.set_type :express
    @order.state = 'cart' unless @order.cart?

    @order.complete

    if @order.completed?
      @current_order = nil
      session[:order_id] = nil
      flash.notice = Spree.t(:order_processed_successfully)
      flash['order_completed'] = true
      return true
    else
      return false
    end
  end

end