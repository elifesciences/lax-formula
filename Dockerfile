FROM python:3.5
RUN ln -s /usr/local/bin/python /usr/bin/python3.5
COPY lax/ /srv/lax
WORKDIR /srv/lax
RUN ./install.sh
EXPOSE 8000
CMD ./manage.sh runserver 0.0.0.0:8000
