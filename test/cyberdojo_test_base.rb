
require_relative 'test_coverage'
require_relative 'all'
require 'test/unit'

class CyberDojoTestBase < Test::Unit::TestCase

  def root_path
    root_dir = File.expand_path('..', File.dirname(__FILE__))
    root_dir + '/test/cyberdojo/'
  end

  def setup
    `rm -rf #{root_path}/katas/*`
  end

  def make_kata(dojo, language_name, exercise_name = 'test_Yahtzee')
    language = dojo.languages[language_name]
    exercise = dojo.exercises[exercise_name]
    dojo.katas.create_kata(language, exercise)
  end

  def self.test(name, &block)
    define_method("test_#{name}".to_sym, &block)
  end

end
