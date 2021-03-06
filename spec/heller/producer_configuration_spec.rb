# encoding: utf-8

require 'spec_helper'

module Heller
  describe ProducerConfiguration do
    it 'has sane defaults for running locally' do
      configuration = described_class.new

      expect(configuration[:brokers]).to eq('localhost:9092')
      expect(configuration[:serializer]).to eq('kafka.serializer.StringEncoder')
      expect(configuration[:ack]).to eq(-1)
      expect(configuration[:type]).to eq(:sync)
    end

    context 'given hash with user-defined options' do
      it 'merges them with the defaults' do
        configuration = described_class.new({
          brokers: 'localhost:9092,localhost:9093',
          serializer: 'kafka.serializer.DefaultEncoder',
          batch_size: 1500
        })

        expect(configuration[:brokers]).to eq('localhost:9092,localhost:9093')
        expect(configuration[:serializer]).to eq('kafka.serializer.DefaultEncoder')
        expect(configuration[:batch_size]).to eq(1500)
      end
    end

    context '#to_java' do
      let :configuration do
        described_class.new({
          brokers: 'localhost:9092,localhost:9093',
          type: :async,
          serializer: 'kafka.serializer.StringEncoder',
          key_serializer: 'kafka.serializer.DefaultEncoder',
          partitioner: 'kafka.producer.DefaultPartitioner',
          compression: :gzip,
          num_retries: 5,
          retry_backoff: 1500,
          metadata_refresh_interval: 5000,
          batch_size: 2000,
          client_id: 'spec-client',
          request_timeout: 10000,
          buffer_limit: 100 * 100,
          buffer_timeout: 1000 * 100,
          enqueue_timeout: 1000,
          socket_buffer: 1024 * 1000,
          ack: -1
        })
      end

      it 'returns an instance of Kafka::Producer::ProducerConfig' do
        expect(configuration.to_java).to be_a(Kafka::Producer::ProducerConfig)
      end

      it 'converts Ruby options to their corresponding Kafka specific option' do
        producer_config = configuration.to_java
        expect(producer_config.broker_list).to eq('localhost:9092,localhost:9093')
        expect(producer_config.request_required_acks).to eq(-1)
        expect(producer_config.producer_type).to eq('async')
        expect(producer_config.serializer_class).to eq('kafka.serializer.StringEncoder')
        expect(producer_config.key_serializer_class).to eq('kafka.serializer.DefaultEncoder')
        expect(producer_config.partitioner_class).to eq('kafka.producer.DefaultPartitioner')
        expect(producer_config.compression_codec.name).to eq('gzip')
        expect(producer_config.message_send_max_retries).to eq(5)
        expect(producer_config.retry_backoff_ms).to eq(1500)
        expect(producer_config.topic_metadata_refresh_interval_ms).to eq(5000)
        expect(producer_config.queue_buffering_max_ms).to eq(1000 * 100)
        expect(producer_config.queue_buffering_max_messages).to eq(10000)
        expect(producer_config.queue_enqueue_timeout_ms).to eq(1000)
        expect(producer_config.batch_num_messages).to eq(2000)
        expect(producer_config.send_buffer_bytes).to eq(1024 * 1000)
        expect(producer_config.client_id).to eq('spec-client')
        expect(producer_config.request_timeout_ms).to eq(10000)
      end
    end
  end
end
