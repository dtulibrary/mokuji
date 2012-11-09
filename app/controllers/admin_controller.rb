require 'securerandom'

class AdminController < ApplicationController
  http_basic_authenticate_with :name => ( API_CONFIG['authentication'] ? API_CONFIG['authentication']['username'] : ''), :password => (API_CONFIG['authentication'] ? API_CONFIG['authentication']['password'] : '')
  
  attr_accessor :users,:user,:task,:form
  
  def index
    @users = User.find(:all)
  end
  
  def show
    @user = User.find(:first,:conditions=>{:api_key=>params[:id]})
  end
  
  def new
    @user = User.new
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def edit
    @user = User.find(:first,:conditions=>{:api_key=>params[:id]})
  end
  
  def update
    # Validate params
    data = params[:user]
    data,invalid,invalid_param = validate_params(data)
    if invalid
      flash[:error] = "Invalid parameter: #{invalid_param}"
      redirect_to :action => :edit,:id=>params[:id]
    else
      @user = User.find(:first,:conditions=>{:api_key=>params[:id]})
      if @user.update_attributes(params[:user])
        redirect_to :action => :show, :id => @user.api_key
      else
        render 'edit'
      end
    end
  end
  
  def create
    # Validate params
    data = params[:user]
    data,invalid,invalid_param = validate_params(data)
    if invalid
      flash[:error] = "Invalid parameter: #{invalid_param}"
      render :new
    else
      # Create user
      api_key = SecureRandom.urlsafe_base64(15)
      while User.find(:first,:conditions=>{'api_key'=>api_key})
        api_key = SecureRandom.urlsafe_base64(15)
      end
      data['api_key'] = api_key
      @user = User.new(data)
      @user.save
      redirect_to :action => :show, :id => @user.api_key
    end
  end
  
  def delete
    @user = User.find(:first,:conditions=>{:api_key =>params[:id]})
    @user.destroy
    redirect_to :action => :index
  end
  
  private
  def validate_params(data)
    codes = Array.new
    codes << 200
    codes << 404
    invalid = false
    invalid_param = ''
    if not data[:sn] =~ /\w+/
      invalid=true
      invalid_param = 'Short name'
    elsif not data[:ln] =~ /\w+/
      invalid=true
      invalid_param = 'Long name'
    end
    return data,invalid,invalid_param
  end
end
