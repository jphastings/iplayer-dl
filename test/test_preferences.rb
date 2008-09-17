$:.unshift( File.join( File.dirname(__FILE__), '..', 'lib' ))
require 'test/unit'
require 'mocha'
require 'iplayer/preferences'

class PreferencesTestWithDefaults < Test::Unit::TestCase

  def setup
    File.stubs(:read).returns('')
  end

  def test_should_start_with_sensible_default_type_preference
    prefs = IPlayer::Preferences.new

    assert_equal ['original', 'signed'], prefs.type_preference
  end

  def test_should_use_current_working_directory_for_download_path
    prefs = IPlayer::Preferences.new

    assert_equal Dir.pwd, prefs.download_path
  end

  def test_should_not_use_subdirectories_by_default
    prefs = IPlayer::Preferences.new

    assert !prefs.subdirs
  end

  def test_should_use_nil_http_proxy_when_unspecified_in_environment
    env = ENV.to_hash.merge('http_proxy' => nil)
    prefs = IPlayer::Preferences.new(env)

    assert_nil prefs.http_proxy
  end
    
  def test_should_use_current_http_proxy_environment_variable
    env = ENV.to_hash.merge('http_proxy' => 'localhost:9999')
    prefs = IPlayer::Preferences.new(env)

    assert_equal 'localhost:9999', prefs.http_proxy
  end

  def test_should_override_defaults_via_assignment
    prefs = IPlayer::Preferences.new
    prefs.http_proxy = 'localhost:3128'
    assert_equal 'localhost:3128', prefs.http_proxy
  end

  def test_should_reset_defaults
    prefs = IPlayer::Preferences.new
    prefs.type_preferences = ['foo', 'bar']
    prefs.reset_defaults
    assert_equal ['original', 'signed'], prefs.type_preference
  end

end

class PreferencesTestWhenLoading < Test::Unit::TestCase

  def test_should_read_from_dotfile_in_home_directory_on_posix_platforms
    env = {'HOME' => '/home/peter'}
    File.stubs(:exist?).returns(true)
    File.expects(:read).with('/home/peter/.iplayer-dl').returns('')
    prefs = IPlayer::Preferences.new(env, 'lunix')
  end

  def test_should_read_from_preference_file_in_appdata_directory_on_windows
    env = {'APPDATA' => 'C:\Documents and Settings\Peter\Application Data'}
    File.stubs(:exist?).returns(true)
    File.expects(:read).with('C:\Documents and Settings\Peter\Application Data/iplayer-dl').returns('') # Looks weird, but paths work this way
    prefs = IPlayer::Preferences.new(env, 'i386-mswin32')
  end

  def test_should_override_defaults_from_yaml_in_file
    file_contents = {
      'type_preference' => %w[foo bar],
      'download_path'   => '/nowhere',
      'http_proxy'      => 'localhost:3128',
      'subdirs'         => true
    }.to_yaml
    File.stubs(:exist?).returns(true)
    File.stubs(:read).returns(file_contents)
    env = {'HOME' => '/home/peter'}
    prefs = IPlayer::Preferences.new(env, 'lunix')
    assert_equal ['foo', 'bar'],   prefs.type_preference
    assert_equal '/nowhere',       prefs.download_path
    assert_equal 'localhost:3128', prefs.http_proxy
    assert prefs.subdirs
  end

  def test_should_ignore_when_preferences_file_does_not_exist
    env = {'HOME' => '/tmp'}
    assert_nothing_raised do
      IPlayer::Preferences.new(env, 'lunix')
    end
  end
end

