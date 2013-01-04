require 'webmachine/events'

module Webmachine
  module Trace
    # This module is injected into {Webmachine::Decision::FSM} when
    # tracing is enabled for a resource, enabling the capturing of
    # traces.
    module FSM
      # Adds the request to the trace.
      # @param [Webmachine::Request] request the request to be traced
      def trace_request(request)
        Webmachine::Events.publish('wm.trace.request', {
          :type => :request,
          :trace_id => trace_id,
          :method => request.method,
          :path => request.uri.request_uri.to_s,
          :headers => request.headers,
          :body => request.body.to_s
        })
      end

      # Adds the response to the trace.
      # @param [Webmachine::Response] response the response to be traced
      def trace_response(response)
        Webmachine::Events.publish('wm.trace.response', {
          :type => :response,
          :trace_id => trace_id,
          :code => response.code.to_s,
          :headers => response.headers,
          :body => trace_response_body(response.body)
        })
      end

      # Adds a decision to the trace.
      # @param [Symbol] decision the decision being processed
      def trace_decision(decision)
        Webmachine::Events.publish('wm.trace.decision', {
          :type => :decision,
          :trace_id => trace_id,
          :decision => decision
        })
      end

      # Overrides the default resource accessor so that incoming
      # callbacks are traced.
      def resource
        @resource_proxy ||= ResourceProxy.new(@resource)
      end

      private
      def trace_id
        resource.object_id.to_s
      end

      # Works around streaming encoders where possible
      def trace_response_body(body)
        case body
        when FiberEncoder
          # TODO: figure out how to properly rewind or replay the
          # fiber
          body.inspect
        when EnumerableEncoder
          body.body.join
        when CallableEncoder
          body.body.call.to_s
        else
          body.to_s
        end
      end
    end
  end
end
