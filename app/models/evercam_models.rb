# Copyright (c) 2014-2015, Evercam.io
require "bcrypt"
require "evercam_misc"
require "nokogiri"
require "sequel"
require "timezone"
Sequel::Model.plugin :boolean_readers
Sequel::Model.plugin :association_proxies
Sequel::Model.plugin :def_dataset_method
Sequel::Model.plugin :timestamps, update_on_create: true
if :postgres == Sequel::Model.db.adapter_scheme
  Sequel::Model.db.extension :pg_array, :pg_json
end
Sequel::Model.require_valid_table = false
require "evercam_models/access_right"
require "evercam_models/access_right_set"
require "evercam_models/access_token"
require "evercam_models/camera"
require "evercam_models/camera_activity"
require "evercam_models/camera_share"
require "evercam_models/camera_share_request"
require "evercam_models/country"
require "evercam_models/snapshot"
require "evercam_models/user"
require "evercam_models/archive"
require "evercam_models/snapshot_report"
require "evercam_models/cloud_recording"
require "evercam_models/vendor"
require "evercam_models/vendor_model"
require "evercam_models/right_sets/account_right_set"
require "evercam_models/right_sets/camera_right_set"
require "evercam_models/right_sets/snapshot_right_set"
require "evercam_models/geocoding"
module Evercam
end
