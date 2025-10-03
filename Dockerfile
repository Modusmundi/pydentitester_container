# Build stage 1, update and pull repo
# Set nonroot perms afterward.
FROM cgr.dev/chainguard/wolfi-base AS repopull
USER root
WORKDIR /app

RUN apk update && apk add --no-cache --update-cache git && git clone https://github.com/Modusmundi/pydentitester.git . &&  chown -R nonroot:nonroot /app/

# Pull dependencies so we don't do it in the end build step.
# We make the results nonroot.
FROM cgr.dev/chainguard/python:latest-dev AS libget
USER root
WORKDIR /app

ENV VIRTUAL_ENV=/app/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY --from=repopull /app/requirements.txt .


RUN python -m venv $VIRTUAL_ENV
RUN venv/bin/pip install --no-cache-dir -r /app/requirements.txt && chown -R nonroot:nonroot /app/


# Put it all together in a minimal Python container.
# Enforce nonroot, run our app.
FROM cgr.dev/chainguard/python:latest AS runtime
USER nonroot
WORKDIR /app

ENV VIRTUAL_ENV=/app/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY --from=libget --chown=nonroot:nonroot /app/venv venv
COPY --from=repopull --chown=nonroot:nonroot /app/ /app/

EXPOSE 8080
ENTRYPOINT ["python", "/app/main.py"]