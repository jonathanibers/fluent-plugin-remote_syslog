require "fluent/mixin/config_placeholders"
require "fluent/mixin/plaintextformatter"
require 'fluent/mixin/rewrite_tag_name'

module Fluent
  class RemoteSyslogOutput < Fluent::Output
    Fluent::Plugin.register_output("remote_syslog", self)

    config_param :hostname, :string, :default => ""

    include Fluent::Mixin::PlainTextFormatter
    include Fluent::Mixin::ConfigPlaceholders
    include Fluent::HandleTagNameMixin
    include Fluent::Mixin::RewriteTagName

    config_param :host, :string
    config_param :port, :integer, :default => 514

    config_param :facility, :string, :default => "user"
    config_param :severity, :string, :default => "info"
    config_param :tag, :string, :default => "fluentd"

    def initialize
      super
      require "remote_syslog_logger"
      @loggers = {}
    end

    def shutdown
      @loggers.values.each(&:close)
      super
    end

    def emit(tag, es, chain)
      es.each do |time, record|
        record.each_pair do |k, v|
          if v.is_a?(String)
            v.force_encoding("utf-8")
          end
        end

        #tag = rewrite_tag!(tag.dup)
        
        #@loggers[@host + @port.to_s] = RemoteSyslogLogger::UdpSender.new(
          #@host, @port, facility: record["facility"] || @facility,
          #severity: record["severity"] || @severity,
          #program: record["tag"] || tag,
          #local_hostname: record["hostnane"] || @hostname)

        #@loggers[@host + @port.to_s].transmit format(tag, time, record)
        
        tag = rewrite_tag!(tag.dup)
        @loggers[@host + @port.to_s] = RemoteSyslogLogger::UdpSender.new(@host,
          @port,
          facility: record["facility"] || @facility,
          severity: record["severity"] || @severity,
          program: record["tag"] || tag,
          local_hostname: record["hostname"] || @hostname)

        @loggers[@host + @port.to_s].transmit(record["message"])

      end
      chain.next
    end
  end
end
