class Archive < Sequel::Model
  # Archive Status constants.
  PENDING                 = 0
  PROCESSING              = 1
  COMPLETED               = 2
  FAILED                  = 3
  # Class relationships.
  many_to_one :camera
  many_to_one :user, class: 'User', key: :requested_by
  # Class validations.
  def validate
    super
    errors.add(:camera_id, 'has not been set') if !camera_id
    errors.add(:requested_by, 'has not been set') if !requested_by
  end
end
