#! /usr/bin/env ruby
# This script was created to allow the user shares of the Evercam remembrance
# camera to be re-created after a bug caused them to be deleted. To create a
# share for all users in the system of a given camera go to the production
# environment issue commands like the following...
#
# $> irb -I./scripts
# irb> require 'create_base_shares'
# irb> Evercam.create_shares('evercam-remembrance-camera')

module Evercam
   # This function will share a specified camera with all users in the system if
   # the camera is public and the user does not already possess a share for the
   # camera.
   #
   # ==== Parameters
   # camera_id::  The unique identifier (exid) for the camera to be shared.
   def self.create_shares(camera_id)
      camera = Camera.where(exid: camera_id).first
      if !camera.nil?
         if camera.is_public?
            owner = camera.owner
            Sequel::Model.db.transaction do
               User.all.each do |user|
                  if camera.owner_id != user.id && CameraShare.where(camera_id: camera.id, user_id: user.id).count == 0
                     puts "Creating a share for the '#{user.username}' user (id: #{user.id})."
                     CameraShare.create(camera: camera,
                                        user:   user,
                                        sharer: owner,
                                        kind:   "public")
                  end
               end
            end
         else
            STDERR.puts "ERROR: The '#{camera_id}' camera is not public."
         end
      else
         STDERR.puts "ERROR: Unable to locate a camera for the id '#{camera_id}'."
      end
   end
end