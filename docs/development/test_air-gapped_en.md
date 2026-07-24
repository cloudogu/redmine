# Test if the dogu would work in an air-gapped environment

Redmine has the reoccurring problem that ruby gems are installed during upgrade.
This poses a problem in air-gapped environments.

Therefore, we need to test at least that rubygems.org will not be accessed during an upgrade.
The following tcpdump command might be helpful:
```bash
sudo tcpdump -i <your-interface> 'tcp dst port 80 or tcp dst port 443' and host rubygems.org
```
If this logs anything during an upgrade, there are missing gems that need to be added to the container.

An even more thorough test would be to run the upgrade without internet access.
If you do not want to mirror the container and dogu registry, you have to pull the images and register the dogu.json in
the local registry beforehand.