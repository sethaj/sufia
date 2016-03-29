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
      generic_work = import_generic_file(generic_file)
      Rails.logger.debug "[IMPORT] File #{File.basename(file_name)} imported as work #{generic_work.id}"
    end

    private

      def import_generic_file(gf)

        # File Set
        fs = FileSet.new
        fs.title << gf.title
        fs.filename = gf.filename
        fs.label = gf.label
        fs.date_uploaded = gf.date_uploaded
        fs.date_modified = gf.date_modified
        fs.apply_depositor_metadata(gf.depositor)
        fs.save!

        fs.permissions = permissions_from_gf(fs.id, gf.permissions)
        fs.save!

        # File
        import_old_versions(gf, fs)
        import_current_version(gf, fs)

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

        byebug
        # TODO: set generic work thumbnail (shouldn't this happen automatically in create derivatives)

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
        agent = gf_perm.agent.split("/").last           # e.g. "http://projecthydra.org/ns/auth/person#hjc14"
        type = agent.split("#").first                   # e.g. person or group
        name = agent.split("#").last
        access = gf_perm.mode.split("#").last.downcase  # e.g. "http://www.w3.org/ns/auth/acl#Write"
        access = "edit" if access == "write"
        Hydra::AccessControls::Permission.new(id: gw_id, name: name, type: type, access: access)
      end

      def sufia6_content_open_uri(id)
        content_uri = "#{@sufia6_root_uri}/#{ActiveFedora::Noid.treeify(id)}/content"
        file = open(content_uri, http_basic_authentication: [@sufia6_user, @sufia6_password])
        file
      end

      def sufia6_version_open_uri(id, label)
        content_uri = "#{@sufia6_root_uri}/#{ActiveFedora::Noid.treeify(id)}/content/fcr:versions/#{label}"
        file = open(content_uri, http_basic_authentication: [@sufia6_user, @sufia6_password])
        file
      end

      def import_current_version(gf, fs)
        # Download the current version to disk...
        filename_on_disk = "/Users/hjc14/dev/friday25/sufia/.internal_test_app/#{fs.label}"
        puts "Downloading #{filename_on_disk}"
        File.open(filename_on_disk, 'wb') do |file_to_upload|
          source_uri = sufia6_content_open_uri(gf.id)
          file_to_upload.write source_uri.read
        end

        # ...upload it...
        File.open(filename_on_disk, 'rb') do |file_to_upload|
          Hydra::Works::UploadFileToFileSet.call(fs, file_to_upload)
        end

        # ...and characterize it.
        byebug
        CharacterizeJob.perform_later(fs.id, filename_on_disk)
        CreateDerivativesJob.perform_later(fs.id, filename_on_disk)

        # byebug
        # ingest = IngestFileJob.new
        # user_key = "hjc14@psu.edu"
        # mime_type = nil
        # ingest.perform(fs.id, filename_on_disk, mime_type, user_key, relation = 'original_file')
      end

      def import_old_versions(gf, fs)
        return if gf.versions.count <= 1
        # Upload all versions before the current version
        # (notice that we don't characterize these versions)
        versions = gf.versions.sort_by { |version| version.created }
        versions.pop
        versions.each do |version|
          source_uri = sufia6_version_open_uri(gf.id, version.label)
          Hydra::Works::UploadFileToFileSet.call(fs, source_uri)
          user = User.find_by_email("#{gf.depositor}@psu.edu")  # TODO: create user ahead of time???
          relation = "original_file"
          CurationConcerns::VersioningService.create(fs.send(relation.to_sym), user)
        end
      end

  end
end
