FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir flask pyyaml prometheus-client
COPY app.py .
EXPOSE 8088
CMD ["python", "app.py"]
