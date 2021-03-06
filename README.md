# Kelbim

Kelbim is a tool to manage ELB.

It defines the state of ELB using DSL, and updates ELB according to DSL.

[![Gem Version](https://badge.fury.io/rb/kelbim.png)](http://badge.fury.io/rb/kelbim)
[![Build Status](https://travis-ci.org/winebarrel/kelbim.svg?branch=master)](https://travis-ci.org/winebarrel/kelbim)

**Notice**

It does not yet support the following load balancer policies:

* ProxyProtocolPolicyType
* BackendServerAuthenticationPolicyType
* PublicKeyPolicyType

## Installation

Add this line to your application's Gemfile:

    gem 'kelbim'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kelbim

## Usage

```sh
export AWS_ACCESS_KEY_ID='...'
export AWS_SECRET_ACCESS_KEY='...'
export AWS_REGION='ap-northeast-1'
kelbim -e -o ELBfile  # export ELB
vi ELBFile
kelbim -a --dry-run
kelbim -a             # apply `ELBfile` to ELB
```

## Help

```
Usage: kelbim [options]
    -p, --profile PROFILE_NAME
        --credentials-path PATH
    -k, --access-key ACCESS_KEY
    -s, --secret-key SECRET_KEY
    -r, --region REGION
    -a, --apply
    -f, --file FILE
    -n, --elb-names NAMES
        --dry-run
        --ec2s VPC_IDS
        --without-deleting-policy
    -e, --export
    -o, --output FILE
        --split
        --split-more
    -t, --test
        --show-load-balancers
        --show-policies
        --no-color
        --debug
```

## ELBfile example

```ruby
require 'other/elbfile'

# EC2 Classic
ec2 do
  load_balancer "my-load-balancer" do
    instances(
      "cthulhu",
      "nyar",
    )

    listeners do
      listener [:http, 80] => [:http, 80]
    end

    health_check do
      target "HTTP:80/index.html"
      timeout 5
      interval 30
      healthy_threshold 10
      unhealthy_threshold 2
    end

    attributes do
      connection_settings :idle_timeout=>60
      access_log :enabled => false
      cross_zone_load_balancing :enabled => false
      connection_draining :enabled => false, :timeout => 300
    end

    availability_zones(
      "ap-northeast-1a",
      "ap-northeast-1b"
    )
  end
end

# EC2 VPC
ec2 "vpc-XXXXXXXXX" do
  load_balancer "my-load-balancer", :internal => true do
    instances(
      "nyar",
      "yog"
    )

    listeners do
      listener [:tcp, 80] => [:tcp, 80]
      listener [:https, 443] => [:http, 80] do
        app_cookie_stickiness "CookieName"=>"20"
        ssl_negotiation ["Protocol-TLSv1", "Protocol-SSLv3", "AES256-SHA", ...]
        server_certificate "my-cert"
      end
    end

    health_check do
      target "TCP:80"
      timeout 5
      interval 30
      healthy_threshold 10
      unhealthy_threshold 2
    end

    attributes do
      access_log :enabled => true, :s3_bucket_name => "any_bucket", :s3_bucket_prefix => nil, :emit_interval => 60
      cross_zone_load_balancing :enabled => true
      connection_draining :enabled => false, :timeout => 300
    end

    subnets(
      "subnet-XXXXXXXX"
    )

    security_groups(
      "default"
    )
  end
end
```

## Test

```ruby
ec2 "vpc-XXXXXXXXX" do
  load_balancer "my-load-balancer" do
    spec do
      url = URI.parse('http://www.example.com/')
      res = Net::HTTP.start(url.host, url.port) {|http| http.get(url.path) }
      expect(res).to be_a(Net::HTTPOK)
    end
    ...
```

```sh
shell> kelbim -t
Test `ELBfile`
...

Finished in 3.16 seconds
3 examples, 0 failures
```
