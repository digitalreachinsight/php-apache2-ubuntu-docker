# Prepare the base environment.
FROM ubuntu:20.04 as builder_base_docker
MAINTAINER itadmin@digitalreach.com.au 
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Australia/Perth
ENV PRODUCTION_EMAIL=True
ENV SECRET_KEY="ThisisNotRealKey"
RUN apt-get clean
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install --no-install-recommends -y wget git libmagic-dev gcc binutils libproj-dev gdal-bin tzdata cron rsyslog apache2
RUN apt-get install --no-install-recommends -y libapache2-mod-php php php-common php-curl php-gd php-imagick php-mbstring php-mysql   
RUN apt-get install --no-install-recommends -y postfix libsasl2-modules vim
RUN apt-get install -y vim telnet
# Example Self Signed Cert
RUN apt-get install -y openssl
RUN openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj  "/C=AU/ST=Western Australia/L=Perth/O=Digital Reach Insight/OU=IT Department/CN=example.com"  -keyout /etc/ssl/private/selfsignedssl.key -out /etc/ssl/private/selfsignedssl.crt

# Install Python libs from requirements.txt.
FROM builder_base_docker as python_libs_docker
WORKDIR /app
# Install the project (ensure that frontend projects have been built prior to this step).
FROM python_libs_docker
# Set  local perth time
COPY timezone /etc/timezone
ENV TZ=Australia/Perth
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY sites.conf /etc/apache2/sites-enabled/
RUN mkdir /etc/webconfs/
#RUN mkdir /etc/webconfs/apache/ 
#RUN mkdir /var/web/
#RUN mkdir /etc/postfix-conf/
RUN a2enmod ssl

RUN touch /app/.env
COPY boot.sh /
RUN touch /etc/cron.d/dockercron
RUN cron /etc/cron.d/dockercron
RUN chmod 755 /boot.sh
EXPOSE 80
HEALTHCHECK --interval=5s --timeout=2s CMD ["wget", "--timeout=15", "--tries=3", "-q", "-O", "-", "http://localhost:80/"]
CMD ["/boot.sh"]
