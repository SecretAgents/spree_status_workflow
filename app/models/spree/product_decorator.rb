Spree::Product.class_eval do

  def self.recalculate_popularity
    Spree::Order.all.find_each do |order|
      order.line_items.each do |line_item|
        line_item.product.popularity += line_item.quantity
        line_item.product.save
      end
    end
  end

end