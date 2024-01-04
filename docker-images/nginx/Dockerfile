FROM nginx:1.25.3-bookworm

RUN mkdir /var/log/monitoring

RUN apt-get update && apt-get install -y \
daemontools \
daemontools-run \
bc

COPY monitoring /etc/service/monitoring
RUN find /etc/service/monitoring -type d -exec chmod 755 {} + ; find /etc/service/monitoring -type f -exec chmod 744 {} +

ADD start.sh /start.sh
RUN chmod +x start.sh
CMD [ "/start.sh"]