# OpenShift EgressIP Helm Chart

This Helm Chart allows you to easily deploy EgressIPs from a simple list and run tests against them enmass.

You can optionally create EgressIPs and/or the tests for them, in case you already have EgressIPs created and just want to test, or just want to create EgressIPs without testing.

```yaml
deployTestJobs: true
targetCURLTestEndpoint: "http://debug-server:8080"

createEgressIPs: true
egressIPList:
- name: nuclear-prod
  egressIPs:
    - 1.2.3.4
    - 4.5.6.7
  selector:
    matchLabels:
      bu: nukesRus
      env: prod
- name: nuclear-non-prod
  egressIPs:
    - 2.3.4.5
    - 7.8.9.1
  selector:
    matchLabels:
      bu: nukesRus
      env: non-prod
```

## Test Service

When testing the EgressIPs you need a little HTTP server to test against.  Below is a Python web server that will provide the feedback needed to run the EgressIP tests:

```python
#!/usr/bin/env python3
"""
Very simple HTTP server in python for logging requests
Usage::
    ./server.py [<port>]
"""
from http.server import BaseHTTPRequestHandler, HTTPServer
import logging
from urllib.parse import urlparse

class S(BaseHTTPRequestHandler):
    def _set_failure(self):
        self.send_error(500, message="NONMATCH", explain=None)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def _set_response(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        # If the path has /egress-test, then log the request headers and path
        logging.info("=============== START GET REQUEST")
        logging.info("GET request,\nPath: %s\nRequested Address: %s\nXFF: %s\nHeaders:\n%s\n", str(self.path), self.client_address[0], str(self.headers.get('X-Forwarded-For')), str(self.headers))
        if "/egress-test" in self.path:
            egressIP = ""
            query = urlparse(self.path).query
            if query != None:
                query_components = dict(qc.split("=") for qc in query.split("&"))
                if "egressip" in query_components:
                    egressIP = query_components["egressip"]

            if egressIP != '':
                message = "{}".format(self.headers.get('X-Forwarded-For'))
                if self.headers.get('X-Forwarded-For') == egressIP or self.client_address[0] == egressIP:
                    self._set_response()
                else:
                    self._set_failure()
            self.wfile.write(message.encode('utf-8'))
        else:
            self._set_response()
            self.wfile.write("GET request for {}".format(self.path).encode('utf-8'))
        logging.info("=============== END GET REQUEST")


def run(server_class=HTTPServer, handler_class=S, port=8080):
    logging.basicConfig(level=logging.INFO)
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    logging.info('Starting httpd...\n')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    logging.info('Stopping httpd...\n')

if __name__ == '__main__':
    from sys import argv

    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()

```

Here's how to deploy it into OpenShift:

```yaml
---
kind: Namespace
apiVersion: v1
metadata:
  name: debug-server
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: script
  namespace: debug-server
data:
  server.py: |-
    #!/usr/bin/env python3
    """
    Very simple HTTP server in python for logging requests
    Usage::
        ./server.py [<port>]
    """
    from http.server import BaseHTTPRequestHandler, HTTPServer
    import logging
    from urllib.parse import urlparse

    class S(BaseHTTPRequestHandler):
        def _set_failure(self):
            self.send_error(500, message="NONMATCH", explain=None)
            self.send_header('Content-type', 'text/html')
            self.end_headers()

        def _set_response(self):
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()

        def do_GET(self):
            # If the path has /egress-test, then log the request headers and path
            logging.info("=============== START GET REQUEST")
            logging.info("GET request,\nPath: %s\nRequested Address: %s\nXFF: %s\nHeaders:\n%s\n", str(self.path), self.client_address[0], str(self.headers.get('X-Forwarded-For')), str(self.headers))
            if "/egress-test" in self.path:
                egressIP = ""
                query = urlparse(self.path).query
                if query != None:
                    query_components = dict(qc.split("=") for qc in query.split("&"))
                    if "egressip" in query_components:
                        egressIP = query_components["egressip"]

                if egressIP != '':
                    message = "{}".format(self.headers.get('X-Forwarded-For'))
                    if self.headers.get('X-Forwarded-For') == egressIP or self.client_address[0] == egressIP:
                        self._set_response()
                    else:
                        self._set_failure()
                self.wfile.write(message.encode('utf-8'))
            else:
                self._set_response()
                self.wfile.write("GET request for {}".format(self.path).encode('utf-8'))
            logging.info("=============== END GET REQUEST")


    def run(server_class=HTTPServer, handler_class=S, port=8080):
        logging.basicConfig(level=logging.INFO)
        server_address = ('', port)
        httpd = server_class(server_address, handler_class)
        logging.info('Starting httpd...\n')
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
        httpd.server_close()
        logging.info('Stopping httpd...\n')

    if __name__ == '__main__':
        from sys import argv

        if len(argv) == 2:
            run(port=int(argv[1]))
        else:
            run()
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: debug-server
  namespace: debug-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: debug-server
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: debug-server
    spec:
      volumes:
        - name: script
          configMap:
            name: script
      containers:
        - name: container
          image: 'registry.access.redhat.com/ubi8/python-312:latest'
          command:
            - /bin/bash
            - '-c'
          args:
            - |
              #!/bin/bash
              python3 /tmp/server/server.py
          ports:
            - containerPort: 8080
              protocol: TCP
          volumeMounts:
            - name: script
              mountPath: /tmp/server
          imagePullPolicy: Always
          resources: {}
          terminationMessagePath: /dev/termination-log
      restartPolicy: Always
      terminationGracePeriodSeconds: 10
  strategy:
    type: Recreate
---
kind: Service
apiVersion: v1
metadata:
  name: debug-server
  namespace: debug-server
spec:
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  type: ClusterIP
  selector:
    app: debug-server
---
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: debug-server
  namespace: debug-server
spec:
  to:
    kind: Service
    name: debug-server
    weight: 100
  port:
    targetPort: 8080
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Allow
  wildcardPolicy: None
```

> Note:  You can't run this service in the same cluster that the EgressIPs are being tested from.