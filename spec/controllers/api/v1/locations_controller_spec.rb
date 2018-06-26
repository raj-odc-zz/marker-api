require "rails_helper"

RSpec.describe Api::V1::LocationsController, :type => :controller do
  describe "GET index" do

  	it "responds to json format" do
      get :index
      expect(response.content_type).to eq "application/json"
    end

    it "has a 200 status code" do
      get :index
      expect(response.status).to eq(200)
    end

    it "has location as empty" do
      get :index
      expect(JSON.parse(response.body)["locations"].length).to eq(0)
    end

    it "has location count as 1" do
      post :create, :params => { :address => "Berlin" }
      get :index
      expect(JSON.parse(response.body)["locations"].length).to eq(1)
    end

  end

  describe "POST create" do

  	it "responds to json format" do
      post :create, :params => { :address => "Hamburg" }
      expect(response.content_type).to eq "application/json"
    end

    it "has a 201 status code" do
      post :create, :params => { :address => "Berlin" }
      expect(response.status).to eq(201)
    end

    it "has a 404 status code when address is empty" do
      post :create, :params => { :address => "" }
      expect(response.status).to eq(404)
    end

    it "has a 404 status code when address not found" do
      post :create, :params => { :address => "ABCDEFGHIJ" }
      expect(response.status).to eq(404)
    end

    it "has marker long_name as Berlin" do
      post :create, :params => { :address => "Berlin" }
      expect(JSON.parse(response.body)["locations"]["long_name"]).to eq("Berlin")
    end

  end

  describe "PUT update" do
  	before(:each) do
    	post :create, :params => { :address => "Berlin" }
  	end

  	it "responds to json format" do
      put :update, :params => { :address => "Hamburg", :id => 1 }
      expect(response.content_type).to eq "application/json"
    end

    it "has a 200 status code" do
      put :update, :params => { :address => "Berlin", :id => 1 }
      expect(response.status).to eq(200)
    end

    it "has a 404 status code when address is not found" do
      put :update, :params => { :address => "", :id => 1 }
      expect(response.status).to eq(404)
    end

    it "has a 404 status code when address not found" do
      put :update, :params => { :address => "ABCDEFGHIJ", :id => 1 }
      expect(response.status).to eq(404)
    end

    it "has marker long_name as Germany" do
      put :update, :params => { :address => "Germany", :id => 1 }
      expect(JSON.parse(response.body)["locations"]["long_name"]).to eq("Germany")
    end

    it "has a 500 status code when id is not found" do
      put :update, :params => { :id => 10 }
      expect(response.status).to eq(500)
    end

  end

  describe "DELETE destroy" do
  	before(:each) do
    	post :create, :params => { :address => "Berlin" }
  	end

  	it "responds to json format" do
      delete :destroy, :params => { :id => 1 }
      expect(response.content_type).to eq "application/json"
    end

    it "has a 200 status code" do
      delete :destroy, :params => { :id => 1 }
      expect(response.status).to eq(200)
    end

    it "has a 500 status code when id is not found" do
      delete :destroy, :params => { :id => 10 }
      expect(response.status).to eq(500)
    end

  end
end