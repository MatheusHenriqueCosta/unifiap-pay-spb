# Simple image for auditoria
FROM python:3.11-slim
ARG USER=appuser
ARG UID=1000
ENV HOME=/home/${USER}

RUN addgroup --system ${USER} \
	&& adduser --system --ingroup ${USER} --uid ${UID} --home ${HOME} ${USER} \
	&& mkdir -p /app /var/logs/api

WORKDIR /app
COPY app.py .
RUN chown -R ${UID}:${UID} /app /var/logs/api

USER ${UID}:${UID}
EXPOSE 8081
CMD ["python", "app.py"]
