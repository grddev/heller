# encoding: utf-8
require 'kafka-jars'

module Kafka
  module Api
    java_import 'kafka.api.FetchRequest'
    java_import 'kafka.api.FetchRequestBuilder'
    java_import 'kafka.api.PartitionOffsetRequestInfo'
    java_import 'kafka.api.OffsetRequest'
  end

  module JavaApi
    java_import 'kafka.javaapi.FetchResponse'
    java_import 'kafka.javaapi.OffsetRequest'
    java_import 'kafka.javaapi.OffsetResponse'
    java_import 'kafka.javaapi.PartitionMetadata'
    java_import 'kafka.javaapi.TopicMetadata'
    java_import 'kafka.javaapi.TopicMetadataRequest'
    java_import 'kafka.javaapi.TopicMetadataResponse'
  end

  module Common
    java_import 'kafka.common.TopicAndPartition'
  end

  module Serializer
    java_import 'kafka.serializer.StringEncoder'
    java_import 'kafka.serializer.StringDecoder'
  end

  module Consumer
    java_import 'kafka.javaapi.consumer.SimpleConsumer'
    java_import 'kafka.javaapi.consumer.ConsumerConnector'
  end

  module Message
    java_import 'kafka.message.Message'
    java_import 'kafka.javaapi.message.MessageSet'
    java_import 'kafka.javaapi.message.ByteBufferMessageSet'
  end

  module Producer
    java_import 'kafka.javaapi.producer.Producer'
    java_import 'kafka.producer.ProducerConfig'
    java_import 'kafka.producer.SyncProducerConfig'
    java_import 'kafka.producer.KeyedMessage'
  end

  module Errors
    java_import 'kafka.common.ErrorMapping'
    java_import 'kafka.common.UnknownException'
    java_import 'kafka.message.InvalidMessageException'
    java_import 'kafka.common.OffsetOutOfRangeException'
    java_import 'kafka.common.UnknownTopicOrPartitionException'
    java_import 'kafka.common.InvalidMessageSizeException'
    java_import 'kafka.common.LeaderNotAvailableException'
    java_import 'kafka.common.NotLeaderForPartitionException'
    java_import 'kafka.common.RequestTimedOutException'
    java_import 'kafka.common.BrokerNotAvailableException'
    java_import 'kafka.common.ReplicaNotAvailableException'
    java_import 'kafka.common.MessageSizeTooLargeException'
    java_import 'kafka.common.ControllerMovedException'
  end
end