Spree::OrderContents.class_eval do

  def reset
    order.line_items = []
    # Update totals, then check if the order is eligible for any cart promotions.
    # If we do not update first, then the item total will be wrong and ItemTotal
    # promotion rules would not be triggered.
    reload_totals
    Spree::PromotionHandler::Cart.new(order).activate
    order.ensure_updated_shipments
    reload_totals
  end

end
