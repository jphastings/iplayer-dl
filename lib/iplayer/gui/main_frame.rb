require 'wx'
require 'iplayer/errors'

module IPlayer
module GUI
class MainFrame < Wx::Frame
  include Wx
  include IPlayer::Errors

  def initialize(app)
    super(nil, -1, "iPandora")

    @app = app

    @pid_label = StaticText.new(self, -1, "Programme ID")
    @pid_field = TextCtrl.new(self, -1, "", DEFAULT_POSITION, Size.new(200,24))
    @download_progress = Gauge.new(self, -1, 1)
    @stop_button = Button.new(self, -1, "Stop")
    evt_button(@stop_button.get_id){ |e| stop_button_clicked(e)   }
    @stop_button.disable
    @download_button = Button.new(self, -1, "Download")
    evt_button(@download_button.get_id){ |e| download_button_clicked(e) }
    @status_bar = StatusBar.new(self, -1)
    set_status_bar(@status_bar)
    @status_bar.set_status_text("Waiting")

    do_layout
  end

  def do_layout
    sizer_main = BoxSizer.new(VERTICAL)
    sizer_buttons = BoxSizer.new(HORIZONTAL)
    sizer_input = BoxSizer.new(HORIZONTAL)
    sizer_input.add(@pid_label, 0, ALL|ALIGN_CENTER_VERTICAL, 4)
    sizer_input.add(@pid_field, 0, ALL|EXPAND|ALIGN_CENTER_VERTICAL, 4)
    sizer_main.add(sizer_input, 0, EXPAND, 0)
    sizer_main.add(@download_progress, 0, ALL|EXPAND, 4)
    sizer_buttons.add(@stop_button, 0, ALL, 4)
    sizer_buttons.add(@download_button, 0, ALL, 4)
    sizer_main.add(sizer_buttons, 0, ALIGN_RIGHT|ALIGN_CENTER_HORIZONTAL, 0)
    self.set_sizer(sizer_main)
    sizer_main.fit(self)
    layout
    centre
  end

  def stop_button_clicked(event)
    @app.stop_download!
    @status_bar.set_status_text("Stopped")
    @download_button.enable
    @stop_button.disable
  end

  def download_button_clicked(event)
    pid = @pid_field.get_value
    if pid.empty?
      message_box('You must specify a programme ID before I can download it.')
      return
    end
    if pid =~ %r!/item/([a-z0-9]{8})!
      pid = $1
    end

    @download_button.disable
    filename = @app.get_default_filename(pid)

    fd = FileDialog.new(nil, 'Save as', '', filename, 'iPlayer Movies (*.mov)|*.mov', FD_SAVE)

    if fd.show_modal == ID_OK
      path = fd.get_path
      @status_bar.set_status_text("Downloading #{File.basename(path)}")
      @download_button.disable
      @stop_button.enable
      begin
        @app.download(pid, path) do |position, max|
          @download_progress.set_range(max)
          @download_progress.set_value(position)
          if position == max
            @status_bar.set_status_text("Completed #{File.basename(path)}")
          end 
        end
      rescue RecognizedError => error
        message_box(error.to_s, :title => 'Error')
      end
      @stop_button.disable
    end
    @download_button.enable
  end

  def message_box(message, options={})
    options = {:title => 'iPandora', :buttons => OK}.merge(options)
    MessageDialog.new(self, message, options[:title], options[:buttons]).show_modal
  end
end
end
end