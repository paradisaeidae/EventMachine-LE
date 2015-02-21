require 'em_test_helper'

class TestIPv6 < Test::Unit::TestCase

  if Test::Unit::TestCase.public_ipv6?

    # Tries to connect to ipv6.google.com (2a00:1450:4007:804::1011) port 80 via TCP.
    # Timeout in 6 seconds.
    def test_ipv6_tcp_client_with_ipv6_google_com
      conn = nil
      setup_timeout(6)

      EM.run do
        conn = EM::connect("2a00:1450:4007:804::1011", 80) do |c|
          def c.connected
            @connected
          end

          def c.unbind(reason)
            warn "unbind: #{reason.inspect}" if reason # XXX at least find out why it failed
          end

          def c.connection_completed
            @connected = true
            EM.stop
          end
        end
      end

      assert conn.connected
    end

    # Runs a TCP server in the local IPv6 address, connects to it and sends a specific data.
    # Timeout in 2 seconds.
    def test_ipv6_tcp_local_server
      @@received_data = nil
      @local_port = next_port
      setup_timeout(2)

      EM.run do
        EM.start_server(@@public_ipv6, @local_port) do |s|
          def s.receive_data data
            @@received_data = data
            EM.stop
          end
        end

        EM::connect(@@public_ipv6, @local_port) do |c|
          def c.unbind(reason)
            warn "unbind: #{reason.inspect}" if reason # XXX at least find out why it failed
          end
          c.send_data "ipv6/tcp"
        end
      end

      assert_equal "ipv6/tcp", @@received_data
    end

    # Runs a UDP server in the local IPv6 address, connects to it and sends a specific data.
    # Timeout in 2 seconds.
    def test_ipv6_udp_local_server
      @@received_data = nil
      @local_port = next_port
      setup_timeout(2)

      EM.run do
        EM.open_datagram_socket(@@public_ipv6, @local_port) do |s|
          def s.receive_data data
            @@received_data = data
            EM.stop
          end
        end

        EM.open_datagram_socket(@@public_ipv6, next_port) do |c|
          c.send_datagram "ipv6/udp", @@public_ipv6, @local_port
        end
      end

      assert_equal "ipv6/udp", @@received_data
    end

    # Try to connect via TCP to an invalid IPv6. EM.connect should raise
    # EM::ConnectionError.
    def test_tcp_connect_to_invalid_ipv6
      invalid_ipv6 = "1:A"

      EM.run do
        begin
          error = nil
          EM.connect(invalid_ipv6, 1234)
        rescue => e
          error = e
        ensure
          EM.stop
          assert_equal EM::ConnectionError, (error && error.class)
        end
      end
    end

    # Try to send a UDP datagram to an invalid IPv6. EM.send_datagram should raise
    # EM::ConnectionError.
    def test_udp_send_datagram_to_invalid_ipv6
      invalid_ipv6 = "1:A"

      EM.run do
        begin
          error = nil
          EM.open_datagram_socket(@@public_ipv6, next_port) do |c|
            c.send_datagram "hello", invalid_ipv6, 1234
          end
        rescue => e
          error = e
        ensure
          EM.stop
          assert_equal EM::ConnectionError, (error && error.class)
        end
      end
    end
  class TestUDP46 < Test::Unit::TestCase
 # this is a bit brittle.  Maybe do not test for the actual error...
 WANT_ALL = [
  ( RUBY_PLATFORM =~ /darwin1/ and ["::1", "::241.1.2.3", 5555, Errno::EHOSTUNREACH]),
  # not an error in Linux (!?), strange handling in OSX 10.5.x (darwin9)
  ["::1", "241.2.3.4", 5555,  (RUBY_PLATFORM =~ /linux/ ? Errno::ENETUNREACH : Errno::EINVAL)],
  ["127.0.0.1", "241.4.5.6", 5555,  (RUBY_PLATFORM =~ /linux/ ? Errno::EINVAL : Errno::ENETUNREACH)]].compact

  # Open a UDP socket listening on, say, ::1, and try to send a UDP
  # datagram to IP address, say, ::241.1.2.3 (so no network route).
  # Without the error handling fix, it makes EM close the UDP socket.
def test_udp_no_route
 WANT_ALL.each do | want |
  @@udp_socket_alive = false
  @@udp_socket_unbind_cause = nil
  @@error_came_in = false
  
  EM.run do
   EM::open_datagram_socket(want[0], next_port, EM::Connection) do |c|
    c.send_error_handling = :ERRORHANDLING_REPORT
    def c.unbind cause=nil
     @@udp_socket_unbind_cause = cause
     EM.stop end
    
    def c.receive_senderror(error, data)
     @@error_came_in = [error, data] end
    c.send_datagram "no-route", want[1], want[2]
    EM.add_timer(0.2) do
     @@udp_socket_alive = true  unless c.error?
     EM.stop end end end
    
   assert @@udp_socket_alive, "UDP socket was killed (unbind cause: #{@@udp_socket_unbind_cause})"
   assert_equal [want[3], [want[1], want[2].to_s]], @@error_came_in end end end

  else
    warn "no IPv6 in this host, skipping tests in #{__FILE__}"

    # Because some rubies will complain if a TestCase class has no tests.
    def test_ipv6_unavailable
      assert true
    end

  end
  


end
