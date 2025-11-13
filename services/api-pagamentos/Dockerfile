# Multi-stage Dockerfile for api-pagamentos
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN python -m pip install --upgrade pip && pip wheel --no-cache-dir --no-deps -r requirements.txt -w /wheels

FROM python:3.11-slim
ARG USER=appuser
ARG UID=1000
ENV HOME=/home/${USER}

# create non-root user to run the app
RUN addgroup --system ${USER} \
	&& adduser --system --ingroup ${USER} --uid ${UID} --home ${HOME} ${USER} \
	&& mkdir -p /var/logs/api /app

WORKDIR /app
COPY --from=builder /wheels /wheels
RUN pip install --no-cache /wheels/* || true
COPY app.py .

# ensure permissions for volume mount
RUN chown -R ${USER}:${USER} /app /var/logs/api

USER ${UID}:${UID}
EXPOSE 8080
CMD ["python", "app.py"]
