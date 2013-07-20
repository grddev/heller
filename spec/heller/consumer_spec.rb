# encoding: utf-8

require 'spec_helper'

module Heller
  describe Consumer do
    let(:consumer) do
      described_class.new('localhost', '9092', consumer_impl: consumer_impl, client_id: 'spec-consumer')
    end

    let :consumer_impl do
      double(:consumer_impl)
    end

    let :consumer_spy do
      double(:consumer, fetch: fetch_response)
    end

    let :fetch_response do
      create_fake_fetch_response
    end

    before do
      consumer_impl.stub(:new) do |*args|
        consumer_spy.stub(:client_id).and_return(args.last)
        consumer_spy
      end
    end

    describe '#new' do
      it 'proxies arguments when creating the internal consumer' do
        consumer = described_class.new('localhost', 9092, consumer_impl: consumer_impl)
        expect(consumer_impl).to have_received(:new).with('localhost', 9092, anything, anything, anything)
      end

      context 'when not given any options' do
        it 'fills in sane defaults for missing options' do
          consumer = described_class.new('localhost', 9092, consumer_impl: consumer_impl)
          expect(consumer_impl).to have_received(:new).with('localhost', 9092, 30000, 65536, anything)
        end

        context 'client_id' do
          it 'makes some kind of attempt to generate a unique client id' do

            consumer = described_class.new('localhost', 9092, consumer_impl: consumer_impl)
            consumer.client_id.should =~ /heller\-consumer\-[a-f0-9]{8}\-[a-f0-9]{4}\-[a-f0-9]{4}\-[a-f0-9]{4}\-[a-f0-9]{12}/
          end
        end
      end

      context 'when given options' do
        it 'merges options with the defaults' do
          consumer = described_class.new('localhost', 9092, consumer_impl: consumer_impl, timeout: 10, buffer_size: 11, client_id: 'hi')
          expect(consumer_impl).to have_received(:new).with('localhost', 9092, 10, 11, 'hi')
        end
      end
    end

    describe '#fetch' do
      it 'creates FetchRequests from given hash' do
        expect(consumer_spy).to receive(:fetch) do |request|
          request.should be_a(Kafka::Api::FetchRequest)
          request_info = request.request_info
          request_info.should have(1).item

          tuple = request_info.first
          tuple._1.topic.should == 'spec'
          tuple._1.partition.should == 0
          tuple._2.offset.should == 1

          fetch_response
        end

        consumer.fetch({['spec', 0] => 1})
      end

      it 'returns a hash with Enumerators over offset and decoded message pairs' do
        fake_fetch_response = create_fake_fetch_response('spec message', 'spec message #2')
        consumer_spy.stub(:fetch).and_return(fake_fetch_response)

        response_hash = consumer.fetch({['spec', 0] => 0})
        response_hash.keys.should == [['spec', 0]]

        result = {}
        response_hash.values.first.each { |o, m| result[o] = m }
        result.should == {0 => 'spec message', 1 => 'spec message #2'}
      end

      context 'fetch options' do
        it 'sets a default fetch size' do
          expect(consumer_spy).to receive(:fetch) do |request|
            tuple = request.request_info.first
            tuple._2.fetch_size.should == 1024 * 1024

            fetch_response
          end

          consumer.fetch({['spec', 0] => 0})
        end

        it 'allows fetch size to be overridden' do
          expect(consumer_spy).to receive(:fetch) do |request|
            tuple = request.request_info.first
            tuple._2.fetch_size.should == 1024

            fetch_response
          end

          consumer.fetch({['spec', 0] => 0}, 1024)
        end

        it 'includes the client_id' do
          expect(consumer_spy).to receive(:fetch) do |request|
            request.client_id.should == 'spec-consumer'

            fetch_response
          end

          consumer.fetch({['spec', 0] => 0})
        end

        it 'includes max_wait if given when the consumer was created' do
          consumer = described_class.new('localhost', '9092', consumer_impl: consumer_impl, client_id: 'spec-consumer', max_wait: 1)

          expect(consumer_spy).to receive(:fetch) do |request|
            request.max_wait.should == 1

            fetch_response
          end

          consumer.fetch({['spec', 0] => 0})
        end

        it 'includes min_bytes if given when the consumer was created' do
          consumer = described_class.new('localhost', '9092', consumer_impl: consumer_impl, client_id: 'spec-consumer', min_bytes: 1024)

          expect(consumer_spy).to receive(:fetch) do |request|
            request.min_bytes.should == 1024

            fetch_response
          end

          consumer.fetch({['spec', 0] => 0})
        end
      end
    end

    describe '#offsets_before', pending: 'fix #metadata first' do
    end

    describe '#earliest_offset', pending: 'fix #metadata first' do
    end

    describe '#latest_offset', pending: 'fix #metadata first' do
    end

    describe '#metadata', pending: 'fix #fetch first' do
      context 'given a list of topics' do
        let :topic_metadata_response do
        end

        it 'sends a TopicMetadataRequest' do
          expect(consumer_spy).to receive(:send) do |request|
            request.topics.to_a.should == ['topic1', 'topic2']
            topic_metadata_response
          end

          consumer.metadata(['topic1', 'topic2'])
        end
      end

      context 'given an empty list' do
      end
    end
  end
end