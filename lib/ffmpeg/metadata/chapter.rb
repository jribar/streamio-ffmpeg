# frozen_string_literal: true

module FFMPEG
  module Metadata
    # Parse a video stream from ffmpeg output
    class Chapter
      attr_reader :index, :title, :timebase, :start, :start_time, :end, :end_time, :tags

      def initialize(chapter)
        @chapter = chapter

        @index = chapter[:id]
        @title = chapter[:tags][:title]
        @timebase = Rational(chapter[:time_base])
        @start = chapter[:start]
        @start_time = chapter[:start_time].to_f
        @end = chapter[:end]
        @end_time = chapter[:end_time].to_f
        @tags = chapter[:tags]
      end
    end
  end
end
