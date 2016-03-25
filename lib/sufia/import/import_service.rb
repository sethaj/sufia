module Importer
  class ImportService
    def initialize(sufia6_user, sufia6_password, sufia6_root_uri, preserve_ids)
      @sufia6_user = sufia6_user
      @sufia6_password = sufia6_password
      @sufia6_root_uri = sufia6_root_uri
      @preserve_ids = preserve_ids
    end

    def import_files(files_pattern)
      files = Dir.glob(files_pattern)
      Rails.logger.debug "[IMPORT] Processing #{files.count} files from #{files_pattern}..."
      files.each do |file_name|
        import_file(file_name)
      end
    end

    def import_file(file_name)
      json = File.read(file_name)
      generic_file = JSON.parse(json, object_class: OpenStruct)
      generic_work = work_from_gf(generic_file)
      Rails.logger.debug "[IMPORT] File #{File.basename(file_name)} imported as work #{generic_work.id}"
    end

    private

      def work_from_gf(gf)

        # File Set
        # TODO: missing properties
        fs = FileSet.new
        # fs.mime_type = gf.characterization.mime_type
        # fs.format_label = gf.characterization.format_label
        fs.title << gf.title
        fs.date_uploaded = gf.date_uploaded
        fs.date_modified = gf.date_modified
        fs.apply_depositor_metadata(gf.depositor)
        fs.save!

        fs.permissions = permissions_from_gf(fs.id, gf.permissions)
        fs.save!

        # # File
        # file = sufia6_content(gf.id)
        # Hydra::Works::UploadFileToFileSet.call(fs, file)

        # Generic Work
        gw = GenericWork.new
        gw.id = gf.id if @preserve_ids
        gw.apply_depositor_metadata(gf.depositor)
        gw.label                  = gf.label
        gw.arkivo_checksum        = gf.arkivo_checksum
        gw.relative_path          = gf.relative_path
        gw.import_url             = gf.import_url
        gw.part_of                = gf.part_of
        gw.resource_type          = gf.resource_type
        gw.title                  = gf.title
        gw.creator                = gf.creator
        gw.contributor            = gf.contributor
        gw.description            = gf.description
        gw.tag                    = gf.tag
        gw.rights                 = gf.rights
        gw.publisher              = gf.publisher
        gw.date_created           = gf.date_created
        # gw.date_uploaded          = gf.date_uploaded ???
        # gw.date_modified          = gf.date_modified ???
        gw.subject                = gf.subject
        gw.language               = gf.language
        gw.identifier             = gf.identifier
        gw.based_near             = gf.based_near
        gw.related_url            = gf.related_url
        gw.bibliographic_citation = gf.bibliographic_citation
        gw.source                 = gf.source

        gw.ordered_members << fs

        gw.save!
        puts "Generic Work #{gw.id}"

        gw.permissions = permissions_from_gf(gw.id, gf.permissions)
        gw.save!

        gw
      end

      def permissions_from_gf(id, gf_perms)
        permissions = []
        gf_perms.each do |gf_perm|
          permissions << permission(id, gf_perm)
        end
        permissions
      end

      def permission(gw_id, gf_perm)
        agent = gf_perm.agent.split("/").last
        type = agent.split("#").first
        name = agent.split("#").last
        access = gf_perm.mode.split("#").last.downcase
        access = "edit" if access == "write"
        Hydra::AccessControls::Permission.new(id: gw_id, name: name, type: type, access: access)
      end

      def sufia6_content(id)
        content_uri = "#{@sufia6_root_uri}/#{ActiveFedora::Noid.treeify(id)}/content"
        file = open(content_uri, http_basic_authentication: [@sufia6_user, @sufia6_password])
        file
      end
  end
end
