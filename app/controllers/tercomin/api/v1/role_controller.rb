class Tercomin::Api::V1::RoleController < TercominBaseController
  before_filter :require_logged

  def index
    @response = {:role => "user" }

    if(is_ingroup(['hr']))
      @response[:role] = "hr"
    end

    if(is_ingroup(['lt-prj-tercomin-pm']))
      @response[:role] = "admin"
    end

    respond_to do |format|
      format.json { render :json => @response}
    end
  end

  private

  def require_logged
    if (!User.current.logged?)
      respond_to do |format|
        format.json { render :json => "User is not logged", status: :unprocessable_entity}
      end
    end
  end

  def is_ingroup(groupNames)
    userGroups = User.current.groups.map{ |o| o.lastname }
    ig = userGroups & groupNames
    return ig.any?
  end
end
