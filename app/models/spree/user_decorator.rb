Spree::User.class_eval do

  require 'securerandom'

  validates :phone,
      uniqueness: true,
      format: {
      with: /\A\+7\d{10}\z/,
      message: Spree.t(:invalid_phone_format)
  }, if: lambda { |a| a.email !='spree@example.com' }

  validates :email, format: {
      with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i,
      message: Spree.t(:invalid_email_format)
  }, if: lambda { |a| !a.email.blank? }

  # Remove the requirement on :phone being present.
  _validators.reject!{ |key, _| [:email].include?(key)  }

  _validate_callbacks.each do |callback|
    callback.raw_filter.attributes.delete :email if callback.raw_filter.is_a?(ActiveModel::Validations::PresenceValidator)
  end

  def self.generate_password(num = 3)
    SecureRandom.hex num
  end

  def self.sample_email(slug)
    "#{slug.gsub(/[\D]+/, '')}@#{}"
  end

  def self.sanitize_phone(phone)
    return phone if phone.nil?
    "+7#{phone.sub(/\A\+/, '').sub(/\A7/, '').gsub(/[\D]+/, '')}"
  end

end
