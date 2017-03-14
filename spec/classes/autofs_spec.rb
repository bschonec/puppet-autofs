require 'spec_helper'
require 'hiera'

describe 'autofs', type: :class do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  hiera = Hiera.new(config: 'spec/fixtures/hiera/hiera.yaml')
  opsys = %w(
    Debian
    Ubuntu
    RedHat
    CentOS
    Suse
  )

  opsys.each do |os|
    context 'main init tests' do
      let(:facts) do
        {
          osfamily: os.to_s,
          concat_basedir: '/etc'
        }
      end
      it { is_expected.to compile }
      it { is_expected.to contain_class('autofs') }
      it { is_expected.to contain_class('autofs::package') }
      it { is_expected.to contain_class('autofs::service') }

      # Check Package and service
      it { is_expected.to contain_package('autofs').with_ensure('installed') }
      it { is_expected.to contain_service('autofs').that_requires('Package[autofs]') }
      it { is_expected.to contain_service('autofs').with_ensure('running') }
      it { is_expected.to contain_service('autofs').with_enable(true) }
    end
  end

  context 'it should create auto.home' do
    mounts = hiera.lookup('homedir', nil, nil)
    let(:params) { { mounts: mounts } }
    it 'is expected to have auto.home hiera values' do
      expect(mounts).to include(
        'mount' => '/home',
        'mapfile' => '/etc/auto.home',
        'mapcontents' => %w(test foo bar),
        'options' => '--timeout=120',
        'order' => 1
      )
    end
  end

  context 'it should create home direct mount' do
    mounts = hiera.lookup('direct', nil, nil)
    let(:params) { { mounts: mounts } }
    it 'is expected to have direct mount hiera values' do
      expect(mounts).to include(
        'mount' => '/-',
        'mapfile' => '/etc/auto.home',
        'mapcontents' => %w(/home\ /test /home\ /foo /home\ /bar),
        'options' => '--timeout=120',
        'order' => 1
      )
    end
  end

  context 'hiera_confdir_test' do
    mounts = hiera.lookup('confdir', nil, nil)
    let(:params) { { mounts: mounts } }
    it 'is expected to have auto.master.d hiera values' do
      expect(mounts).to include(
        'mount' => '/home',
        'mapfile' => '/etc/auto.home',
        'mapcontents' => %w(*\ -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl\ server.example.com:/path/to/home/shares),
        'options' => '--timeout=120',
        'order' => 1,
        'use_dir' => true
      )
    end
  end

  context 'Parameter is not a hash' do
    mounts = 'string'
    let(:params) { { mounts: mounts } }
    it 'is expected to fail' do
      is_expected.to compile.and_raise_error(%r{parameter 'mounts' expects a Hash value})
    end
  end
end
