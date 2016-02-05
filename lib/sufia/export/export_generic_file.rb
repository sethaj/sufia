require "../lib/sufia/export/export_characterization.rb"

module Export
  class GenericFile
    # Properties to be exported
    attr_accessor :id, :label, :depositor, :arkivo_checksum, :relative_path,
      :import_url, :part_of, :resource_type, :title, :creator, :contributor,
      :description, :tag, :rights, :publisher, :date_created, :date_uploaded,
      :date_modified, :subject, :language, :identifier, :based_near,
      :related_url, :bibliographic_citation, :source
      :_source_uri
    attr_accessor :characterization

    # The content is fetched from Sufia 7 at the time the GenericFile is imported
    # contains "content", class_name: 'FileContentDatastream'

    # We probably don't need to worry about this
    # if we let Sufia 7 re-characterize the file and re-generate derivatives
    #
    # contains 'full_text'
    # contains "thumbnail"
    #

    # TODO: belongs_to :batch

    def initialize(gf)
      @id = gf.id
      @label = gf.label
      @depositor = gf.depositor
      @arkivo_checksum = gf.arkivo_checksum
      @relative_path = gf.relative_path
      @import_url = gf.import_url
      @part_of = gf.part_of
      @resource_type = gf.resource_type
      @title = gf.title
      @creator = gf.creator
      @contributor = gf.contributor
      @description = gf.contributor
      @tag = gf.tag
      @rights = gf.rights
      @publisher = gf.publisher
      @date_created = gf.date_created
      @date_uploaded = gf.date_uploaded
      @date_modified = gf.date_modified
      @subject = gf.subject
      @language = gf.language
      @identifier = gf.identifier
      @based_near = gf.based_near
      @related_url = gf.related_url
      @bibliographic_citation = gf.bibliographic_citation
      @source = gf.source
      @characterization = Export::Characterization.new(gf)
    end
  end
end