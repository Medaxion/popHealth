#From https://github.com/OSEHRA/popHealth/wiki/Installation-v5.1#11-configure-startup-processes

cd ~
echo -e '#!/bin/bash\ncd /home/vagrant/popHealth\n. /usr/local/rvm/scripts/rvm\nbundle exec rake jobs:work RAILS_ENV=production\n' > start_delayed_job.sh
chmod +x start_delayed_job.sh

cat << DELAYED_WORKER_END | sudo dd of=/etc/systemd/system/pophealth_delayed_worker.service
  [Unit]
  Description=delayed_worker
  After=mongod.service
  Requires=mongod.service

  [Service]
  Type=simple
  User=vagrant
  WorkingDirectory=/home/vagrant/popHealth
  ExecStart=/home/vagrant/start_delayed_job.sh
  TimeoutSec=120

  [Install]
  WantedBy=multi-user.target
DELAYED_WORKER_END