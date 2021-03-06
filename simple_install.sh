sudo yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine
rm -rf /var/lib/docker && rm -rf /data/storage/
sudo yum install -y yum-utils && yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
mkdir -p /etc/docker/
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://9rudmnh3.mirror.aliyuncs.com" ]
}
EOF
yum install -y docker-ce
systemctl start docker && systemctl stop docker && mkdir -p /data/storage && mv /var/lib/docker /data/storage/ && ln -s /data/storage/docker /var/lib/docker
systemctl start docker
find / -name 'simple_install.sh' |xargs rm -rf
exit 0
