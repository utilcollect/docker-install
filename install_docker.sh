#!/bin/bash
rm -rf /opt/gezhiwei
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
function check_ip() {
    local IP=$1
    VALID_CHECK=$(echo $IP|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
        if [ $VALID_CHECK == "yes" ]; then
         echo "IP $IP  available!"
            return 0
        else
            echo "IP $IP not available!"
            return 1
        fi
    else
        echo "IP format error!"
        return 1
    fi
}
while true; do
    read -p "Please enter IP: " IP
    check_ip $IP
    [ $? -eq 0 ] && break
done

yum -y update
yum -y install epel-release && yum -y install python-pip && pip install pexpect
echo "python pip and pexpect has been installed -------------------------------------------------------------------------"
sudo yum install -y yum-utils && yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

mkdir -p /opt/gezhiwei/docker/ /etc/docker/
tee /opt/gezhiwei/docker/openssh-cert-server.py <<-'EOF'
# -*- coding: utf-8 -*-
#!/usr/bin/evn python
import shutil,re,sys,os
import pexpect
from time import sleep


def movefile(srcfile, dstfile):
    if not os.path.isfile(srcfile):
        print "%s not exist!" % (srcfile)
    else:
        fpath, fname = os.path.split(dstfile)  # 分离文件名和路径
        if not os.path.exists(fpath):
            os.makedirs(fpath)  # 创建路径
        shutil.move(srcfile, dstfile)  # 移动文件
        print "move %s -> %s" % (srcfile, dstfile)

def copyfile(srcfile, dstfile):
    if not os.path.isfile(srcfile):
        print "%s not exist!" % (srcfile)
    else:
        fpath, fname = os.path.split(dstfile)  # 分离文件名和路径
        if not os.path.exists(fpath):
            os.makedirs(fpath)  # 创建路径
        shutil.copyfile(srcfile, dstfile)  # 复制文件
        print "copy %s -> %s" % (srcfile, dstfile)


# server sa
child2 = pexpect.pty_spawn.spawn('openssl genrsa -out server-key.pem 4096')
sleep(3)

# create ca
child3 = pexpect.spawn(
    'openssl req -sha256 -new -key server-key.pem -out server.csr')
child3.expect('Country Name *')
child3.sendline('cn')
child3.expect('Province')
child3.sendline('jiangsu')
child3.expect('Locality Name *')
child3.sendline('suzhou')
child3.expect('Organization Name *')
child3.sendline('jiangduoduo')
child3.expect('Organizational Unit Name *')
child3.sendline('saishi')
child3.expect('Common Name *')
child3.sendline(sys.argv[1])
child3.expect('Email Address *')
child3.sendline('\n')
child3.expect('challenge password *')
child3.sendline('\n')
child3.expect('An optional company *')
child3.sendline('\n')
sleep(3)

child4 = pexpect.spawn(
    'openssl x509 -req -days 3650 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem')
child4.expect('Enter pass phrase *')
child4.sendline('1234')
sleep(3)

movefile('./server-cert.pem','/etc/docker/server-cert.pem')
movefile('./server-key.pem','/etc/docker/server-key.pem')
copyfile('./ca.pem','/etc/docker/ca.pem')
EOF

tee /opt/gezhiwei/docker/ca.pem <<-'EOF'
-----BEGIN CERTIFICATE-----
MIIFqzCCA5OgAwIBAgIJAMuyIFsaOb4/MA0GCSqGSIb3DQEBCwUAMGwxCzAJBgNV
BAYTAmNuMRAwDgYDVQQIDAdqaWFuZ3N1MQ8wDQYDVQQHDAZzdXpob3UxFDASBgNV
BAoMC2ppYW5nZHVvZHVvMQ8wDQYDVQQLDAZzYWlzaGkxEzARBgNVBAMMCjEwLjMz
Ljk0LjUwHhcNMTgwNzEzMDgwMDIzWhcNMjgwNzEwMDgwMDIzWjBsMQswCQYDVQQG
EwJjbjEQMA4GA1UECAwHamlhbmdzdTEPMA0GA1UEBwwGc3V6aG91MRQwEgYDVQQK
DAtqaWFuZ2R1b2R1bzEPMA0GA1UECwwGc2Fpc2hpMRMwEQYDVQQDDAoxMC4zMy45
NC41MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEApfhffaCUhkz3UwIy
hCMipySCJKOilM5bVGonk4J5xE6/Z5r2nlPxELrT7l/cqAQmj5SsTo4zD3JKYXlL
7+60HovyiISNG/l9ZLrKhizQW6A2OLFWdykDjUojTez6R0uqqbfoRXnlKSnxNX7j
T8YGb8SGo5lqzXXQmwsOe34UoWPrVu0zGGMW+M1K1+g22cMv8a48Zrk7AZ1MDlBP
8J6LRMngq2H5QFW88uoZWxzWlsYcT07XgNZdqXbHULGtqW5rc9MKKPnLxfix5mBn
SjlCbTGqDVVJk54hyzj7BMWRXQhECmK1doanddscRYGQ7hIwG0V+PxegPRZLPzeB
gaufoMjxNK5U5BfwNS+g7VtAd/l2xnCaGFnTNX54PPceZSQYRk/hOZVEQhDDIxI7
Kz6+8wU/mmZ9lf49QnIW1QO56YhnGwrb63uUbNl6ipMQgEY8Dmxe4JtRAnKm8wzt
PHly432oA0DVq7+tz1w6ZkE+1socVpqdDpYOUNxyBaJMnn72kRr7Ubj4wFgarFwv
PgVZLtBQ83C4L76Le5v9ZNoxVsuMFKhH//OKBRQDIho3MS9AAuqnJk+ohS01/Zj+
FRBv6o13PuXJ02TnWWxaWcz4vkpUwxY3IZMDCbtv40MakRQxoZqZT5rgIJqtHD43
x/fWr5k/dwIjAl67xm5Z/JO/vUECAwEAAaNQME4wHQYDVR0OBBYEFFfmHuPTF4SO
tmhYiom39RUd3vgpMB8GA1UdIwQYMBaAFFfmHuPTF4SOtmhYiom39RUd3vgpMAwG
A1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggIBAFRzHuUGnALaqxDjX0+R6OnV
1N6qMfgLxmHK4HJHoIJ9lQo6PcNmkuH+k+a4/3DuJvDHZhdgUnVSak6kDA1FN7d6
Yl14PDJ1ubxRgqkU4FsQI0AiCGa1P/F//A7iJP4MrE24Tv2V1OIsC5wuj3mOQClU
cHIweZthdi3sd84MP0ITto67GMwAHrZtoRzwzWaN6yGwoe4nfM8/kZXHMAYTa8dF
RsVfl+MWrmoozdBTu5hKE6873A3D4FE1SOPlp0akisb/5RYd+AEvT/qG8RyjlWcW
+jEWsyZo0u+vSPwATf1uyIuX475AOxfRYOOaPKh+ofaOgc6eZFEcgroJIO4/WMjB
jBSV756aT0VPlhbYOJrgbrmBkxQyMBPXuvIxRaFeg0tL4A7+ywPyFaDWwX7LcEc8
ThzBqEWa40QjfQ3QOYqvfHssv1cmgoJGuTSELHil6Lp7Tfwo4GSqZwKPlLjD1hb1
tRegoX8H8yAkYSYu8GyDMtytLWwgyoZNbN26JLvCNt+5I3QDuVZ4PXeDZUXdpCdJ
gzjPK0hWnSYQrJ0aJQQOuq4sBmZMqBMrR8MaFXYO5Co64OZXBBCPCi9oWptpU46a
dxsEH5gRNT6DB6WGtnYg1P6zMT1H2M0BKK3XltqsSBRkKLCgMsJOcCsmIRbnsTsU
s+e+E6t0pHyv8nxc5uyC
-----END CERTIFICATE-----
EOF

tee /opt/gezhiwei/docker/ca-key.pem <<-'EOF'
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-256-CBC,D978AA5AD677E0C5B29615C9F415621F

C80xEHYiqdXTi2IPVRMnqHRqXLcoqCNr8yYWBbZGbZHRhzCc9m2E1XRAVlptxK51
yeDaft+lSSQ8POX3JXEJqClHUJ2Ao7X8F1jEUcLBQOvQ+V+D7Vv3GztpaLMg4g9D
MqrjnqNRpqfU68YIJxO/L0VngsjfhBPmQmcPo7esawmf6kWE6BxvXanT+r4UPzQi
pq2dm033YXU1DvNbzg8jhB0JLUTqN3w+BQurHD97YUqg79mhjKfK00FaAPw2WhxU
1Xeafc1NtggKJwpucVipIsOH1wrexhmqWubaIoYkGDGF8I+LSFIDSy9j8o1T9KhS
Dc20WedNYvLbrCdcc2EjbGpXaDaVlOhiqoSlqzd+Czz4othhkPNfHq13i+WOsnCj
jPB5oGvbxm4TpC3/jbPcMx3ocWNmUvHaXuRxgOFdTwOWEq+3Cpc6Un25HrQV5rUt
t8guC2NRaH18WjlgCzxSJUxlfYa1ZzsXrjBg7EcJGHFOmm1PufnUe8oQRjZSsIMQ
bsDHGY3zYji6Or1bmLT/qtZ2Ia1u/HTdxQBonigqu99btqD0kG3g+tF33SRkpxtu
wwFCdmbzAI6YYLsb4yFn+5MXB4P9P0cXU3c05D07jI4jfYbJIAKTGohTUgtpH47T
eSi3DclNfYmXA4EPJhtGFBfKijp1cVAHk8Jo40kauAvrNfpIod0MLZ6WPadPpcIL
PZX1VavjaTON/1oCZE8Sr/e2dpeqrgMzDG3c7u4vQtwmh2YPRLKDeQFsc2Cpby83
4sq7TLTnWRp2gF0kVzB/uatYxItT/5tVwvlo+dkkjBdW4wsfhrdKoU3oL5Uyqe9H
G7EMsRv2r1dIT1HdfpbO1tYNcW9JsVEa963vWZvwmkn0y/GPJO7gkMOnoZ9ICkAH
AmPaQJzX+DpFluQE5Fgql3p72Q0SI24RCb1gl6SSTquILPgvlCQ07IhxEDLZK2oC
zwnt6LMA+egHuDKyVFzXMup0+ayVH4Y/T2by9eRt0tpxUroDzSxBSMws6KrbnLQm
9oQe2wxAC6+CBCEEYcwSo+iLonYYArZxT7wxtS6Gnqcf76hwkHlXUhBvJ1vaHbWC
PeLbEysxoWO92oYOP3QJYxAVNUj3ARZeqLf8biWUYEdyU6EI1jsxyRo2/LV7MeBC
hWZgQpEOTJ9Iqb6dzeeBM3D53B6dShlBu+AIfh0HviVoxZcPyOsb1/XzqROIMirZ
MLcx/MV9fyYJP2XzbixcuWLD0ve8X1SgAbui8lx5eAggUiGlNcfEphJrKroUy06j
KaYlpzS+hFR4ovaREXDQEhuTpGyMj4tIPaJjxuRe3QgwPnTr35z1ilLfV/eqokAk
VPe8GGi+DCgU9DNTAxw+bbYP2mfGl8/JyTh8i4P2f+BvlcZzF7KCNT73UA9hYFht
jA5+yiuR0Rlv1w8Z64c8o2jKW0tQlBSSMjEX0i+2CZAKWUGnqWjbH2iquKYbvj1G
op905mabFaBI27Dx39cQmq2t4fhUFYiGiwJDasIEOkSi5FkACeDObyMAFfkFXWTj
9gnkAK6/2VBKFxt17+m5rtyVVnTiD6LpRs0MpevNPbxoaMQbqdYQ7umf4fBd/xdL
2WNeBM3LtqQWpnGpwnxVY7L8E5gd2N3xJHphIQwpbeBWdGbyyp4c/j2L1QXVN97Y
BiYSJ8X4AxgOQ9YeG4TBLjR5HYejkN0XqgLGkuOFmiixyXE0OF/Ck/qxr8p235kk
gzwkZ1tM+8FLFABcBlyWhiFAPoCphR0f4KIbPBS4uXTkcb6NbtgZp8HoA+xBjk1V
C8UtEksSeT4C61sjr6IPs3GbKm+i1YL4MYrYIFiC5gCE2VxXgwDK9nhz8bW/bwRv
RdOfFs02MrsuX3z98ugPkTDnHnQy5gxd2eyMNJEQrM3UWc8TkzUXeIXu3nzB0nfh
fNuNlkqVfFSGla/BYfFZ+zYz1ufrMBSQVC4IpF/3bZ/ya8cqjlfN4uFcI2ElUqSC
Hh+FN3R/yhzaWY/4k/gFFvYc3ruZSYl4klA5IYAJDBbRCPFFSA6Hl2oujePI4A7U
WkhIsyJlSwCrZNO5deQkYu8Huue0FGtiTvdqiZs/vkm8W4DIhmVX6B0eVRFdCM37
gaJEwwlFcC/hbzHl7RgkWYPwiSdOJhwehkiKu2Bt/Nzi/dgaibhbhLPsilWwgJ6C
48xVdSrODKramPbiUdswmjUrOJtN+MM7EUefldwBm4rgNs0N9Ep6Z6xShvwZL+cG
lrpq7Z+D/1mGTKcdTzBPja8yR9IWRxD5Ykc6MHgUuYtvAY60bhTbmuamNJn7hNnE
DMxozXOiTTiDIeGb9RIjO8YdL4dC6Qgs2uFANycnZHBkNGGDa+xqE8dK4vNEmr6g
O3XTCZUtsX12E620HscNQu5nGkowQw6JbXXdWGPeD/aL3QOhFQ+R89LMbcVVtB3M
0/fRr/FUIofCDBVh0eaMsudz1SUvpIwq7oXI3/PbfCgMlvlJMszCG1exce9ieuPy
ew6yZvUIKjv9qhKCKLeUZ0CfVZNFiAskO4TNg8ZFn7olZNRRam1eFdofMpPlQOqG
PXZB2eXumiHJdVTUDE5Cst6xVLvLZxKwTGO85gm0Xww1scHmnamsVNR4//y/bTEU
j1IFm+8gcHxX73RdDL3BA6HTSviGD2yAGQwQ1vskoLkxuQrpBPK0gERCmqta7+Ga
I1w/cCsjKno3kvC7Lbk1pEK/4g5CNcZcK+X8creRGJAgfdRQINe5bzzOP/EBqsLl
B9uT4l9MOYz36mGRMCU/KcNRXN8++0fRMqbjluddQAFcd+rPiJLKUz3c67j54YBD
t7p41ZpphrNhhPkbnqZf4TcL29syuE/SAHX857/T+5eUxzRbBnt2gryZh5jfnDdt
hv7ySeB69USc8e5naQSFr6Z0B+eFAlirwo3ubcWoZ8D79PdNxOvnMAygcFVM5+WM
Xts6rCfopLrFV3bZpay+IZtdaz99dgcPnGcar+lNwVPTX0U6yDnHsKBKm2I6d2oS
cYy/SymmGVnqZ5UYOqHo692CDKVDt97BBIiUXSwFbWKN/Purs/HIDkNcwc1Ey7DH
AxyorPWb+qillHZ5guDs8jmhL5FGKTFy7ZmbagHvm4WX7M9C+vxxlq0bOyEjWwFr
-----END RSA PRIVATE KEY-----
EOF



tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://dthsa6yd.mirror.aliyuncs.com" ]
}
EOF
yum install -y docker-ce-18.06.0.ce-3.el7
chmod +x /opt/gezhiwei/docker/openssh-cert-server.py && cd /opt/gezhiwei/docker/ && python openssh-cert-server.py $IP
echo "ca certifate has been installed -------------------------------------------------------------------------"
echo "ca certifate has been installed -------------------------------------------------------------------------"
echo "ca certifate has been installed -------------------------------------------------------------------------"
systemctl start docker && systemctl stop docker && mkdir -p /data/storage && mv /var/lib/docker /data/storage/ && ln -s /data/storage/docker /var/lib/docker
sed -i '/ExecStart/s/ExecStart.*/ExecStart=\/usr\/bin\/dockerd --tlsverify --tlscacert=\/etc\/docker\/ca.pem --tlscert=\/etc\/docker\/server-cert.pem --tlskey=\/etc\/docker\/server-key.pem   -H=0.0.0.0:2376 -H=unix:\/\/\/var\/run\/docker.sock/g' /usr/lib/systemd/system/docker.service

systemctl daemon-reload
systemctl start docker
systemctl enable docker
rm -rf /opt/gezhiwei
find / -name 'install_docker.sh' |xargs rm -rf
exit 0