require "../lib/sufia/export/generic_file.rb"

module Export
  class Service
    # Exports each GenericFile ID to a JSON file in the specified path
    # Each JSON file is named gw_###.json (where ### is the Generic File's ID)
    def self.export(ids, path)
      ids.each do |id|
        file_name = File.join(path, "gf_#{id}.json")
        export_one_to_file(id, file_name)
      end
    end

    def self.export_all(_path)
      # TODO
    end

    def self.export_one_to_file(id, file_name)
      gf = ::GenericFile.find(id)
      json = Export::GenericFile.new(gf).to_json(true)
      File.write(file_name, json)
    end
  end
end
