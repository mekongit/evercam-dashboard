class AccessRightSet
  def initialize(resource, requester)
    @resource     = resource
    @requester    = requester
    @type         = requester.instance_of?(User) ? :user : :client
    @access_token = load_token
  end

  attr_reader :resource, :requester, :type
  # Tests whether the requester has a specified permission on the resource
  # covered by the right set.
  def allow?(_right)
    false
  end

  # Convenience method for testing permissions on a set of rights.
  def allow_all?(_rights)
    false
  end

  # Tests whether the requester possesses at least one of a set of permissions
  # on a resource.
  def allow_any?(_rights)
    false
  end

  # Tests whether the requester possesses the right to grant a specified right
  # to another user.
  def can_grant?(right)
    allow?("#{AccessRight::GRANT}~#{right}")
  end

  # Tests whether the requester possesses the right to grant a all of a set of
  # specified rights to another user.
  def can_grant_all?(*rights)
    rights.detect {|right| can_grant?(right) == false}.nil?
  end

  def grant(_rights)
    raise "The #{self.class.name} class has not implemented the #grant() method."
  end

  def revoke(_rights)
    raise "The #{self.class.name} class has not implemented the #revoke() method."
  end

  # Tests whether the requester is the owner of the resource being accessed.
  def is_owner?
    @type == :user && @resource.respond_to?(:owner) ? (@resource.owner.id == @requester.id) : false
  end

  # This method is used to test whether the underlying resource is public.
  def is_public?
    @resource.respond_to?(:is_public?) && @resource.is_public?
  end

  # This method fetches the access token for the right set. For client right
  # sets this will generally be the client latest token.
  def token
    @access_token
  end

  # Tests whether it is valid to have a specified right on the underlying
  # resource.
  def valid_right?(_right)
    false
  end

  # Tests whether it is valid to have
  def valid_rights?(*rights)
    rights.detect {|right| valid_right?(right) == false}.nil?
  end

  # This method fetches a list of rights that the current requester possesses
  # actual records in the access_rights table for.
  def recorded_rights
    raise "The #{self.class.name} class has not implemented the #recorded_rights() method."
  end

  # Fetches a specific resource based access right set. Use this in preference
  # to creating the resource set classes directly.
  #
  # ==== Parameters
  # resource::   The resource related to the right set (e.g. a Camera object).
  # requester::  The user or client that the right set relates to.
  def self.for(resource, requester)
    if resource.instance_of?(Camera)
      CameraRightSet.new(resource, requester)
    elsif resource.instance_of?(Snapshot)
      SnapshotRightSet.new(resource, requester)
    else
      raise "Right set requested for unknown resource class '#{resource.class.name}'."
    end
  end

  private

  def load_token
    token = nil
    if @type != :user && !@requester.nil?
      token = AccessToken.where(client_id: @requester.id).order(Sequel.desc(:created_at)).first
      token = AccessToken.create(client: @requester, refresh: SecureRandom.base64(24)) if token.nil?
    elsif !@requester.nil?
      token = @requester.token
    end
    token
  end
end
