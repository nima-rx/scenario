#!/bin/sh
yum install -y httpd
systemctl enable httpd
echo "Hello World" > /var/www/html/index.html
systemctl start httpd
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
echo "qazwsx" | passwd root --stdin
