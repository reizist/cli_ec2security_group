# http://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/Using_SettingUpUser.html
# http://docs.aws.amazon.com/AWSRubySDK/latest/AWS.html
require 'bundler/setup'
require 'yaml'

Bundler.require

CONFIG = YAML.load_file('config.yml')

class Ec2SecurityGroup

  def initialize(account_key='default')
    unless CONFIG[account_key]
      puts "Server key '#{account_key}' does not exist."
      exit(1)
    end


    AWS.config( :ec2_endpoint  => "ec2.ap-northeast-1.amazonaws.com")
    @ec2 = AWS::EC2.new(
      access_key_id: CONFIG[account_key]['access_key_id'],
      secret_access_key: CONFIG[account_key]['secret_access_key']
    )
  end

  def main
    %w(http smtp ssh https mysql redis).each do |sg|
      begin
        security_group = @ec2.security_groups.create(sg)
        hash = send(sg)
        security_group.authorize_ingress(hash[:protocol], hash[:port])
      rescue AWS::EC2::Errors::InvalidGroup::Duplicate
        next
      end
    end
  end

  private

  # tcp:80
  def http
    {protocol: :tcp, port: 80 }
  end

  # tcp:25
  def smtp
    {protocol: :tcp, port: 25 }
  end

  # tcp:22
  def ssh
    {protocol: :tcp, port: 22 }
  end

  # tcp:443
  def https
    {protocol: :tcp, port: 443 }
  end

  # tcp:3306
  def mysql
    {protocol: :tcp, port: 3306 }
  end

  # tcp:6379
  def redis
    {protocol: :tcp, port: 6379 }
  end
end

client = Ec2SecurityGroup.new
client.main
