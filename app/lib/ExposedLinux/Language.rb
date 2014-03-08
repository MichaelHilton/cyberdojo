
module ExposedLinux

  class Language

    def initialize(dojo,name)
      @dojo,@name = dojo,name
    end

    attr_reader :dojo, :name

    def visible_files
      Hash[visible_filenames.collect{ |filename|
        [ filename, dir.read(filename) ]
      }]
    end

    def support_filenames
      manifest['support_filenames'] || [ ]
    end

    def highlight_filenames
      manifest['highlight_filenames'] || [ ]
    end

    def unit_test_framework
      manifest['unit_test_framework']
    end

    def tab
      " " * tab_size
    end

    def tab_size
      manifest['tab_size'] || 4
    end

    def visible_filenames
      manifest['visible_filenames'] || [ ]
    end

    def manifest
      @manifest ||= JSON.parse(dir.read('manifest.json'))
    end

    def path
      Languages.new(dojo).path + name + '/'
    end

  private

    def dir
      dojo.paas.disk[path]
    end
    
  end

end