class CameraShare < Sequel::Model
	# Share kind constants.
	PRIVATE                   = 'private'.freeze
	PUBLIC                    = 'public'.freeze
	ALL_KINDS                 = [PRIVATE, PUBLIC]
	# Class relationships.
	many_to_one :camera
	many_to_one :user
	many_to_one :sharer, class: 'User', key: :sharer_id
	# Class validations.
	def validate
		super
		errors.add(:camera_id, 'has not been set') if !camera_id
		errors.add(:user_id, 'has not been set') if !user_id
		errors.add(:kind, 'has not been set') if !kind
		errors.add(:kind, 'is invalid') if !ALL_KINDS.include?(kind)
	end
end
