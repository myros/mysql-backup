
ENTRYPOINT ["/entrypoint.sh"]

RUN touch /var/log/cron.log

CMD cron && tail -f /var/log/cron.log
