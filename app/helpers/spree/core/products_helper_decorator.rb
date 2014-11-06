Spree::ProductsHelper.class_eval do

  def new_address_params
    [:housing, :building, :room, :porch, :floor, :elevators, :subway_station, :intercom_code]
  end

end