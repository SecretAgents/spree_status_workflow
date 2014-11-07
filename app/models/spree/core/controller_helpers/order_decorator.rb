Spree::Core::ControllerHelpers::Order.class_eval do

  def current_order_params
    { currency: current_currency, guest_token: cookies.signed[:guest_token] }
  end

  def current_order_params_with_login
    { currency: current_currency, user_id: try_spree_current_user.try(:id) }
  end

  def find_order_by_token_or_user_with_login(options={})

    # Try to find order with native spree method without user_id
    order = find_order_by_token_or_user_without_login options

    # Trying to find with user_id
    if order.nil? && try_spree_current_user
      order = Spree::Order.incomplete.includes(:adjustments).lock(options[:lock]).find_by(current_order_params_with_login)
    end

    order
  end
  alias_method_chain :find_order_by_token_or_user, :login

end