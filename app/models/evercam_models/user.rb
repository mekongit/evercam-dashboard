require 'bcrypt'
class User < Sequel::Model
  include BCrypt
  many_to_one :country
  one_to_many :cameras, key: :owner_id
  one_to_many :grants,
              class: 'AccessToken',
              conditions: Sequel.negate(client_id: nil),
              key: :user_id
  one_to_one  :token,
              class: 'AccessToken',
              conditions: { client_id: nil },
              after_load: proc { |u| u.send(:ensure_token_exists) },
              key: :user_id
  one_to_many :camera_shares

  def self.by_login(login)
    username_query = Sequel.ilike(:username, login)
    email_query = Sequel.ilike(:email, login)
    where(username_query).or(email_query).first
  end

  def fullname
    [firstname, lastname].join(' ')
  end

  def password
    Password.new(values[:password])
  end

  def password=(val)
    values[:password] = Password.create(val, cost: 10)
  end

  def before_save
    values[:encrypted_password] = values[:password]
    super
  end

  def confirmed?
    false == confirmed_at.nil?
  end

  def allow?(token)
    if token
      if token.user == self
        return true
      end
    end
  end

  def validate
    super
    errors.add(:firstname, "is invalid") if (/^[\p{Word}\s,.']+$/ =~ firstname).nil?
    errors.add(:lastname, "is invalid") if (/^[\p{Word}\s,.']+$/ =~ lastname).nil?
    errors.add(:email, "is invalid") if (/^.+@.+\..+$/ =~ email).nil?
  end

  private

  def ensure_token_exists
    self.token ||= AccessToken.new(
      expires_at: Time.at(2**31))
  end
end
