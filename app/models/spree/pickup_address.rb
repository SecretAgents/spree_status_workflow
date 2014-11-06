class Spree::PickupAddress < ActiveRecord::Base
  validates :address, presence: true
end
