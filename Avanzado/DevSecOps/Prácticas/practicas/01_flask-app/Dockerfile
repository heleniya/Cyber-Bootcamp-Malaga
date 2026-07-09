
FROM python:3.9-slim


USER root

WORKDIR /app
COPY app/ .

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8001

EXPOSE 8081

CMD ["python", "app.py"]