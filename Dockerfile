FROM bitnami/oauth2-proxy:6

ADD build/site /srv

EXPOSE 4180

CMD ['oauth2-proxy', '--upstream', 'file:///srv/#/']
