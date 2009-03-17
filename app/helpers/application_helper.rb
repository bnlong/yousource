#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 August Lilleaas <augustlilleaas@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  include UsersHelper
  include BreadcrumbsHelper
  include EventRenderingHelper
  
  def help_box(&block)
    out = %Q{<div class="help-side-box round-5"><div class="icon"></div>}
    out << capture(&block)
    out << "</div>"
    concat(out, block.binding)
  end
  
  def markdown(text, options = [:smart])
    rd = RDiscount.new(text.to_s, *options)
    rd.to_html
  end
  
  def feed_icon(url, alt_title = "Atom feed", size = :small)
    link_to image_tag("silk/feed.png", :class => "feed_icon"), url,
      :alt => alt_title, :title => alt_title
  end
  
  def default_css_tag_sizes
    %w(tag_size_1 tag_size_2 tag_size_3 tag_size_4)
  end
  
  def linked_tag_list_as_sentence(tags)
    tags.map do |tag|
      link_to(h(tag.name), search_path(:q => "category:#{h(tag.name)}"))
    end.to_sentence
  end
  
  def build_notice_for(object)
    out =  %Q{<div class="being_constructed">}
    out << %Q{  <p>#{I18n.t( "application_helper.notice_for").call(object.class.name.humanize.downcase)}</p>}
    out << %Q{  <p class="spin">#{image_tag("spinner.gif")}</p>}
    out << %Q{</div>}
    out
  end
  
  def render_if_ready(object)
    if object.respond_to?(:ready?) && object.ready?
      yield
    else
      concat(build_notice_for(object))
    end
  end  
  
  def selected_if_current_page(url_options, slack = false)
    if slack
      if controller.request.request_uri.index(CGI.escapeHTML(url_for(url_options))) == 0
        "selected"
      end
    else
      "selected" if current_page?(url_options)
    end
  end
  
  def submenu_selected_class_if_current?(section)
    case section
    when :overview
     if %w[projects].include?(controller.controller_name )
       return "selected"
     end
    when :repositories
      if %w[repositories trees logs commits comitters comments merge_requests 
            blobs committers].include?(controller.controller_name )
        return "selected"
      end
    when :pages
      if %w[pages].include?(controller.controller_name )
        return "selected"
      end
    end
  end
  
  def link_to_with_selected(name, options = {}, html_options = nil)
    html_options = current_page?(options) ? {:class => "selected"} : nil
    link_to(name, options = {}, html_options)
  end
  
  def syntax_themes_css
    out = []
    if @load_syntax_themes
      # %w[ active4d all_hallows_eve amy blackboard brilliance_black brilliance_dull 
      #     cobalt dawn eiffel espresso_libre idle iplastic lazy mac_classic 
      #     magicwb_amiga pastels_on_dark slush_poppies spacecadet sunburst 
      #     twilight zenburnesque 
      # ].each do |syntax|
      #   out << stylesheet_link_tag("syntax_themes/#{syntax}")
      # end
      return stylesheet_link_tag("syntax_themes/idle")
    end
    out.join("\n")
  end
  
  def base_url(full_url)
    URI.parse(full_url).host
  end
  
  def gravatar_url_for(email, options = {})
    "http://www.gravatar.com/avatar.php?gravatar_id=" << 
    (email.nil? ? "" : Digest::MD5.hexdigest(email)) <<
    "&amp;default=" <<
    u("http://#{request.host}:#{request.port}/images/default_face.gif") <<
    options.map { |k,v| "&amp;#{k}=#{v}" }.join
  end
  
  def gravatar(email, options = {})
    size = options[:size]
    image_options = { :alt => "avatar" }
    if size
      image_options.merge!(:width => size, :height => size)
    end
    image_tag(gravatar_url_for(email, options), image_options)
  end
  
  def gravatar_frame(email, options = {})
    extra_css_class = options[:style] ? " gravatar_#{options[:style]}" : ""
    %{<div class="gravatar#{extra_css_class}">#{gravatar(email, options)}</div>}
  end
  
  def flashes
    flash.map do |type, content| 
      content_tag(:div, content_tag(:p, content), :class => "flash_message #{type}")
    end.join("\n")
  end
  
  def commit_graph_tag(repository, ref = "master")
    filename = Gitorious::Graphs::CommitsBuilder.filename(repository, ref)
    if File.exist?(File.join(Gitorious::Graphs::Builder.graph_dir, filename))
      image_tag("graphs/#{filename}")
    end
  end
  
  def commit_graph_by_author_tag(repository, ref = "master")    
    filename = Gitorious::Graphs::CommitsByAuthorBuilder.filename(repository, ref)
    if File.exist?(File.join(Gitorious::Graphs::Builder.graph_dir, filename))
      image_tag("graphs/#{filename}")
    end
  end
  
  def action_and_body_for_event(event)
    target = event.target
    if target.nil?
      return [action, body, category]
    end
    # These are defined in event_rendering_helper.rb:
    self.send("render_event_#{Action::css_class(event.action)}", event)
  end
  
  def link_to_remote_if(condition, name, options)
    if condition
      link_to_remote(name, options)
    else
      content_tag(:span, name)
    end
  end
  
  def sidebar_content?
    !@content_for_sidebar.blank?
  end
  
  def render_readme(repository)
    possibilities = []
    repository.git.git.ls_tree({:name_only => true}, "master").each do |line|
      possibilities << line[0, line.length-1] if line =~ /README.*/
    end
    
    return "" if possibilities.empty?
    text = repository.git.git.show({}, "master:#{possibilities.first}")
    markdown(text) rescue simple_format(sanitize(text))
  end
  
  def file_path(repository, filename, head = "master")
    project_repository_blob_path(repository.project, repository, branch_with_tree(head, filename))
  end
  
  def link_to_help_toggle(dom_id)
    link_to_function(image_tag("help_grey.png", {
      :alt => t("application_helper.more_info")
    }), "$('#{dom_id}').toggle()", :class => "more_info")
  end
  FILE_EXTN_MAPPINGS = {
    '.cpp' => 'cplusplus-file', 
    '.c' => 'c-file',
    '.h' => 'header-file',
    '.java' => 'java-file',
    '.sh' => 'exec-file',
    '.exe'  => 'exec-file',
    '.rb' => 'ruby-file',
    '.png' => 'image-file',
    '.jpg' => 'image-file', 
    '.gif' => 'image-file',
    'jpeg' => 'image-file',
    '.zip' => 'compressed-file',
    '.gz' => 'compressed-file'}
  
  def class_for_filename(filename)
    return FILE_EXTN_MAPPINGS[File.extname(filename)] || 'file'
  end
  
  def render_download_links(project, repository, head, options={})
    links = []
    exceptions = Array(options[:except])
    unless exceptions.include?(:source_tree)
      links << content_tag(:li, link_to("View source tree for #{desplat_path(head)}", 
                  tree_path(head)), :class => "tree")
    end

    head = desplat_path(head) if head.is_a?(Array)
    
    if head =~ /^[a-z0-9]{40}$/ # it looks like a SHA1
      head = head[0..7]
    end
    
    {
      'tar.gz' => 'tar',
      # 'zip' => 'zip',
    }.each do |extension, url_key|
      archive_path = self.send("project_repository_archive_#{url_key}_path", project, repository, head)
      link_html = link_to("Download #{head} as #{extension}", archive_path, 
                                  :onclick => "Gitorious.DownloadChecker.checkURL('#{archive_path}?format=js', 'archive-box-#{head}');return false",
                                  :class => "download-link")
      link_callback_box = content_tag(:div, "", :class => "archive-download-box round-5 shadow-2", 
        :id => "archive-box-#{head}", :style => "display:none;")
      links << content_tag(:li, link_html+link_callback_box, :class => extension.split('.').last)
    end
    
    if options.delete(:only_list_items)
      links.join("\n")
    else
      css_classes = options[:class] || "meta"
      content_tag(:ul, links.join("\n"), :class => "links #{css_classes}")
    end
  end
  
  def paragraphs_with_more(text)
    return if text.blank?
    first, rest = text.split("</p>", 2)
    if rest.blank?
      first + "</p>"
    else
      %Q{#{first} 
        <a href="#more" onclick="$('description-rest').toggle(); this.hide()">more&hellip;</a></p>
        <div id="description-rest" style="display:none;">#{rest}</div>}
    end
  end
  
  def markdown_hint
    t("views.common.format_using_markdown", 
      :markdown => %(<a href="http://daringfireball.net/projects/markdown/">Markdown</a>))
  end
  
  def current_site
    @controller.current_site
  end
end
