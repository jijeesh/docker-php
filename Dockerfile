FROM centos:latest
MAINTAINER Jijeesh <silentheartbeat@gmail.com>
#DOMAIN INFORMATION
ENV servn example.com
ENV cname www
ENV dir /var/www/
ENV user apache
ENV listen *
#Virtual hosting
RUN yum install -y httpd
RUN yum install -y --skip-broken php php-devel php-mysqlnd php-common php-pdo php-mbstring php-xml
RUN mkdir -p $dir${cname}_$servn
RUN chown -R ${user}:${user}  $dir${cname}_$servn
RUN chmod -R 755  $dir${cname}_$servn
RUN mkdir /var/log/${cname}_$servn
RUN mkdir /etc/httpd/sites-available
RUN mkdir /etc/httpd/sites-enabled
RUN mkdir -p ${dir}${cname}_${servn}/logs
RUN mkdir -p ${dir}${cname}_${servn}/public_html

RUN printf '# * Hardening Apache \n\
ServerTokens Prod \n\
ServerSignature Off \n\
Header append X-FRAME-OPTIONS "SAMEORIGIN" \n\
FileETag None \n\
' \
>> /etc/httpd/conf/httpd.conf



RUN printf "IncludeOptional sites-enabled/${cname}_$servn.conf" >> /etc/httpd/conf/httpd.conf
####
RUN printf "#### $cname $servn \n\
<VirtualHost ${listen}:80> \n\
ServerName ${servn} \n\
ServerAlias ${alias} \n\
DocumentRoot ${dir}${cname}_${servn}/public_html \n\
ErrorLog ${dir}${cname}_${servn}/logs/error.log \n\
CustomLog ${dir}${cname}_${servn}/logs/requests.log combined \n\
<Directory ${dir}${cname}_${servn}/public_html> \n\
Options -Indexes \n\
Options -ExecCGI -Includes \n\
LimitRequestBody 204800 \n\
AllowOverride All \n\
Order allow,deny \n\
Allow from all \n\
Require all granted \n\
<LimitExcept GET POST HEAD> \n\
    deny from all \n\
</LimitExcept> \n\
<IfModule mod_headers.c> \n\
    Header set X-XSS-Protection \"1; mode=block\" \n\
    Header edit Set-Cookie ^(.*)$ $1;HttpOnly;Secure \n\
</IfModule> \n\

</Directory> \n\
</VirtualHost>\n" \
 > /etc/httpd/sites-available/${cname}_$servn.conf
RUN ln -s /etc/httpd/sites-available/${cname}_$servn.conf /etc/httpd/sites-enabled/${cname}_$servn.conf
########################################################
#### PHP configuration ##########

RUN cp /etc/php.ini /etc/php.ini.orginal
RUN mkdir -p /data/php/log/
RUN mkdir -p /data/php/session/
RUN mkdir -p /data/php/tmp/

# -----------------------------------------------------------------------------
# Securisation for PHP
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's/^expose_php = .*/expose_php = Off/' \
	-e 's/^memory_limit = .*/memory_limit = 512M' \
	-e 's/^max_execution_time = .*/max_execution_time = 30/' \
	/etc/php.ini

EXPOSE 80

RUN rm -rf /run/httpd/* /tmp/httpd*
CMD ["/usr/sbin/apachectl", "-D", "FOREGROUND"]

