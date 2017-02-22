# TODO: check azure_webapps_spec
require 'spec_helper'
require 'dpl/provider/pages'

describe DPL::Provider::Pages do
  let(:options) do
    {
      :local_dir => '',
      :project_name => '',
      :fqdn => '',
      :repo => '',
      :target_branch => 'gh-pages',
      :keep_history => true,
      :github_token => '',
      :email => '',
      :name => ''
    }
  end

  subject :provider do
    described_class.new(DummyContext.new, options)
  end

  its(:needs_key?) { should be false }

  describe '#github_deploy' do
    example do
      expect(provider.context).to receive(:shell).with(
        'rm -rf .git > /dev/null 2>&1'
      ).and_return(true)
      expect(provider.context).to receive(:shell).with(
        "touch \"deployed at `date` by #{options[:name]}\""
      ).and_return(true)
      expect(provider.context).to receive(:shell).with(
        "git init"
      ).and_return(true)
      expect(provider.context).to receive(:shell).with(
        "git config user.email '#{options[:email]}'"
      ).and_return(true)
      expect(provider.context).to receive(:shell).with(
        "git config user.name '#{options[:name]}'"
      ).and_return(true)
      expect(provider.context).to receive(:shell).with(
        "echo '#{options[:fqdn]}' > CNAME"
      ).and_return(true)
      expect(provider.context).to receive(:shell).with(
        'git add .'
      ).and_return(true)
      expect(provider.context).to receive(:shell).with(
        "git commit -m 'Deploy #{options[:project_name]} to github.com/#{options[:repo]}.git:#{options[:target_branch]}'"
      ).and_return(true)
      expect(provider.context).to receive(:shell).with(
        "git push --force --quiet 'https://#{options[:github_token]}@github.com/#{options[:repo]}.git' master:#{options[:target_branch]} > /dev/null 2>&1"
      ).and_return(true)
      provider.deploy
    end
  end

  describe '#push_app' do
    example do
      expect(provider.context).to receive(:shell).with(
        '...'
      ).and_return(...)
    end
    it 'on api success' do
      expect(provider).to receive(:api_call).with('/1.0/~user/repo/branch/+code-import', {'ws.op' => 'requestImport'}).and_return Net::HTTPSuccess.new("HTTP/1.1", 200, "Ok")
      provider.push_app
    end

    it 'on api failure' do
      expect(provider).to receive(:api_call).with('/1.0/~user/repo/branch/+code-import', {'ws.op' => 'requestImport'}).and_return double("Net::HTTPUnauthorized", code: 401, body: "", class: Net::HTTPUnauthorized)
      expect { provider.push_app }.to raise_error(DPL::Error)
    end
  end

  describe 'private method' do
    describe '#authorization' do
      it 'should return correct oauth' do
        result = provider.instance_eval { authorization }
        expect(result).to include('oauth_token="uezinoosinmxkewhochq",')
        expect(result).to include('oauth_signature="%26dinb6fao4jh0kfdn5mich31cbikdkpjplkmadhi80h93kbbaableeeg41mm0jab9jif8ch7i2k9a80n5",')
      end
    end
  end

end
