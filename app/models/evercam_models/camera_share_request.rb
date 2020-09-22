class CameraShareRequest < Sequel::Model
   # Field length constants.
   MAX_KEY_LEN               = 100
   MAX_EMAIL_LEN             = 250
   MAX_RIGHTS_LEN            = 1000
   # Status constants.
   PENDING                   = -1
   CANCELLED                 = -2
   USED                      = 1
   ALL_STATUSES              = [USED, CANCELLED, PENDING]
   many_to_one :user
   many_to_one :camera
   def validate
      super
      errors.add(:camera_id, "has not been specified") if camera_id.nil?
      errors.add(:user_id, "has not been specified") if user_id.nil?
      errors.add(:key, "has not been specified") if [nil, ""].include?(key)
      errors.add(:key, "is too long") if key && key.length > MAX_KEY_LEN
      errors.add(:email, "has not been specified") if [nil, ""].include?(email)
      errors.add(:email, "is too long") if email && email.length > MAX_EMAIL_LEN
      errors.add(:status, "is invalid") if !ALL_STATUSES.include?(status)
      errors.add(:rights, "has not been specified") if [nil, ""].include?(rights)
      errors.add(:rights, "is too long") if rights && rights.length > MAX_RIGHTS_LEN
   end

   def before_validation
      self.key = SecureRandom.hex(25) if [nil, ''].include?(self.key)
   end
end
