Spree::Address.class_eval do

  # Remove the requirement on :phone being present.
  _validators.reject!{ |key, _| [:firstname, :lastname, :address1, :city].include?(key)  }

  _validate_callbacks.each do |callback|
    callback.raw_filter.attributes.delete :firstname if callback.raw_filter.is_a?(ActiveModel::Validations::PresenceValidator)
    callback.raw_filter.attributes.delete :lastname if callback.raw_filter.is_a?(ActiveModel::Validations::PresenceValidator)
    callback.raw_filter.attributes.delete :address1 if callback.raw_filter.is_a?(ActiveModel::Validations::PresenceValidator)
    callback.raw_filter.attributes.delete :city if callback.raw_filter.is_a?(ActiveModel::Validations::PresenceValidator)
  end

  def require_zipcode?
    false
  end

  def require_phone?
    true
  end

end