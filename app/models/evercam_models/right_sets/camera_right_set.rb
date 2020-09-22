class CameraRightSet < AccessRightSet
  # The list of valid rights for a camera.
  VALID_RIGHTS = [AccessRight::DELETE,
                  AccessRight::EDIT,
                  AccessRight::LIST,
                  AccessRight::SNAPSHOT,
                  AccessRight::VIEW,
                  "#{AccessRight::GRANT}~#{AccessRight::DELETE}",
                  "#{AccessRight::GRANT}~#{AccessRight::EDIT}",
                  "#{AccessRight::GRANT}~#{AccessRight::LIST}",
                  "#{AccessRight::GRANT}~#{AccessRight::SNAPSHOT}",
                  "#{AccessRight::GRANT}~#{AccessRight::VIEW}"].freeze
  # List of public rights for a snapshot.
  PUBLIC_RIGHTS = [AccessRight::SNAPSHOT, AccessRight::LIST].freeze
  # Constructor for the CameraRightSet class.
  #
  # ==== Parameters
  # camera::     The camera that the rights pertain to.
  # requester::  The user or client that the rights pertain to.
  def initialize(camera, requester)
    super(camera, requester)
  end

  alias :camera :resource

  # Tests whether the requester has a specified permission on the camera.
  #
  # ==== Parameters
  # right::  The name of the right to perform the check for.
  def allow?(right)
    type == :user ? user_allow?(right) : client_allow?(right)
  end

  # Tests whether the requester has all of a specified set of permissions on
  # the camera.
  #
  # ==== Parameters
  # *rights::  An array of the rights to include in the check.
  def allow_all?(*rights)
    rights.detect { |right| allow?(right) == false }.nil?
  end

  # Tests whether the requester has at least one of a specified set of
  # permissions on the camera.
  #
  # ==== Parameters
  # *rights::  An array of the rights to include in the check.
  def allow_any?(*rights)
    !(rights.find {|right| allow?(right)}.nil?)
  end

  # This method gifts one or more rights to the requester on the camera.
  #
  # ==== Parameters
  # *rights::  An array of the rights to be granted to the requester.
  def grant(*rights)
    (rights - recorded_rights).each do |right|
      raise "#{right} is not a valid camera access right." if !valid_right?(right)
      AccessRight.create(token:  token,
                         camera: camera,
                         right:  right,
                         status: AccessRight::ACTIVE) if !is_owner?
    end
  end

  # This method removes one or more rights on the camera from the requester.
  #
  # ==== Parameters
  # *rights::  An array of the rights to be revoked.
  def revoke(*rights)
    type == :user ? user_revoke(*rights) : client_revoke(*rights)
  end

  # Tests whether a specified right is valid for a camera.
  #
  # ==== Parameters.
  # right::  The right to perform the test for.
  def valid_right?(right)
    CameraRightSet.valid_right?(right)
  end

  # Class level implementation of the valid right test.
  def self.valid_right?(right)
    VALID_RIGHTS.include?(right)
  end

  # This method fetches a list of rights that the current requester possesses
  # actual records in the access_rights table for.
  def recorded_rights
    rights = []
    AccessRight.where(token: token,
                      camera: camera,
                      status: AccessRight::ACTIVE).each do |record|
      rights << record.right
    end
    rights.uniq
  end

  private

  # An implementation of the allow? method specific to checking user
  # permissions.
  #
  # ==== Parameters
  # right::  The name of the right to perform the check for.
  def user_allow?(right)
    raise "#{right} is not a valid camera access right." if !valid_right?(right)
    result = is_public? && PUBLIC_RIGHTS.include?(right)
    if !result
      if !requester.nil?
        if !camera.nil?
          result = is_owner?
          if !result
            if token.valid?
              result = (AccessRight.where(token_id:  token.id,
                                          camera_id: camera.id,
                                          status:    AccessRight::ACTIVE,
                                          right:     right).count > 0)
              if !result
                # Check for an account level permissions grant.
                rights = AccountRightSet.new(camera.owner, requester, AccessRight::CAMERAS)
                result = rights.allow?(right)
              end
            end
          end
        end
      end
    end
    result
  end

  # An implementation of the revoke method specific to removing rights from
  # a user.
  #
  # ==== Parameters
  # *rights::  The rights to be removed from the user.
  def user_revoke(*rights)
    if allow_any?(*rights) && !is_owner?
      AccessRight.where(token:  token,
                        camera: camera,
                        status: AccessRight::ACTIVE,
                        right: rights).update(status: AccessRight::DELETED)
    end
  end

  # An implementation of the allow? method specific to checking client
  # permissions.
  #
  # ==== Parameters
  # right::  The name of the right to perform the check for.
  def client_allow?(right)
    raise "#{right} is not a valid camera access right." if !valid_right?(right)
    result = is_public? && PUBLIC_RIGHTS.include?(right)
    if !result
      if !requester.nil?
        if !camera.nil?
          query = AccessRight.join(:access_tokens, id: :token_id).where(client_id: requester.id,
                                                                        is_revoked: false,
                                                                        camera_id: camera.id,
                                                                        status: AccessRight::ACTIVE,
                                                                        right: right)
          result = (query.count > 0)
          if !result
            # Check for an account level permissions grant.
            result = AccountRightSet.new(camera.owner, requester, AccessRight::CAMERAS).allow?(right)
          end
        end
      end
    end
    result
  end

  # An implementation of the revoke method specific to removing rights from
  # a user.
  #
  # ==== Parameters
  # *rights::  The rights to be removed from the user.
  def client_revoke(*rights)
    if allow_any?(*rights)
      AccessRight.select(:token_id, :right).join(:access_tokens, id: :token_id).where(client_id: requester.id,
                                                                                      is_revoked: false,
                                                                                      camera_id: camera.id,
                                                                                      status: AccessRight::ACTIVE,
                                                                                      right: rights).each do |record|
        AccessRight.where(token_id: record.token_id,
                          status: AccessRight::ACTIVE,
                          right:  record.right).update(status: AccessRight::DELETED)
      end
    end
  end
end
