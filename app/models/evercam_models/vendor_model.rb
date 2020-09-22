class VendorModel < Sequel::Model
  many_to_one :vendor
  one_to_many :cameras
  DEFAULT = 'Default'

end
