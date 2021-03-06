class Tercomin::Api::V1::LocaleController < TercominBaseController
  before_filter :require_tercomin_pm, :only => [:index]
  accept_api_auth :index #api is disabled by admins ))

  def index
    respond_to do |format|
      format.json { render :json => "put locales here. TBD"}
    end
  end

  private  

  def is_ingroup(groupNames)
    userGroups = User.current.groups.map{ |o| o.lastname }    
    ig = userGroups & groupNames
    return ig.any?
  end

  def require_tercomin_pm        
    return unless require_login #401
    if !is_ingroup(['lt-prj-tercomin-pm'])
      render_403
      return false
    end
    true
  end

end