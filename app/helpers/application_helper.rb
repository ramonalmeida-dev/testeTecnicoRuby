module ApplicationHelper
  def user_avatar(user, size: 32)
    if user && user.name.present?
      initials = user.name.split(' ').map(&:first).join('').upcase[0,2]
      content_tag :div, initials, 
        style: "
          width: #{size}px; 
          height: #{size}px; 
          border-radius: 50%; 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white; 
          display: inline-flex; 
          align-items: center; 
          justify-content: center; 
          font-weight: bold; 
          font-size: #{size/2.5}px;
          margin-right: 8px;
          vertical-align: middle;
        "
    else
      content_tag :div, "?", 
        style: "
          width: #{size}px; 
          height: #{size}px; 
          border-radius: 50%; 
          background: #ccc;
          color: white; 
          display: inline-flex; 
          align-items: center; 
          justify-content: center; 
          font-weight: bold; 
          font-size: #{size/2.5}px;
          margin-right: 8px;
          vertical-align: middle;
        "
    end
  end

  def user_with_avatar(user, show_name: true)
    return content_tag(:span, "Não atribuído", style: "color: #999;") unless user
    
    avatar = user_avatar(user)
    name = show_name ? user.name : ""
    
    content_tag :div, style: "display: flex; align-items: center;" do
      avatar + content_tag(:span, name)
    end
  end
end
