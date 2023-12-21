# frozen_string_literal: true

module FFMPEG
  module Metadata
    # Parse a program from ffmpeg output
    class Program
      attr_reader :program, :id, :tags, :video_streams, :audio_streams, :video_stream, :audio_stream

      def initialize(program)
        @program = program

        @id = program[:program_id]
        @tags = program[:tags]

        parse_video_streams
        parse_audio_streams
      end

      protected

      def parse_video_streams
        video_streams = streams_for_type('video')

        @video_streams = video_streams.map do |stream|
          FFMPEG::Metadata::VideoStream.new(stream)
        end

        @video_stream = @video_streams.find { |s| s.default == true } || @video_streams.first
      end

      def parse_audio_streams
        audio_streams = streams_for_type('audio')

        @audio_streams = audio_streams.map do |stream|
          FFMPEG::Metadata::AudioStream.new(stream)
        end

        @audio_stream = @audio_streams.find { |s| s.default == true } || @audio_streams.first
      end

      def streams_for_type(type)
        streams = @program[:streams]

        streams.select { |stream| stream.key?(:codec_type) and stream[:codec_type] == type }
      end
    end
  end
end
