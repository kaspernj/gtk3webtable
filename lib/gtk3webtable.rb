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
    
    self.reload_table
    @ui["window"].show_all
  end
  
  def on_webview_console_message(*args)
    Gtk3assist::Msgbox.new(:type => :warning, :msg => args[1])
    puts "Console msg: #{args}"
  end
  
  def on_webview_title_changed(*args)
    str = args[2].to_s
    Gtk3assist::Msgbox.new(:msg => "Callback from JavaScript. Clicked on TD with content: '#{str}'.")
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
    
    script = head.add(:script, {
      :attr => {"type" => "text/javascript"},
      :str => "
        function remove_row(row_ele){
          $('div, span', row_ele).slideUp('fast', function(){
            row_ele.remove()
          })
        }
      "
    })
    
    
    body = html.add(:body)
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
        td = tr.add(:td).add(:span, {
          :str => data,
          :css => {
            "cursor" => "pointer"
          },
          :attr => {
            "onclick" => "document.title = $(this).text()"
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