class SnapshotReport < Sequel::Model
  # Class relationships.
  many_to_one :camera
end
