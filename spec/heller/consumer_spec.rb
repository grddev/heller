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
          expect(request).to be_a(Kafka::Api::FetchRequest)
          request_info = request.request_info
          expect(request_info).to have(1).item

          tuple = request_info.first
          expect(tuple._1.topic).to eq('spec')
          expect(tuple._1.partition).to eq(0)
          expect(tuple._2.offset).to eq(1)

          fetch_response
        end

        consumer.fetch({['spec', 0] => 1})
      end

      it 'returns a hash with Enumerators over offset and decoded message pairs' do
        fake_fetch_response = create_fake_fetch_response('spec message', 'spec message #2')
        consumer_spy.stub(:fetch).and_return(fake_fetch_response)

        response_hash = consumer.fetch({['spec', 0] => 0})
        expect(response_hash.keys).to eq([['spec', 0]])

        result = {}
        response_hash.values.first.each { |o, m| result[o] = m }
        expect(result).to eq({0 => 'spec message', 1 => 'spec message #2'})
      end

      context 'fetch options' do
        it 'sets a default fetch size' do
          expect(consumer_spy).to receive(:fetch) do |request|
            tuple = request.request_info.first
            expect(tuple._2.fetch_size).to eq(1024 * 1024)

            fetch_response
          end

          consumer.fetch({['spec', 0] => 0})
        end

        it 'allows fetch size to be overridden' do
          expect(consumer_spy).to receive(:fetch) do |request|
            tuple = request.request_info.first
            expect(tuple._2.fetch_size).to eq(1024)

            fetch_response
          end

          consumer.fetch({['spec', 0] => 0}, 1024)
        end

        it 'includes the client_id' do
          expect(consumer_spy).to receive(:fetch) do |request|
            expect(request.client_id).to eq('spec-consumer')

            fetch_response
          end

          consumer.fetch({['spec', 0] => 0})
        end

        it 'includes max_wait if given when the consumer was created' do
          consumer = described_class.new('localhost', '9092', consumer_impl: consumer_impl, client_id: 'spec-consumer', max_wait: 1)

          expect(consumer_spy).to receive(:fetch) do |request|
            expect(request.max_wait).to eq(1)

            fetch_response
          end

          consumer.fetch({['spec', 0] => 0})
        end

        it 'includes min_bytes if given when the consumer was created' do
          consumer = described_class.new('localhost', '9092', consumer_impl: consumer_impl, client_id: 'spec-consumer', min_bytes: 1024)

          expect(consumer_spy).to receive(:fetch) do |request|
            expect(request.min_bytes).to eq(1024)

            fetch_response
          end

          consumer.fetch({['spec', 0] => 0})
        end
      end
    end

    describe '#offsets_before' do
      before do
        consumer_spy.stub(:get_offsets_before)
      end

      it 'sends an OffsetRequest using #get_offsets_before' do
        expect(consumer_spy).to receive(:get_offsets_before) do |request|
          expect(request).to be_a(Kafka::Api::OffsetRequest)
        end

        consumer.offsets_before({['spec', 0] => Time.utc(2013, 7, 20)})
      end

      it 'includes client_id' do
        expect(consumer_spy).to receive(:get_offsets_before) do |request|
          expect(request.underlying.client_id).not_to be_nil
        end

        consumer.offsets_before({['spec', 0] => Time.utc(2013, 7, 20)})
      end

      it 'accepts ints instead of Time objects' do
        expect(consumer_spy).to receive(:get_offsets_before) do |request|
          request_info = request.underlying.request_info
          expect(request.underlying.request_info.values.first.time).to eq(0)
          expect(request_info.values.first.time).to eq(0)
        end

        consumer.offsets_before({['spec', 0] => 0})
      end

      context 'maximum number of offsets to fetch' do
        it 'defaults to 1' do
          expect(consumer_spy).to receive(:get_offsets_before) do |request|
            request_info = request.underlying.request_info
            expect(request_info.values.first.max_num_offsets).to eq(1)
          end

          consumer.offsets_before({['spec', 0] => 0})
        end

        it 'is overridable' do
          expect(consumer_spy).to receive(:get_offsets_before) do |request|
            request_info = request.underlying.request_info
            expect(request_info.values.first.max_num_offsets).to eq(10)
          end

          consumer.offsets_before({['spec', 0] => 0}, 10)
        end
      end
    end

    describe '#earliest_offset' do
      it 'sends an OffsetRequest with the magic value for \'earliest\' offset' do
        expect(consumer_spy).to receive(:get_offsets_before) do |request|
          request_info = request.underlying.request_info
          expect(request_info.values.first.time).to eq(-2)
        end

        consumer.earliest_offset([['spec', 0]])
      end

      it 'fetches only one offset per topic-partition combination' do
        expect(consumer_spy).to receive(:get_offsets_before) do |request|
          request_info = request.underlying.request_info
          expect(request_info.values.first.max_num_offsets).to eq(1)
        end

        consumer.earliest_offset([['spec', 0]])
      end
    end

    describe '#latest_offset' do
      it 'sends an OffsetRequest with the magic value for \'latest\' offset' do
        expect(consumer_spy).to receive(:get_offsets_before) do |request|
          request_info = request.underlying.request_info
          expect(request_info.values.first.time).to eq(-1)
        end

        consumer.latest_offset([['spec', 0]])
      end

      it 'fetches only one offset per topic-partition combination' do
        expect(consumer_spy).to receive(:get_offsets_before) do |request|
          request_info = request.underlying.request_info
          expect(request_info.values.first.max_num_offsets).to eq(1)
        end

        consumer.latest_offset([['spec', 0]])
      end
    end

    describe '#metadata' do

      # TODO: look at TopicMetadataResponse a bit more and figure
      # out if it's necessary to wrap it in some proxy class to
      # make it more appealing

      context 'given a list of topics' do
        it 'sends a TopicMetadataRequest' do
          expect(consumer_spy).to receive(:send) do |request|
            expect(request.topics.to_a).to eq(['topic1', 'topic2'])
          end

          consumer.metadata(['topic1', 'topic2'])
        end
      end

      context 'given an empty list' do
        it 'does not send any request' do
          expect(consumer_spy).to_not receive(:send)

          consumer.metadata([])
        end

        it 'returns nil' do
          expect(consumer.metadata([])).to be_nil
        end
      end
    end

    context '#disconnect' do
      before do
        consumer_spy.stub(:close)
      end

      it 'calls #close on the underlying consumer' do
        consumer.disconnect

        expect(consumer_spy).to have_received(:close)
      end

      it 'is aliased to #close' do
        consumer.close

        expect(consumer_spy).to have_received(:close)
      end
    end
  end
end
