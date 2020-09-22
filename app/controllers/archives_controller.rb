class ArchivesController < ApplicationController
    before_action :authenticate_user!
    include SessionsHelper
    include ApplicationHelper
  
    def index
      @cameras = load_user_cameras(true, false)
    end
  end