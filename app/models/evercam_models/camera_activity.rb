require 'active_support/core_ext/object/blank'
class CameraActivity < Sequel::Model
  def to_s
    if ['shared', 'stopped sharing', 'updated share'].include?(action)
      "[#{camera_exid}] #{name} #{action} with #{extra['with']} at #{done_at} from #{ip}"
    elsif %w[online offline].include?(action)
      "[#{camera_exid}] went #{action} at #{done_at}"
    elsif access_token_id.nil?
      "[#{camera_exid}] Anonymous #{action} at #{done_at} from #{ip}"
    else
      "[#{camera_exid}] #{name} #{action} at #{done_at} from #{ip}"
    end
  end
end
