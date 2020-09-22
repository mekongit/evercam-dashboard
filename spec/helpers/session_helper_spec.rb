require 'spec_helper'

describe SessionsHelper do

  let!(:user) {
    create(:active_user)
  }

  describe 'sign_in' do
    it "sets session key user to email and instance variable to user" do
      sign_in(user)
      expect(session[:user]).to be(user.email)
      expect(current_user).to be(user)
    end
  end

  describe 'sign_out' do
    it "clears session and sets instance variable to nil" do
      sign_in(user)
      sign_out
      expect(session[:user]).to be_nil
      expect(current_user).to be_nil
    end
  end

  describe 'signed_in?' do
    it "returns true if user is signed in" do
      sign_in(user)
      expect(signed_in?).to be(true)
    end

    it "returns false if user is signed out" do
      expect(signed_in?).to be(false)
    end
  end

  describe 'current_user=' do

    let!(:other_user) {
      create(:active_user)
    }

    it "returns true when comparing signed in user" do
      sign_in(user)
      expect(current_user==user).to be(true)
    end

    it "returns false when comparing other user" do
      sign_in(user)
      expect(current_user==other_user).to be(false)
    end
  end

end