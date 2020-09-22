class Snapshot < Sequel::Model
  set_primary_key :id
  DEFAULT_RANGE = 1
  def self.snapshot_by_ts(camera_id, timestamp, range = nil)
    range ||= DEFAULT_RANGE
    if range < DEFAULT_RANGE then range = DEFAULT_RANGE end
    where(camera_id: camera_id).order(:created_at).last(:created_at => (timestamp - range + 1).to_s...(timestamp + range).to_s)
  end

  def self.snapshot_by_ts!(camera_id, timestamp, range = nil)
    snapshot_by_ts(camera_id, timestamp, range) || (
    raise Evercam::NotFoundError, 'Snapshot does not exist')
  end
end
