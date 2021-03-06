require 'zip' #ms word generation
require 'nokogiri' #ms word generation

class TercominController < TercominBaseController  
	before_filter :find_user_profile, :only => [:cv, :avatar, :thumb]
  before_filter :has_full_access, :only => :cv

  before_filter :find_project, :only => [:avatar, :thumb]
  before_filter :find_avatar, :only => [:avatar, :thumb]
  before_filter :file_readable, :only => [:avatar, :thumb]

  def index   
  	@themeName = "default"
  	if User.current.logged?
      @currentUserId = User.current.id
  		profile = UserProfile.find_by_user_id(User.current.id)
  		if UserProfile.exists?(profile)
  			if profile.settings.present?
		        settings = JSON.parse(profile.settings)		        
	  				@themeName = settings["theme"]	  			
		    end
  		end
  	end
  end

  def cv
    if @has_full_access
      result_file_name = "#{@user.lastname}_#{@user.firstname}.docx"
      @user_profile = UserProfile.find_or_create_by(:user_id => params[:id])      
      filename = template_tag("cv.docx", :plugin => 'tercomin')
      zf = Zip::File.new(filename)    

      if @user_profile.respond_to? :data
        begin
          pd = JSON.parse(@user_profile.data)
        rescue  
          puts 'parse profile error'  
        end  
        begin
          positions = JSON.parse(@user_profile.positions)
        rescue  
          puts 'parse positions error'  
        end  
        begin
          background = JSON.parse(@user_profile.backgrounds)
        rescue  
          puts 'parse background error'  
        end  
        buffer = Zip::OutputStream.write_buffer do |out|
          zf.entries.each do |e|    
            if e.ftype == :directory
              out.put_next_entry(e.name)          
            else          
              out.put_next_entry(e.name)
              if (e.name == DOCUMENT_FILE_PATH)             
                tmp = e.get_input_stream.read
                doc = Nokogiri::XML(tmp)
                node = doc.at('//w:t[contains(., "Professional experience")]')
                tableNode = node.parent.parent.next_element
                tableRowsNodes = tableNode.xpath('.//w:tr')
                
                if positions && !positions.empty?                
                  tableRowsNodes.remove
                  positions.each do |i|                  
                    for j in tableRowsNodes do
                      row = j.clone
                      replaceNodeContent(row, "[Work_From_Year]", i['from'])
                      replaceNodeContent(row, "[Work_To_Year]", i['to'])
                      replaceNodeContent(row, "[Work_Name]", i['companyName'])
                      replaceNodeContent(row, "[Work_Project]", i['project'])
                      replaceNodeContent(row, "[Work_Position]", i['position'])
                      replaceNodeContent(row, "[Work_Resp]", i['resp'])
                      replaceNodeContent(row, "[Work_TS]", i['techSummary'])
                      tableNode.add_child(row)
                    end
                  end
                end

                nodeEdu = doc.at('//w:t[contains(., "Educational background")]')
                tableEduNode = nodeEdu.parent.parent.next_element
                tableEduRowsNodes = tableEduNode.xpath('.//w:tr')
                
                if background && !background.empty?
                  tableEduRowsNodes.remove
                  background.each do |i|                  
                    for j in tableEduRowsNodes do
                      row = j.clone
                      replaceNodeContent(row, "[EDU_From_Year]", i['from'])
                      replaceNodeContent(row, "[EDU_To_Year]", i['to'])                    
                      replaceNodeContent(row, "[EDU_Summary]", i['name'])
                      tableEduNode.add_child(row)
                    end
                  end
                end

                doc = doc.inner_html
                doc = doc.gsub("[Firstname]", @user.firstname)   
                doc = doc.gsub("[Lastname]", @user.lastname)
                doc = doc.gsub("[Position]", pd['position']) if pd['position'].present?
                if pd
                  if pd['summary'].present?
                    tmp = Nokogiri::HTML(pd['summary'].gsub(/>\s+</, "><"))                
                    doc = doc.force_encoding("UTF-8").gsub("[Summary]", tmp.xpath("//text()").to_s)
                  end
                  if pd['skills'].present?
                    tmp = Nokogiri::HTML(pd['skills'].gsub(/>\s+</, "><"))                
                    doc = doc.force_encoding("UTF-8").gsub("[Skills]", tmp.xpath("//text()").to_s)
                  end

                  if pd['coureses'].present?
                    tmp = Nokogiri::HTML(pd['coureses'].gsub(/>\s+</, "><"))                
                    doc = doc.force_encoding("UTF-8").gsub("[Certificates]", tmp.xpath("//text()").to_s)
                  end
                  if pd['english_lvl'].present?                  
                    tmp = Nokogiri::HTML(pd['english_lvl'].gsub(/>\s+</, "><"))                
                    doc = doc.force_encoding("UTF-8").gsub("[EnglishLVL]", tmp.xpath("//text()").to_s)
                  end
                  if pd['extra_languages'].present?                  
                    tmp = Nokogiri::HTML(pd['extra_languages'].gsub(/>\s+</, "><"))                
                    doc = doc.force_encoding("UTF-8").gsub("[Languages_Extra]", tmp.xpath("//text()").to_s)
                  end
                end

                out.write doc        
              else
                out.write e.get_input_stream.read
              end      
            end
          end
        end
      end  
      buffer.rewind
      send_data( buffer.sysread, :filename => result_file_name )
    else
      render_403
    end
  end

  def avatar
    if stale?(:etag => @attachment.digest)
      send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
                                      :type => detect_content_type(@attachment),
                                      :disposition => (@attachment.image? ? 'inline' : 'attachment')
    end
  end

  def thumb
    if @attachment.thumbnailable? && thumbnail = @attachment.thumbnail(:size => params[:size])
      if stale?(:etag => thumbnail)
        send_file thumbnail,
          :filename => filename_for_content_disposition(@attachment.filename),
          :type => detect_content_type(@attachment),
          :disposition => 'inline'
      end
    else
      render :nothing => true, :status => 404
    end
  end

  private
  DOCUMENT_FILE_PATH = "word/document.xml"

  def find_user_profile
    @user = User.find_by_id(params[:id])          
    raise ActiveRecord::RecordNotFound if params[:id] && @user.nil? && params[:id] != @user.id
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = Project.find_by_identifier("tercomin")
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_avatar
    if @attachment = @project.attachments.find_by_description("#{@user.login} image")
    else
      @attachment = @project.attachments.find_by_description("anonymous image")
    end
    raise ActiveRecord::RecordNotFound if @attachment.blank?
  end

  def file_readable
    if @attachment.readable?
      true
    else
      render_404
    end
  end

  def detect_content_type(attachment)
    content_type = attachment.content_type
    if content_type.blank?
      content_type = Redmine::MimeType.of(attachment.filename)
    end
    content_type.to_s
  end

  def is_in_system_group    
    if !User.current.logged?
      return false
    end
    currentGroups = User.current.groups.map{ |o| o.lastname }
    ig = currentGroups & ['hr', 'lt-prj-tercomin-pm', 'lt-prj-tercom-website-pm']    
    return ig.any?
  end

  def has_full_access
    @has_full_access = false
    if (params[:id] == "logged" || User.current.id == params[:id].to_i || is_in_system_group())
      @has_full_access = true;        
    else      
      e = Event.last
      if e.present?
        groups = JSON.parse(e.groups)
        for i in groups          
          if i['m'].keys().include?(User.current.id.to_s)            
            if i['e'].keys().include?(params[:id])              
              @has_full_access = true;
            end
          end          
        end        
      end      
    end
  end

  def template_tag(source, options={})
    if plugin = options.delete(:plugin)      
      source = "#{Rails.root}/public/plugin_assets/#{plugin}/reporting/#{source}"    
    end
    return source
  end

  def replaceNodeContent(node, content, newcontent)
    criteria = './/w:t[contains(., "%s")]' % content
    item =node.at(criteria)
    item.content = item.content.gsub("#{content}", "#{newcontent}") if item
  end
end
