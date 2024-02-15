#
# Copyright (c) 2023 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#

# Build environment
FROM registry.access.redhat.com/ubi9/go-toolset:1.20 as builder
COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download
COPY . .
RUN CGO_ENABLED=1 GOFLAGS="" go build -o /usr/bin/upgrade-tool

# Final image
FROM registry.access.redhat.com/ubi9/ubi:9.2-489

# Create/Mount working directory
ARG ASSETS_DIR=/assets
RUN mkdir $ASSETS_DIR && chmod 775 $ASSETS_DIR
VOLUME $ASSETS_DIR
ENV ASSETS_DIR=$ASSETS_DIR

# Install the required packages:
RUN \
    dnf -y install \
    tar \
    && \
    dnf -y clean all

# Download oc
RUN curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz \
    | tar xvzf - -C /usr/local/bin && \
    chmod +x /usr/local/bin/oc

# Install the tool:
COPY --from=builder /usr/bin/upgrade-tool /usr/bin/upgrade-tool

WORKDIR $ASSETS_DIR
ENTRYPOINT ["/usr/bin/upgrade-tool"]
