Spree::Api::ShipmentsController.class_eval do

  before_filter :find_and_update_shipment, only: [:ship, :ready, :add, :remove, :arrange, :deliver]

  def ship
    unless @shipment.shipped?
      @shipment.next!
    end
    respond_with(@shipment, default_template: :show)
  end

end
