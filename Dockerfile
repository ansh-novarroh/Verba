FROM python:3.11
WORKDIR /Vijil RAG Agent
COPY . /Vijil RAG Agent
RUN pip install '.'
EXPOSE 8000
CMD ["verba", "start","--port","8000","--host","0.0.0.0"]
