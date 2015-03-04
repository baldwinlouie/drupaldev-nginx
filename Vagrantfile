Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu-14.04-amd64-vbox.box"
  config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vbox.box"

  config.vm.hostname = "ubuntu14.dev"

  config.vm.network :private_network, ip: "192.168.99.10"
    config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |v|
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--memory", 2048]
  end

  config.vm.synced_folder "./sites", "/var/www", :nfs => {:mount_options => ['noatime'], :export_options => ['rw', 'sync', 'nohide']}, :map_uid => 0, :map_guid => 0
  config.vm.provision :shell, :inline => "sudo apt-get update"
  config.vm.provision :shell, :path => "upgrade_puppet.sh"

  config.vm.provision :puppet do |puppet|
    puppet.facter = {
      "ssh_username" => "vagrant"
    }

    puppet.manifests_path = "manifests"
    puppet.module_path = "modules"
    puppet.options = ["--verbose", "--hiera_config /vagrant/hiera.yaml"]
  end

  config.ssh.username = "vagrant"
end
