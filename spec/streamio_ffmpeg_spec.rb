# frozen_string_literal: true

require 'spec_helper'

describe FFMPEG do
  describe 'logger' do
    after do
      described_class.logger = Logger.new(nil)
    end

    it 'is a Logger' do
      expect(described_class.logger).to be_instance_of(Logger)
    end

    it 'is at info level' do
      described_class.logger = nil # Reset the logger so that we get the default
      expect(described_class.logger.level).to eq(Logger::INFO)
    end

    it 'is assignable' do
      new_logger = Logger.new($stdout)
      described_class.logger = new_logger
      expect(described_class.logger).to eq(new_logger)
    end
  end

  describe '.ffmpeg_binary' do
    after do
      described_class.ffmpeg_binary = nil
    end

    it 'defaults to finding from path' do
      allow(described_class).to receive(:which).and_return('/usr/local/bin/ffmpeg')
      expect(described_class.ffmpeg_binary).to eq described_class.which('ffprobe')
    end

    it 'is assignable' do
      allow(File).to receive(:executable?).with('/new/path/to/ffmpeg').and_return(true)
      described_class.ffmpeg_binary = '/new/path/to/ffmpeg'
      expect(described_class.ffmpeg_binary).to eq '/new/path/to/ffmpeg'
    end

    it 'raises exception if it cannot find assigned executable' do
      expect { described_class.ffmpeg_binary = '/new/path/to/ffmpeg' }.to raise_error(Errno::ENOENT)
    end

    it 'raises exception if it cannot find executable on path' do
      allow(File).to receive(:executable?).and_return(false)
      expect { described_class.ffmpeg_binary }.to raise_error(Errno::ENOENT)
    end
  end

  describe '.ffprobe_binary' do
    after do
      described_class.ffprobe_binary = nil
    end

    it 'defaults to finding from path' do
      allow(described_class).to receive(:which).and_return('/usr/local/bin/ffprobe')
      expect(described_class.ffprobe_binary).to eq described_class.which('ffprobe')
    end

    it 'is assignable' do
      allow(File).to receive(:executable?).with('/new/path/to/ffprobe').and_return(true)
      described_class.ffprobe_binary = '/new/path/to/ffprobe'
      expect(described_class.ffprobe_binary).to eq '/new/path/to/ffprobe'
    end

    it 'raises exception if it cannot find assigned executable' do
      expect { described_class.ffprobe_binary = '/new/path/to/ffprobe' }.to raise_error(Errno::ENOENT)
    end

    it 'raises exception if it cannot find executable on path' do
      allow(File).to receive(:executable?).and_return(false)
      expect { described_class.ffprobe_binary }.to raise_error(Errno::ENOENT)
    end
  end

  describe '.max_http_redirect_attempts' do
    after do
      described_class.max_http_redirect_attempts = nil
    end

    it 'defaults to 10' do
      expect(described_class.max_http_redirect_attempts).to eq 10
    end

    it 'is an Integer' do
      expect { described_class.max_http_redirect_attempts = 1.23 }.to raise_error(Errno::ENOENT)
    end

    it 'is not negative' do
      expect { described_class.max_http_redirect_attempts = -1 }.to raise_error(Errno::ENOENT)
    end

    it 'is assignable' do
      described_class.max_http_redirect_attempts = 5
      expect(described_class.max_http_redirect_attempts).to eq 5
    end
  end
end
