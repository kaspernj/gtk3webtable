#encoding: utf-8

class Gtk3webtable
  def initialize(args = {})
    @ui = Gtk3assist::Builder.new.add_from_file("#{File.dirname(__FILE__)}/win_main.glade")
    @ui.connect_signals{|h| method(h)}
    
    @wview = WebKit::WebView.new
    @wview.signal_connect("title-changed", &self.method(:on_webview_title_changed))
    @wview.signal_connect("console-message", &self.method(:on_webview_console_message))
    
    #Enable loading of local files (used for jQuery).
    @wview.settings.set_property("enable-file-access-from-file-uris", true)
    
    @ui["scrolledwindow"].add(@wview)
    
    
    #Make up CSS for the body-element in the WebView from the current windows Gtk-style.
    ex_win = @ui["window"]
    ex_win_sc = ex_win.style_context
    
    @body_css = {
      "background-color" => convert_gdk_color_to_hex(ex_win_sc.background_color(Gtk::StateFlags[:normal])),
      "color" => convert_gdk_color_to_hex(ex_win_sc.color(Gtk::StateFlags[:normal])),
      "font-family" => ex_win_sc.font(Gtk::StateFlags[:normal]).get_family,
      "font-size" => "#{ex_win_sc.font(Gtk::StateFlags[:normal]).get_size / 1024}pt"
    }
    
    
    #Load content for the WebView.
    self.reload_table
    
    #Show the window.
    @ui["window"].show_all
  end
  
  def convert_gdk_color_to_hex(gdk_color)
    return "#{(gdk_color.red * 255).to_i.to_s(16)}#{(gdk_color.blue * 255).to_i.to_s(16)}#{(gdk_color.green * 255).to_i.to_s(16)}"
  end
  
  def on_webview_console_message(*args)
    Gtk3assist::Msgbox.new(:type => :warning, :msg => args[1])
    puts "Console msg: #{args}"
  end
  
  def on_webview_title_changed(*args)
    new_title = args[2]
    return false if new_title == "" or new_title == "undefined"
    data = JSON.parse(new_title)
    
    if data["args"]
      call_args = data["args"]
    else
      call_args = []
    end
    
    self.__send__(data["callback"], *call_args)
    return false
  end
  
  def on_col_clicked(str)
    Gtk3assist::Msgbox.new(:msg => "Callback from JavaScript. Clicked on TD with content: '#{str.strip}'.")
  end
  
  def on_testbutton_clicked
    Gtk3assist::Msgbox.new(:msg => "Another callback from JavaScript. This time by pressing the 'Test button'.")
  end
  
  def reload_table
    html = Html_gen::Element.new(:html)
    
    head = html.add(:head)
    
    head.add(:link, {
      :attr => {
        "rel" => "stylesheet",
        "type" => "text/css",
        "href" => "file://#{File.realpath("#{File.dirname(__FILE__)}/../css")}/default.css"
      }
    })
    
    head.add(:script, {
      :attr => {
        "type" => "text/javascript",
        "src" => "file://#{File.realpath("#{File.dirname(__FILE__)}/../js")}/jquery-1.8.1.min.js"
      }
    })
    
    head.add(:script, {
      :attr => {
        "type" => "text/javascript",
        "src" => "file://#{File.realpath("#{File.dirname(__FILE__)}/../js")}/json/json2.js"
      }
    })
    
    head.add(:script, {
      :attr => {"type" => "text/javascript"},
      :str_html => "
        function remove_row(row_ele){
          $('div, span', row_ele).slideUp('fast', function(){
            row_ele.remove()
          })
        }
        
        function webview_callback(args){
          document.title = ''
          new_title = JSON.stringify(args)
          document.title = new_title
        }
      "
    })
    
    
    body = html.add(:body, :css => @body_css)
    table = body.add(:table, :css => {"width" => "100%"})
    thead = table.add(:thead)
    thead.add(:th, :str => "First name")
    thead.add(:th, :str => "Last name")
    thead.add(:th, :str => "Age")
    thead.add(:th, :str => "Actions")
    
    tbody = table.add(:tbody)
    
    persons = [
      ["Kasper", "Johansen", "27"],
      ["Jacob", "Emcken", "29"],
      ["Christina", "Stöckel", "25"]
    ]
    
    persons.each do |person|
      tr = tbody.add(:tr)
      
      person.each do |data|
        td = tr.add(:td, :css => @body_css).add(:span, {
          :str => data,
          :css => {
            "cursor" => "pointer"
          },
          :attr => {
            "onclick" => "document.title = webview_callback({'callback': 'on_col_clicked', 'args': [$(this).text()]})"
          }
        })
      end
      
      add = tr.add(:td).add(:span).add(:a, {
        :str => "[remove]",
        :css => {
          "cursor" => "pointer"
        },
        :attr => {
          "onclick" => "remove_row($(this).parent().parent().parent())"
        }
      })
    end
    
    div_buttons = body.add(:div, :css => {"text-align" => "right"})
    button = div_buttons.add(:input, {
      :attr => {
        "type" => "button",
        "value" => "Test button",
        "onclick" => "document.title = webview_callback({'callback': 'on_testbutton_clicked'})"
      }
    })
    
    div_text = body.add(:div, :str => "This is some text")
    html_str = html.html
    
    print "Reload table HTML:\n"
    print html_str
    print "\n\n"
    
    @wview.load_string(html_str, "text/html", "utf-8", "file://")
  end
  
  def on_window_destroy
    Gtk.main_quit
  end
end