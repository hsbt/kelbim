require 'forwardable'
require 'kelbim/ext/elb-listener-ext'
require 'kelbim/wrapper/policy-collection'
require 'kelbim/logger'

module Kelbim
  class ELBWrapper
    class LoadBalancerCollection
      class LoadBalancer
        class ListenerCollection
          class Listener
            extend Forwardable
            include Logger::ClientHelper

            def_delegators(
              :@listener,
              :protocol, :port, :instance_protocol, :instance_port, :load_balancer)

            def initialize(listener, options)
              @listener = listener
              @options = options
            end

            def policies
              PolicyCollection.new(@listener.policies, self, @options)
            end

            def eql?(dsl)
              compare_server_certificate(dsl)
            end

            def update(dsl)
              compare_server_certificate(dsl) do
                # XXX: logging
                unless @options.dry_run
                  ss = @options.iam.server_certificates[dsl.server_certificate]

                  unless ss
                    raise "Can't find ServerCertificate: #{ss_name} in #{self.load_balancer.vpc_id || :classic} > #{self.load_balancer.name}"
                  end

                  @listener.server_certificate = ss
                end
              end
            end

            def policies=(policy_list)
              # XXX: logging
              unless @options.dry_run
                @options.elb.client.set_load_balancer_policies_of_listener({
                  :load_balancer_name => @listener.load_balancer.name,
                  :load_balancer_port => @listener.port,
                  :policy_names       => policy_list.map {|i| i.name },
                })
              end
            end

            def delete
              # XXX: ポリシーも削除（オプションで制御）
              # XXX: logging
              unless @options.dry_run
                @listener.delete
              end
            end

            private
            def compare_server_certificate(dsl)
              aws_server_certificate = @listener.server_certificate
              aws_server_certificate = aws_server_certificate.name if aws_server_certificate
              same = (aws_server_certificate == dsl.server_certificate)
              yield if !same && block_given?
              return same
            end
          end # Listener
        end # ListenerCollection
      end # LoadBalancer
    end # LoadBalancerCollection
  end # ELBWrapper
end # Kelbim
