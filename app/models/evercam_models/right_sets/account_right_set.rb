class AccountRightSet < AccessRightSet
  # The list of valid rights for a account.
  VALID_RIGHTS = { AccessRight::CAMERAS  => [AccessRight::SNAPSHOT,
                                             AccessRight::DELETE,
                                             AccessRight::EDIT,
                                             AccessRight::LIST,
                                             AccessRight::VIEW,
                                             "#{AccessRight::GRANT}~#{AccessRight::SNAPSHOT}",
                                             "#{AccessRight::GRANT}~#{AccessRight::DELETE}",
                                             "#{AccessRight::GRANT}~#{AccessRight::EDIT}",
                                             "#{AccessRight::GRANT}~#{AccessRight::LIST}",
                                             "#{AccessRight::GRANT}~#{AccessRight::VIEW}"],
                  AccessRight::SNAPSHOTS => [AccessRight::DELETE,
                                             AccessRight::EDIT,
                                             AccessRight::LIST,
                                             AccessRight::VIEW,
                                             "#{AccessRight::GRANT}~#{AccessRight::SNAPSHOT}",
                                             "#{AccessRight::GRANT}~#{AccessRight::DELETE}",
                                             "#{AccessRight::GRANT}~#{AccessRight::EDIT}",
                                             "#{AccessRight::GRANT}~#{AccessRight::LIST}",
                                             "#{AccessRight::GRANT}~#{AccessRight::VIEW}"],
                  AccessRight::USER      => [AccessRight::DELETE,
                                             AccessRight::EDIT,
                                             AccessRight::LIST,
                                             AccessRight::VIEW] }.freeze
  # List of account public rights.
  PUBLIC_RIGHTS = []

  # Constructor for the AccountRightSet class.
  #
  # ==== Parameters
  # user::       The user whose account the rights apply to.
  # requester::  The user or client that the rights pertain to.
  # scope::      The scope that the right will apply to.
  def initialize(user, requester, scope)
    super(user, requester)
    @scope = scope
  end

  attr_reader :scope
  alias :user :resource
  # Tests whether the requester is the owner of the account.
  def is_owner?
    resource.id == requester.id
  end

  # Tests whether the requester has a specified permission on the account.
  #
  # ==== Parameters
  # right::  The name of the right to perform the check for.
  def allow?(right)
    type == :user ? user_allow?(right) : client_allow?(right)
  end

  # Tests whether the requester has all of a specified set of permissions on
  # the account.
  #
  # ==== Parameters
  # *rights::  An array of the rights to include in the check.
  def allow_all?(*rights)
    rights.detect { |right| allow?(right) == false }.nil?
  end

  # Tests whether the requester has at least one of a specified set of
  # permissions on the account.
  #
  # ==== Parameters
  # *rights::  An array of the rights to include in the check.
  def allow_any?(*rights)
    !(rights.detect { |right| allow?(right) == false }.nil?)
  end

  # This method gifts one or more rights to the requester on the account.
  #
  # ==== Parameters
  # rights::  An array of the rights to be granted to the requester.
  def grant(*rights)
    (rights - recorded_rights).each do |right|
      raise "#{right} is not a valid account access right." if !valid_right?(right)
      AccessRight.create(token:    token,
                         account:  user,
                         right:    right,
                         scope:    @scope,
                         status:   AccessRight::ACTIVE) if !is_owner?
    end
  end

  # This method removes one or more rights on the account from the requester.
  #
  # ==== Parameters
  # *rights::  An array of the rights to be revoked.
  def revoke(*rights)
    type == :user ? user_revoke(*rights) : client_revoke(*rights)
  end

  # Tests whether a specified right is valid for a account.
  #
  # ==== Parameters.
  # right::  The right to perform the test for.
  def valid_right?(right)
    AccountRightSet.valid_right?(right, @scope)
  end

  # Class level implementation of the valid right test.
  def self.valid_right?(right, scope)
    VALID_RIGHTS[scope].include?(right)
  end

  # This method fetches a list of rights that the current requester possesses
  # actual records in the access_rights table for.
  def recorded_rights
    rights = []
    AccessRight.where(token: token,
                      account: user,
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
    raise "#{right} is not a valid account access right." if !valid_right?(right)
    result = is_public? && PUBLIC_RIGHTS.include?(right)
    if !result
      if !requester.nil?
        if !user.nil?
          result = is_owner?
          if !result && token.valid?
            result = (AccessRight.where(token_id:    token.id,
                                        account_id:  user.id,
                                        status:      AccessRight::ACTIVE,
                                        right:       right,
                                        scope:       @scope).count > 0)
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
    if allow_any?(*rights) && !is_owner? && !is_public?
      AccessRight.where(token:    token,
                        account:  user,
                        status:   AccessRight::ACTIVE,
                        right:    rights,
                        scope:    @scope).update(status: AccessRight::DELETED)
    end
  end

  # An implementation of the allow? method specific to checking client
  # permissions.
  #
  # ==== Parameters
  # right::  The name of the right to perform the check for.
  def client_allow?(right)
    raise "#{right} is not a valid account access right." if !valid_right?(right)
    result = is_public? && PUBLIC_RIGHTS.include?(right)
    if !result && !requester.nil? && !user.nil?
      query = AccessRight.join(:access_tokens, id: :token_id).where(client_id: requester.id,
                                                                    is_revoked: false,
                                                                    account_id: user.id,
                                                                    status: AccessRight::ACTIVE,
                                                                    right: right,
                                                                    scope: @scope)
      result = (query.count > 0)
    end
    result
  end

  # An implementation of the revoke method specific to removing rights from
  # a user.
  #
  # ==== Parameters
  # *rights::  The rights to be removed from the user.
  def client_revoke(*rights)
    if allow_any?(*rights) && !is_public?
      AccessRight.select(:token_id, :right).join(:access_tokens, id: :token_id).where(client_id: requester.id,
                                                                                      is_revoked: false,
                                                                                      account_id: user.id,
                                                                                      status: AccessRight::ACTIVE,
                                                                                      right: rights,
                                                                                      scope: @scope).each do |record|
        AccessRight.where(token_id: record.token_id,
                          status: AccessRight::ACTIVE,
                          right:  record.right).update(status: AccessRight::DELETED)
      end
    end
  end
end
