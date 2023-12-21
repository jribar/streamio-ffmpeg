# frozen_string_literal: true

module FFMPEG
  module Metadata
    # Parse an audio stream from ffmpeg output
    class AudioStream
      attr_reader :stream, :index, :default, :channels, :codec_name, :codec_name_long, :sample_rate,
                  :bitrate, :channel_layout, :tags, :overview

      def initialize(stream)
        @stream = stream

        @index = stream[:index]
        @default = stream[:disposition][:default] == '1'

        @channels = stream[:channels].to_i
        @codec_name = stream[:codec_name]
        @codec_name_long = stream[:codec_long_name]
        @sample_rate = stream[:sample_rate].to_i
        @bitrate = stream[:bit_rate].to_i
        @channel_layout = stream[:channel_layout]
        @tags = stream[:streams]
        @overview = "#{stream[:codec_name]} (#{stream[:codec_tag_string]} / #{stream[:codec_tag]}), #{stream[:sample_rate]} Hz, #{stream[:channel_layout]}, #{stream[:sample_fmt]}, #{stream[:bit_rate]} bit/s"
      end

      def [](key)
        send(key)
      end
    end
  end
end
