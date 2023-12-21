# frozen_string_literal: true

module FFMPEG
  module Metadata
    # Parse a video stream from ffmpeg output
    class VideoStream
      attr_reader :stream, :index, :default, :codec_name, :codec_name_long, :pixel_format, :color_space,
                  :bitrate, :sar, :dar, :frame_rate, :profile,
                  :level, :tags, :side_data_list, :overview

      def initialize(stream)
        @stream = stream

        @index = stream[:index]
        @default = stream[:disposition][:default] == '1'

        @codec_name = stream[:codec_name]
        @codec_name_long = stream[:codec_long_name]
        @pixel_format = stream[:pix_fmt]
        @color_space = stream[:color_space]
        @width = stream[:width]
        @height = stream[:height]
        @resolution = "#{@width}x#{@height}"
        @bitrate = stream[:bit_rate].to_i
        @sar = stream[:sample_aspect_ratio]
        @dar = stream[:display_aspect_ratio]
        @frame_rate = stream[:avg_frame_rate] == '0/0' ? nil : Rational(stream[:avg_frame_rate])
        @profile = stream[:profile]
        @level = stream[:level]
        @tags = stream[:tags]
        @side_data_list = stream[:side_data_list]
        @overview = "#{codec_name} (#{profile}) (#{stream[:codec_tag_string]} / #{stream[:codec_tag]}), #{pixel_format}, #{resolution} [SAR #{sar} DAR #{dar}]"
      end

      def width
        return @width if rotation.nil?

        rotation == 180 || rotation.zero? ? @width : @height
      end

      def height
        return @height if rotation.nil?

        rotation == 180 || rotation.zero? ? @height : @width
      end

      def resolution
        return if width.nil? || height.nil?

        "#{width}x#{height}"
      end

      def calculated_aspect_ratio
        aspect_from_dar || aspect_from_dimensions
      end

      def calculated_pixel_aspect_ratio
        aspect_from_sar || 1
      end

      def rotation
        if @tags&.key?(:rotate)
          @tags[:rotate].to_i % 360
        elsif @side_data_list
          rotation_data = @side_data_list.find { |data| data.key?(:rotation) }
          rotation_data ? rotation_data[:rotation].to_i % 360 : nil
        end
      end

      protected

      def aspect_from_dar
        calculate_aspect(dar)
      end

      def aspect_from_sar
        calculate_aspect(sar)
      end

      def calculate_aspect(ratio)
        return nil unless ratio

        w, h = ratio.split(':')
        return nil if w == '0' || h == '0'

        ar = rotation.nil? || (rotation == 180) ? Rational(w.to_f, h.to_f) : Rational(h.to_f, w.to_f)
        ar.to_f
      end

      def aspect_from_dimensions
        return nil unless width && height

        Rational(width.to_f, height.to_f).to_f
      end
    end
  end
end
