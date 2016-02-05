module Export
  class Characterization
    attr_accessor :mime_type, :format_label, :file_size, :last_modified,
                  :original_checksum, :well_formed, :valid, :file_title, :file_author,
                  :page_count, :file_language, :word_count, :character_count, :paragraph_count,
                  :line_count, :table_count, :graphics_count, :byte_order, :compression,
                  :color_space, :profile_name, :profile_version, :orientation, :color_map,
                  :image_producer, :capture_device, :scanning_software, :exif_version,
                  :gps_timestamp, :latitude, :longitude, :character_set, :markup_basis,
                  :markup_language, :bit_depth, :channels, :data_format, :offset, :frame_rate

    # TODO: handle these fields
    # :file_name, :rights_basis, :copyright_basis, :copyright_note, :status_message

    def initialize(gf)
      @mime_type = gf.characterization.mime_type
      @format_label = gf.characterization.format_label
    end
  end
end
