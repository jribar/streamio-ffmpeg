# frozen_string_literal: true

require 'time'
require 'multi_json'
require 'uri'
require 'net/http'

module FFMPEG
  # Represents a movie to be processed by ffmpeg
  class Movie
    attr_reader :path, :duration, :time, :bitrate, :size, :creation_time,
                :video_streams, :video_stream,
                :audio_streams, :audio_stream,
                :programs, :chapters, :program_count, :stream_count,
                :container, :container_long_name, :metadata, :format_tags

    UNSUPPORTED_CODEC_PATTERN = /^Unsupported codec with id (\d+) for input stream (\d+)$/.freeze

    def initialize(path, no_verify: false) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      @path = path

      if remote?
        if no_verify == false
          @head = head
          raise Errno::ENOENT, "the URL '#{path}' does not exist or is not available (response code: #{@head.code})" unless @head.is_a?(Net::HTTPSuccess)
        end
      else
        raise Errno::ENOENT, "the file '#{path}' does not exist" unless File.exist?(path)
      end

      # ffmpeg will output to stderr
      command = [FFMPEG.ffprobe_binary, '-i', @path, '-print_format', 'json', '-show_format', '-show_programs', '-show_streams', '-show_error']
      std_output, std_error = capture3(*command)

      fix_encoding(std_output)
      fix_encoding(std_error)

      begin
        @metadata = MultiJson.load(std_output, symbolize_keys: true)
      rescue MultiJson::ParseError
        raise "Could not parse output from FFProbe:\n#{std_output}"
      end

      parse_format

      unless @metadata.key?(:error)
        parse_programs
        parse_video_streams
        parse_audio_streams
      end

      unsupported_stream_ids = unsupported_streams(std_error)
      nil_or_unsupported = ->(stream) { stream.nil? || unsupported_stream_ids.include?(stream.index) }

      @invalid = true if nil_or_unsupported.call(@video_stream) && nil_or_unsupported.call(@audio_stream)
      @invalid = true if @metadata.key?(:error)
      @invalid = true if std_error.include?('could not find codec parameters')
    end

    def unsupported_streams(std_error)
      [].tap do |stream_indices|
        std_error.each_line do |line|
          match = line.match(UNSUPPORTED_CODEC_PATTERN)
          stream_indices << match[2].to_i if match
        end
      end
    end

    def valid?
      !@invalid
    end

    def remote?
      @path =~ URI::DEFAULT_PARSER.make_regexp(%w[http https])
    end

    def local?
      !remote?
    end

    def transcode(output_file, options = EncodingOptions.new, transcoder_options = {}, &block)
      Transcoder.new(self, output_file, options, transcoder_options).run(&block)
    end

    def screenshot(output_file, options = EncodingOptions.new, transcoder_options = {}, &block)
      Transcoder.new(self, output_file, options.merge(screenshot: true), transcoder_options).run(&block)
    end

    def video_codec
      @video_stream&.codec_name
    end

    def pixel_format
      @video_stream&.pixel_format
    end

    def colorspace
      @video_stream&.color_space
    end

    def width
      @video_stream&.width
    end

    def height
      @video_stream&.height
    end

    def resolution
      @video_stream&.resolution
    end

    def video_bitrate
      @video_stream&.bitrate
    end

    def sar
      @video_stream&.sar
    end

    def dar
      @video_stream&.dar
    end

    def calculated_aspect_ratio
      @video_stream&.calculated_aspect_ratio
    end

    def calculated_pixel_aspect_ratio
      @video_stream&.calculated_pixel_aspect_ratio
    end

    def frame_rate
      @video_stream&.frame_rate
    end

    def rotation
      @video_stream&.rotation
    end

    def audio_channels
      @audio_stream&.channels
    end

    def audio_codec
      @audio_stream&.codec_name
    end

    def audio_sample_rate
      @audio_stream&.sample_rate
    end

    def audio_bitrate
      @audio_stream&.bitrate
    end

    def audio_tags
      @audio_stream&.tags
    end

    def audio_channel_layout
      @audio_stream&.channel_layout
    end

    protected

    def parse_format
      if @metadata.key?(:error)
        @duration = 0
      else
        @container = @metadata[:format][:format_name]
        @container_long_name = @metadata[:format][:format_long_name]
        @size = @metadata[:format][:size].to_i
        @duration = @metadata[:format][:duration].to_f
        @time = @metadata[:format][:start_time].to_f
        @format_tags = @metadata[:format][:tags]
        @bitrate = @metadata[:format][:bit_rate].to_i
        @program_count = @metadata[:format][:nb_programs].to_i
        @stream_count = @metadata[:format][:nb_streams].to_i

        if @format_tags&.key?(:creation_time)
          begin
            @creation_time = Time.parse(@format_tags[:creation_time])
          rescue ArgumentError
            nil
          end
        end
      end
    end

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

    def parse_programs
      @programs = @metadata[:programs]&.map do |program|
        FFMPEG::Metadata::Program.new(program)
      end
    end

    def streams_for_type(type)
      streams = @metadata[:streams]

      streams.select { |stream| stream.key?(:codec_type) and stream[:codec_type] == type }
    end

    def fix_encoding(output)
      output[/test/] # Running a regexp on the string throws error if it's not UTF-8
    rescue ArgumentError
      output.force_encoding('ISO-8859-1')
    end

    def head(location = @path, limit = FFMPEG.max_http_redirect_attempts)
      url = URI(location)
      return unless url.path

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = url.port == 443
      response = http.request_head(url.request_uri)

      case response
      when Net::HTTPRedirection
        raise FFMPEG::HTTPTooManyRequests if limit.zero?

        new_uri = url + URI(response['Location'])
        @path = new_uri.to_s

        head(new_uri, limit - 1)
      else
        response
      end
    rescue SocketError, Errno::ECONNREFUSED
      nil
    end

    def capture3(*cmd)
      Open3.popen3(*cmd, {}) do |_i, o, e|
        out_reader = Thread.new { o&.read }
        err_reader = Thread.new { e&.read }

        [out_reader.value || '', err_reader.value || '']
      end
    end
  end
end
