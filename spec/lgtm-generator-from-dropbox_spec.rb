require 'rspec'
require_relative '../lgtm-generator-from-dropbox'

RSpec.describe LgtmGenerator do
  describe 'Executer' do
    describe '.set_client' do
      let(:json_data) { { access_token: 'dummy' }.to_json }

      it 'generates DropboxApi::Client' do
        client = LgtmGenerator::Executer.setup_client(json_data)
        expect(client.is_a?(DropboxApi::Client)).to eq true
      end
    end

    describe '.adopt_history' do
      let(:file_list) { ['foo', 'bar'] }

      it 'returns name if should_adopt? is true' do
        allow(History).to receive(:should_adopt?).and_return(true)
        name = LgtmGenerator::Executer.adopt_history(file_list)
        expect(file_list.include?(name)).to eq true
      end
    end

    describe '.select_only_gif' do
      let(:names) { ['foo.png', 'bar.gif', 'fizz.jpg', 'bazz.gif'] }
      it 'returns only *.gif' do
        gifs = LgtmGenerator::Executer.select_only_gif(names)
        expect(gifs).to match ['bar.gif', 'bazz.gif']
      end
    end

    describe '.extract_name_from' do
      let(:item1) { double('item1') }
      let(:item2) { double('item2') }
      let(:json_data) { { target_directory: 'dummy' }.to_json }

      it 'returns names' do
        allow(item1).to receive(:name).and_return('foo')
        allow(item2).to receive(:name).and_return('bar')
        names =
          LgtmGenerator::Executer.extract_name_from([item1, item2], json_data)
        expect(names).to match ['foo', 'bar']
      end
    end

    describe '.generate_lgtm!' do
      let(:json) { { 'cjk_font': nil }.to_json }
      let(:params) {
        {
          'use-gif' => use_gif,
          'text-gif' => gif_text,
          'size' => size,
          'text' => text,
          'color' => color,
          'auto-color' => auto_color,
          'background' => background
        }.to_h
      }
      let(:use_gif) { false }
      let(:gif_text) { false }
      let(:size) { nil }
      let(:text) { nil }
      let(:color) { nil }
      let(:auto_color) { nil }
      let(:background) { nil }

      let(:generator) { double('generator') }

      it 'does not raise error with valid params' do
        allow(generator).to receive(:generate!).and_return(nil)

        expect {
          LgtmGenerator::Executer.generate_lgtm!(params, json, generator)
        }.not_to raise_error
      end

      it 'raises error with invalid params' do
        allow(generator).to receive(:generate!).and_return(nil)
        params.delete('use-gif')

        expect {
          LgtmGenerator::Executer.generate_lgtm!(params, json, generator)
        }.to raise_error(RuntimeError)
      end
    end

    describe '.resize!' do
      it '' do
        size = 'foo'
        expect{
          LgtmGenerator::Executer.resize!(size, nil)
        }.to raise_error(RuntimeError)
      end

      it '' do
        size = '123x456'
        expect{
          LgtmGenerator::Executer.resize!(size, nil)
        }.to raise_error(RuntimeError)
      end
    end

    describe '.select_generator' do
      def spec(use_gif, text_gif, generator)
        params = {}
        params['use-gif'] = use_gif
        params['text-gif'] = text_gif
        expect(
          LgtmGenerator::Executer.select_generator(params)
        ).to eq generator
      end

      it 'select valid generator' do
        spec(true, false, Generator::Gif)
        spec(true, true, Generator::Gif)
        spec(false, false, Generator::Jpg)
        spec(false, true, Generator::TextGif)
      end
    end

    describe '.select_output_file' do
      def spec(use_gif, text_gif, output)
        params = {}
        params['use-gif'] = use_gif
        params['text-gif'] = text_gif
        expect(
          LgtmGenerator::Executer.select_output_file(params)
        ).to eq output
      end

      it 'select valid generator' do
        spec(true, false, OUTPUT_GIF_NAME)
        spec(true, true, OUTPUT_GIF_NAME)
        spec(false, false, OUTPUT_IMAGE_NAME)
        spec(false, true, OUTPUT_GIF_NAME)
      end
    end
  end
end
