class AccessRight < Sequel::Model
  # Right constants.
  SNAPSHOT                   = 'snapshot'.freeze
  VIEW                       = 'view'.freeze
  EDIT                       = 'edit'.freeze
  DELETE                     = 'delete'.freeze
  LIST                       = "list".freeze
  SHARE                      = "share".freeze
  GRANT                      = 'grant'.freeze
  BASE_RIGHTS                = [SNAPSHOT, VIEW, EDIT, DELETE, LIST, SHARE]
  ALL_RIGHTS                 = BASE_RIGHTS + [GRANT]
  # Scope constants.
  CAMERAS                    = "cameras".freeze
  SNAPSHOTS                  = "snapshots".freeze
  USER                       = "user".freeze
  ALL_SCOPES                 = [CAMERAS, SNAPSHOTS, USER]
  # Status constants.
  ACTIVE                     = 1
  DELETED                    = -1
  ALL_STATUSES               = [ACTIVE, DELETED]
  many_to_one :token, class: 'AccessToken'
  many_to_one :camera
  many_to_one :grantor, class: 'User', key: :grantor_id
  many_to_one :snapshot
  many_to_one :account, class: 'User', key: :account_id
  # Fetches the resource associated with the access right. This could be a
  # camera, a snapshot or a user (for account rights).
  def resource
    if !camera_id.nil?
      camera
    elsif !snapshot_id.nil?
      snapshot
    else
      account
    end
  end

  # A simple method to test whether this access right relates to an individual
  # camera.
  def for_camera?
    !camera_id.nil?
  end

  # A simple method to test whether this access right relates to an individual
  # snapshot.
  def for_snapshot?
    !snapshot_id.nil?
  end

  # A simple method to test whether this access right relates to an entire
  # users account.
  def for_account?
    !account_id.nil?
  end

  # Returns a basic string representation of an AccessRight.
  def to_s
    [camera_id, token_id, right].join(':')
  end

  # Validates the objects values. Implicitly called before save.
  def validate
    super
    errors.add(:token_id, "is not set") if !token_id
    if camera_id.nil?
      if snapshot_id.nil?
        if account_id.nil?
          errors.add(:resource, 'has not been set')
        end
      end
    end
    errors.add(:status, "is invalid") if !ALL_STATUSES.include?(status)
    if !BASE_RIGHTS.include?(right)
      match = /^grant~(.+)$/.match(right)
      if match
        errors.add(:right, "is invalid") if !BASE_RIGHTS.include?(match[1])
      else
        errors.add(:right, "is invalid")
      end
    end
    if scope
      if !ALL_SCOPES.include?(scope)
        errors.add(:scope, "is invalid")
      end
    end
  end

  # Returns an AccessRightSet for a given resource and token combination.
  def self.rights_for(resource, token)
    AccessRightSet.for(resource, token.target)
  end

  def self.valid_right_name?(name)
    result = BASE_RIGHTS.include?(name)
    if !result
      match = /^grant~(.+)$/.match(name)
      result = BASE_RIGHTS.include?(match[1]) if match
    end
    result
  end
end
