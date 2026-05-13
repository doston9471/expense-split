# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Guest visits marketing home", type: :system do
  it "shows sign up call to action" do
    visit root_path
    expect(page).to have_content("Split costs fairly")
    expect(page).to have_link("Sign up")
  end
end
