
class ApiController < ApplicationController
  include ApiHelper
  before_filter :authenticate_request, :only => [:get_articles,:get_issue_keys,:get_next_key,:get_prev_key,:template]
  before_filter :set_instance_variables, :only => [:get_articles,:get_issue_keys,:get_next_key,:get_prev_key,:template]
  
  # Data variables
  attr_accessor :issue_key,:issn,:articles,:new_issue_key,:is_bound,:issue_keys
  attr_accessor :groups,:issues,:task,:user
  # Query parameter variables
  attr_accessor :proxy_url,:api_key

  def index
  end
  
  def template
    # @issn = params[:issn]
    # @issue_key = params[:issue_key]
    @task = params[:task]
    @proxy_url = params[:proxy_url]
    ### Get issue keys ###
    if not @task or @task == 'get_issue_keys'
      response = get_data(JOBRO_BASE_URL+@issn)
      if response
        @groups,@issues = parse_jobro_response(response)
        render :status=>:not_found and return if not @groups
        @articles = articles_helper(@groups[0]['issues'][0]['jobro_key'])#@new_issue_key
      else
        render :status=>:not_found and return
      end
    ### Get articles ###
    elsif @task == 'get_articles'
      @articles = articles_helper(@issue_key)
      render :status=>:not_found and return if not @articles
    ### Get previous key ###
    elsif @task == 'get_prev_key'
      @is_bound,@new_issue_key=prev_key_helper(@issn,@issue_key)
      if @new_issue_key
        @issue_key = @new_issue_key
        @articles = articles_helper(@issue_key)#@new_issue_key
      else
        @articles = articles_helper(@issue_key)
      end
    ### Get next key ###
    elsif @task == 'get_next_key'
      @is_bound,@new_issue_key=next_key_helper(@issn,@issue_key)
      if @new_issue_key
        @issue_key = @new_issue_key
        @articles = articles_helper(@issue_key)#@new_issue_key
      else
        @articles = articles_helper(@issue_key)
      end
    end
    ###
    respond_to do |format|
      format.html
      format.js
    end
    #render :layout => false
  end
  
  def get_articles
    # @issue_key = params[:issue_key]
    @articles = articles_helper(@issue_key)
    render :status => :not_found, :formats => :xml and return if not @articles
    render :formats => :xml and return
  end
  
  def get_issue_keys
    # @issn = params[:issn]
    response = get_data(JOBRO_BASE_URL+@issn)
    if response
      @issue_keys = response
      render :formats => :xml and return
      #TODO:the response may simply be forwarded ?
    else
      render :status => :not_found,:formats => :xml and return
    end
  end
  
  def get_next_key#(issn,issue_key)
    # @issue_key = params[:issue_key]
    # @issn = params[:issn]
    @is_bound,@new_issue_key=next_key_helper(@issn,@issue_key)
    render :status => :not_found, :formats => :xml and return if @is_bound == nil
    render :formats => :xml and return
  end
  
  def get_prev_key#(issn,issue_key)
    # @issue_key = params[:issue_key]
    # @issn = params[:issn]
    @is_bound,@new_issue_key=prev_key_helper(@issn,@issue_key)
    render :status => :not_found, :formats => :xml and return if @is_bound == nil
    render :formats => :xml and return
  end
  
  ### Fix routing issues ###
  def routing_error
    render_404 and return
  end
  
  ### Before filter operations ###
  protected
  def authenticate_request
    @api_key = params[:api_key]
    @user = User.find(:first,:conditions=>{:api_key=>@api_key})
    #render_401 and return if not @user
    render :file => "#{Rails.root}/public/401", :status => :unauthorized, :formats => :html and return if not @user
  end
  
  protected
  def set_instance_variables
    @issue_key = params[:issue_key] if params[:issue_key]
    @issn = params[:issn] if params[:issn]
  end
  
  ### Error pages ###
  private
  def render_401
    #TODO: should we log something on unauthorized attempts ???
    render :file => "#{Rails.root}/public/401", :status => :unauthorized, :formats => :html
  end
  
  private
  def render_404(perform_log=true)
    # Perform logging.
    #write_to_log if perform_log
    #TODO: enable logging..
    # Render
    render :file => "#{Rails.root}/public/404", :status => :not_found, :formats => :html
  end
  
end
