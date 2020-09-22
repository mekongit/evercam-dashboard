require 'hashie'
require 'active_support/core_ext/object/blank'
class Camera < Sequel::Model
  include Hashie::Extensions::Mash
  many_to_one :vendor_model, class: 'VendorModel', key: :model_id
  many_to_one :owner, class: 'User', key: :owner_id
  one_to_many :shares, class: 'CameraShare'
  one_to_one :cloud_recording
  MAC_ADDRESS_PATTERN = /^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$/i
  # Finds the camera with a matching external id
  # (exid) string or nil if none exists
  def self.by_exid(exid)
    where(exid: exid).eager(:owner, vendor_model: :vendor).all.fetch(0, nil)
  end

  # Like by_exid but will raise an Evercam::NotFoundError
  # if the camera does not exist
  def self.by_exid!(exid)
    by_exid(exid) || (raise Evercam::NotFoundError, "The '#{exid}' camera does not exist.")
  end

  # Finds cameras which are within a given radius
  # (in meters) of a particular location
  def_dataset_method(:by_distance) do |from, meters|
    point = Geocoding.as_point(from)
    query = "ST_DWithin(location, ST_SetSRID(ST_Point(?, ?), 4326)::geography, ?)"
    where(query, point.lng, point.lat, meters)
  end

  # Finds cameras nearest to the given location
  # and order them by distance
  def self.nearest(location)
    query = "ST_Distance(location, ST_SetSRID(ST_Point(#{location[:longitude]}, #{location[:latitude]}), 4326)::geography)"
    zero_point = "ST_DWithin(location, ST_SetSRID(ST_Point(0, 0), 4326)::geography, 0)"
    where(status: "online", is_public: true, discoverable: true)
      .exclude(Sequel.lit(zero_point))
      .order(Sequel.lit(query))
  end

  def vendor
    vendor_model.vendor if vendor_model
  end

  # Determines if the presented token should be allowed
  # to conduct a particular action on this camera
  def allow?(right, token)
    AccessRightSet.for(self, token.nil? ? nil : token.target).allow?(right)
  end

  # The IANA standard timezone for this camera
  # defaulting to UTC if none specified
  def timezone
    Timezone::Zone.new zone: (values[:timezone] || 'Etc/UTC')
  end

  # Returns a deep merge of any config values set for this
  # camera with the config of any associated model
  def config
    fconf = vendor_model ? vendor_model.config : {}
    fconf.delete("auth")
    Hashie::Mash.new(fconf.deep_merge(values[:config] || {}))
  end

  # Returns the location for the camera as a GeoRuby
  # Point if it exists otherwise nil
  def location
    Geocoding.as_point(super) if super
  end

  # Sets the cameras location as a GeoRuby Point
  # instance or call with nil to unset
  def location=(val)
    point = Geocoding.as_point(val)
    super(point ? point.as_hex_ewkb : nil)
  end

  def url
    "/users/#{owner.username}/cameras/#{exid}"
  end

  # Utility method to check whether a string is a potential MAC address.
  def self.is_mac_address?(text)
    !(MAC_ADDRESS_PATTERN =~ text).nil?
  end

  def external_url(type = 'http')
    port = config.fetch("external_#{type}_port", nil)
    host = config.fetch('external_host', nil)
    unless host.blank?
      host = "#{type}://#{host}"
      host << ":#{port}" unless port.blank? or port == 80
    end
    host
  end

  def internal_url(type='http')
    port = config.fetch("internal_#{type}_port", nil)
    host = config.fetch('internal_host', nil)
    unless host.blank?
      host = "#{type}://#{host}"
      host << ":#{port}" unless port.blank? or port == 80
    end
    host
  end

  def dyndns_url(type='http')
    return nil if external_url.nil?
    port = config.fetch("external_#{type}_port", nil)
    host = "#{type}://#{exid}.evr.cm"
    unless host.blank?
      host << ":#{port}" unless port.blank? or port == 80
    end
    host
  end

  def res_url(type)
    url = config.fetch('snapshots', {}).fetch(type, '')
    url = '' if url.nil?
    url.prepend('/') unless url.start_with?('/') or url.empty?
    url
  end

  def cam_username
    basic_auth.fetch('username', '')
  end

  def cam_password
    basic_auth.fetch('password', '')
  end

  def validate
    super
    errors.add(:exid, "is invalid") if (/^[\w\s-]+$/ =~ exid).nil?
  end

  private

  def basic_auth
    (config.fetch('auth', {}) || {}).fetch('basic', {})
  end
end
