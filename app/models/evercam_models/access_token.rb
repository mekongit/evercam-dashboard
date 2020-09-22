require 'securerandom'
class AccessToken < Sequel::Model
  plugin :after_initialize
  many_to_one :user
  one_to_many :rights, class: 'AccessRight', key: :token_id
  many_to_one :grantor, class: 'User', key: :grantor_id
  # Finds the token with a matching request
  # key string or nil if none exist
  def self.by_request(val)
    first(request: val)
  end

  # Sets up a new token with a randomly generated
  # request key which expires one hour from now
  def after_initialize
    self.request ||= SecureRandom.hex(16)
    self.expires_at ||= Time.now + 3600
    self.is_revoked ||= false
    super
  end

  # Determines the number of seconds until this
  # token expires (zero if already expired)
  def expires_in
    seconds = expires_at - Time.now
    seconds > 0 ? seconds.to_i : 0
  end

  # Whether or not this token is still valid
  # (i.e. neither expired nor revoked)
  def is_valid?
    false == is_revoked? && !is_expired?
  end

  def is_expired?
    Time.now > self.expires_at
  end

  # A convenience method that returns either the user or client associated
  # with an access token depending on which applies.
  def target
    user_id ? user : client
  end

  # This method is needed as 'refresh' seems to be already taken.
  def refresh_code
    self[:refresh]
  end
end
