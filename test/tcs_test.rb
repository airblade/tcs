gem 'minitest'
require 'minitest/autorun'

class TcsTest < Minitest::Test

  SETUP = system <<~END
    cd #{File.expand_path('..', __dir__)} && \
    npx tailwindcss \
      -c ./test/tailwind.config.js \
      -i ./test/input.css \
      -o ./test/output.css
  END

  def setup
    @tcs = root_file 'tcs'
    @css = test_file 'output.css'
  end

  def test_too_few_args
    _, err = capture_subprocess_io do
      refute system(@tcs)
    end
    assert_match /Usage/, err
  end

  def test_too_many_args
    _, err = capture_subprocess_io do
      refute system("#{@tcs} foo bar baz")
    end
    assert_match /Usage/, err
  end

  # Most of the fixtures come from here:
  # https://tailwindcss.com/blog/automatic-class-sorting-with-prettier#how-classes-are-sorted
  def test_sorting
    source_html_files.each do |filename|
      name = File.basename filename, '.html'
      success = nil
      out, err = capture_subprocess_io do
        success = system("#{@tcs} #{@css} < #{input_html name}")
      end
      puts "#{name}:\n#{err}" if !success

      assert_equal File.read(expected_html(name)), out, name
    end
  end


  private

  def source_html_files
    fixture_files.reject { |filename| filename.include? 'expected' }
  end

  def fixture_files
    Dir.glob('./fixtures/*.html', base: __dir__)
  end

  def input_html(name)
    fixture_file "#{name}.html"
  end

  def expected_html(name)
    fixture_file "#{name}.expected.html"
  end

  def fixture_file(name)
    File.expand_path "../fixtures/#{name}", __FILE__
  end

  def test_file(name)
    File.expand_path "../#{name}", __FILE__
  end

  def root_file(name)
    File.expand_path "../../#{name}", __FILE__
  end
end
