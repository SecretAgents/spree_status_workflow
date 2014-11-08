# Переопределение /spree_backend-2.3.1/app/helpers/spree/admin/orders_helper.rb

Spree::Admin::OrdersHelper.class_eval do

  # удалено data-confirm
  def event_links
    links = []
    @order_events.sort.each do |event|
      if @order.send("can_#{event}?")
        links << button_link_to(Spree.t(event), [event, :admin, @order],
                                :method => :put,
                                :icon => "#{event}"
        )
      end
    end
    links.join('&nbsp;').html_safe
  end

  # получение скидок, отличных от автоматической персональной скидки
  def another_discounts(order)
    order.adjustments.select {|p| p.source.nil? or p.source.type != 'Spree::Promotion::Actions::PersonalDiscountPromotion'}
  end
end