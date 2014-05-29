Spree::OrderUpdater.class_eval do

  def update_payment_state

    # line_item are empty when user empties cart
    #if line_items.empty? || round_money(order.payment_total) < round_money(order.total)
      if payments.each.first.nil?
        order.payment_state = nil
      else
        order.payment_state = payments.each.first.state
      end

      order.change_status
    ##end
    order.state_changed('payment')
  end

  def update_shipment_state

    state_priorities = {
      :arrangement => 10,
      :ready => 8,
      :delivered => 9,
      :shipped => 7
    }

    if order.backordered?
      order.shipment_state = 'backorder'
    else
      shipment_states = shipments.states

      result_state = shipments.states.first
      shipment_states.each do |state|
        if state_priorities[state.to_sym] > state_priorities[result_state.to_sym]
          result_state = state
        end
      end
      order.shipment_state = result_state
      order.change_status
    end
    order.state_changed('shipment')
  end


end